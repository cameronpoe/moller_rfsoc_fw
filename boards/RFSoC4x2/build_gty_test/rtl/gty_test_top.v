`timescale 1ns / 1ps
// -------------------------------------------------------------------------------------------------
// gty_test_top.v: RFSoC4x2 QSFP / GTY bank 128 test
//
//   gty_trig : 1.25 Gb/s 8b/10b, QPLL0, on X0Y4 (bank 128 ch0) and X0Y7 (bank 128 ch3)
//              ch0 = lane 1 TX (status back to the master) / lane 4 RX
//              ch3 = lane 1 RX (trigger from the master)   / lane 4 TX
//
//   Both channels transmit the same test pattern: one K28.5 comma word every 256 words, and a
//   16-bit counter in the other 255. Each receiver checks the counter (seq_err), counts 8b/10b code
//   errors (code_err), and counts PRBS errors while PRBS mode is on.
//
//   Clocks:
//     pl_clk0       125 MHz  PS; VIO, frequency-counter gate
//     clk_freerun   31.25    pl_clk0 / 4 (BUFGCE_DIV); wizard reset controller (same as JLab)
//     refclk_fabric 156.25   GTY refclk (ODIV2 -> BUFG_GT), only for measuring it
//     tx_usrclk2    62.5     GT TX user clock (master X0Y4)
//     rx_usrclk2    62.5     GT RX user clock = X0Y7 recovered clock (RX master); data ILA, MMCM input
//     clk250/clk62  250/62.5 MMCM on rx_usrclk2 (what the TI core will use in step 2)
//
//   Two-channel buses on gty_trig: slice 0 / slice 1. Assumed slice 0 = X0Y4 (ch0) and
//   slice 1 = X0Y7 (ch3), i.e. lowest site first. CHECK against the LOC lines in gty_trig's XDC.
// -------------------------------------------------------------------------------------------------
module gty_test_top (
    // GTY reference clock, MGTREFCLK0_128 (AA33/AA34), 156.25 MHz
    input  wire       gty_refclk_p,
    input  wire       gty_refclk_n,
    // GTY serial pins (placed by gty_trig's own LOC constraints)
    input  wire [1:0] gtyrxp_in,
    input  wire [1:0] gtyrxn_in,
    output wire [1:0] gtytxp_out,
    output wire [1:0] gtytxn_out,
    // QSFP sideband (bank 66)
    output wire       qsfp_resetl,
    output wire       qsfp_lpmode,
    output wire       qsfp_modsell,
    input  wire       qsfp_modprsl,
    input  wire       qsfp_intl
);

    // ---------------------------------------------------------------------------------------------
    // QSFP module control: out of reset, high-power mode, selected (for I2C later)
    // ---------------------------------------------------------------------------------------------
    assign qsfp_resetl  = 1'b1;
    assign qsfp_lpmode  = 1'b0;
    assign qsfp_modsell = 1'b0;

    // ---------------------------------------------------------------------------------------------
    // PS block design
    // ---------------------------------------------------------------------------------------------
    wire pl_clk0;     // 125 MHz, already on a BUFG inside the PS block
    wire pl_resetn0;

    gty_test_wrapper u_ps (
        .pl_clk0    (pl_clk0),
        .pl_resetn0 (pl_resetn0)
    );

    // ---------------------------------------------------------------------------------------------
    // Free-running clock for the wizard: 125 / 4 = 31.25 MHz, plus a ~1 ms power-on reset
    // ---------------------------------------------------------------------------------------------
    wire clk_freerun;

    BUFGCE_DIV #(
        .BUFGCE_DIVIDE (4)
    ) u_freerun_div (
        .I   (pl_clk0),
        .CE  (1'b1),
        .CLR (1'b0),
        .O   (clk_freerun)
    );

    reg [15:0] por_cnt = 16'd0;
    reg        por     = 1'b1;
    always @(posedge clk_freerun) begin
        if (!por_cnt[15])
            por_cnt <= por_cnt + 16'd1;
        por <= ~por_cnt[15];            // high for 2^15 cycles = 1.05 ms after configuration
    end

    // ---------------------------------------------------------------------------------------------
    // GTY reference clock
    //   O     -> QPLL0 (gtrefclk00_in)
    //   ODIV2 -> BUFG_GT -> refclk_fabric, only so the frequency counter can measure it
    // ---------------------------------------------------------------------------------------------
    wire refclk;
    wire refclk_odiv2;
    wire refclk_fabric;

    IBUFDS_GTE4 #(
        .REFCLK_EN_TX_PATH  (1'b0),
        .REFCLK_HROW_CK_SEL (2'b00),    // ODIV2 = O (156.25 MHz)
        .REFCLK_ICNTL_RX    (2'b00)
    ) u_refclk_ibuf (
        .I     (gty_refclk_p),
        .IB    (gty_refclk_n),
        .CEB   (1'b0),
        .O     (refclk),
        .ODIV2 (refclk_odiv2)
    );

    BUFG_GT u_refclk_bufg (
        .I       (refclk_odiv2),
        .CE      (1'b1),
        .CEMASK  (1'b0),
        .CLR     (1'b0),
        .CLRMASK (1'b0),
        .DIV     (3'd0),                // divide by 1
        .O       (refclk_fabric)
    );

    // ---------------------------------------------------------------------------------------------
    // VIO controls (pl_clk0 domain)
    // ---------------------------------------------------------------------------------------------
    wire       vio_reset_all;           // full GT reset (PLL + both datapaths)
    wire       vio_reset_rx_datapath;   // RX datapath reset (use after changing loopback/polarity)
    wire [5:0] vio_loopback;            // 3 bits per channel: 000 normal, 001 near-end PCS, 010 near-end PMA
    wire [1:0] vio_rxpolarity;
    wire [1:0] vio_txpolarity;
    wire [3:0] vio_prbssel;             // same for TX and RX, both channels: 0000 off, 0001 PRBS-7, ...
    wire [1:0] vio_txprbsforceerr;      // while high: forces errors into the TX PRBS stream
    wire [1:0] vio_rxcdrhold;
    wire       vio_cnt_reset;           // clears the error counters and the GT's PRBS counters
    wire       vio_mmcm_reset;

    // ---------------------------------------------------------------------------------------------
    // gty_trig signals
    // ---------------------------------------------------------------------------------------------
    wire        tx_usrclk2, tx_active;
    wire        rx_usrclk2, rx_active;
    wire        tx_done, rx_done, cdr_stable, qpll0lock;
    wire [1:0]  gtpowergood, txpmaresetdone, rxpmaresetdone;
    wire [1:0]  rxbyteisaligned, rxbyterealign, rxcommadet, rxcdrlock, rxprbserr, rxprbslocked;
    wire [5:0]  rxbufstatus;            // 3 bits per channel
    wire [3:0]  txbufstatus;            // 2 bits per channel
    wire [31:0] rxdata;                 // 16 bits per channel
    wire [31:0] rxctrl0;                // per channel [15:0]: [1:0] = char-is-K
    wire [31:0] rxctrl1;                // per channel [15:0]: [1:0] = disparity error
    wire [15:0] rxctrl2;                // per channel [7:0]:  [1:0] = char-is-comma
    wire [15:0] rxctrl3;                // per channel [7:0]:  [1:0] = not-in-table
    reg  [31:0] txdata  = 32'd0;
    reg  [15:0] txctrl2 = 16'd0;        // per channel [7:0]: [1:0] = char-is-K

    // VIO controls moved into the GT user-clock domains they belong to
    wire [1:0] tx_polarity_s, tx_forceerr_s;
    wire [3:0] tx_prbssel_s;
    wire [1:0] rx_polarity_s, rx_cdrhold_s;
    wire [3:0] rx_prbssel_s;
    wire       rx_cnt_reset_s;

    xpm_cdc_array_single #(
        .DEST_SYNC_FF  (4),
        .SRC_INPUT_REG (1),
        .WIDTH         (8)
    ) u_sync_to_tx (
        .src_clk  (pl_clk0),
        .src_in   ({vio_txpolarity, vio_txprbsforceerr, vio_prbssel}),
        .dest_clk (tx_usrclk2),
        .dest_out ({tx_polarity_s, tx_forceerr_s, tx_prbssel_s})
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF  (4),
        .SRC_INPUT_REG (1),
        .WIDTH         (9)
    ) u_sync_to_rx (
        .src_clk  (pl_clk0),
        .src_in   ({vio_rxpolarity, vio_rxcdrhold, vio_prbssel, vio_cnt_reset}),
        .dest_clk (rx_usrclk2),
        .dest_out ({rx_polarity_s, rx_cdrhold_s, rx_prbssel_s, rx_cnt_reset_s})
    );

    // ---------------------------------------------------------------------------------------------
    // GT wizard instance
    // ---------------------------------------------------------------------------------------------
    gty_trig u_gty_trig (
        // user clocking: hold each BUFG_GT in reset until that direction's PMA reset is done
        .gtwiz_userclk_tx_reset_in          (~&txpmaresetdone),
        .gtwiz_userclk_tx_usrclk2_out       (tx_usrclk2),
        .gtwiz_userclk_tx_active_out        (tx_active),
        .gtwiz_userclk_rx_reset_in          (~&rxpmaresetdone),
        .gtwiz_userclk_rx_usrclk2_out       (rx_usrclk2),
        .gtwiz_userclk_rx_active_out        (rx_active),

        // reset controller (it synchronizes these inputs internally)
        .gtwiz_reset_clk_freerun_in         (clk_freerun),
        .gtwiz_reset_all_in                 (por | vio_reset_all | ~pl_resetn0),
        .gtwiz_reset_tx_pll_and_datapath_in (1'b0),
        .gtwiz_reset_tx_datapath_in         (1'b0),
        .gtwiz_reset_rx_pll_and_datapath_in (1'b0),
        .gtwiz_reset_rx_datapath_in         (vio_reset_rx_datapath),
        .gtwiz_reset_rx_cdr_stable_out      (cdr_stable),
        .gtwiz_reset_tx_done_out            (tx_done),
        .gtwiz_reset_rx_done_out            (rx_done),

        // data
        .gtwiz_userdata_tx_in               (txdata),
        .gtwiz_userdata_rx_out              (rxdata),

        // QPLL0 (common block inside the core)
        .gtrefclk00_in                      (refclk),
        .qpll0lock_out                      (qpll0lock),

        // serial pins
        .gtyrxn_in                          (gtyrxn_in),
        .gtyrxp_in                          (gtyrxp_in),
        .gtytxn_out                         (gtytxn_out),
        .gtytxp_out                         (gtytxp_out),

        // test controls
        .loopback_in                        (vio_loopback),   // asynchronous in the GT
        .rxcdrhold_in                       (rx_cdrhold_s),
        .rxpolarity_in                      (rx_polarity_s),
        .rxprbscntreset_in                  ({2{rx_cnt_reset_s}}),
        .rxprbssel_in                       ({2{rx_prbssel_s}}),
        .txpolarity_in                      (tx_polarity_s),
        .txprbsforceerr_in                  (tx_forceerr_s),
        .txprbssel_in                       ({2{tx_prbssel_s}}),

        // 8b/10b control
        .txctrl0_in                         (32'd0),          // no forced disparity
        .txctrl1_in                         (32'd0),
        .txctrl2_in                         (txctrl2),        // char-is-K
        .rxctrl0_out                        (rxctrl0),
        .rxctrl1_out                        (rxctrl1),
        .rxctrl2_out                        (rxctrl2),
        .rxctrl3_out                        (rxctrl3),

        // status
        .gtpowergood_out                    (gtpowergood),
        .rxbufstatus_out                    (rxbufstatus),
        .rxbyteisaligned_out                (rxbyteisaligned),
        .rxbyterealign_out                  (rxbyterealign),
        .rxcdrlock_out                      (rxcdrlock),
        .rxcommadet_out                     (rxcommadet),
        .rxpmaresetdone_out                 (rxpmaresetdone),
        .rxprbserr_out                      (rxprbserr),
        .rxprbslocked_out                   (rxprbslocked),
        .txbufstatus_out                    (txbufstatus),
        .txpmaresetdone_out                 (txpmaresetdone)
    );

    // ---------------------------------------------------------------------------------------------
    // TX pattern (both channels): slot 0 = {D5.6, K28.5}, slots 1..255 = 16-bit counter
    // Ignored by the GT while PRBS is selected.
    // ---------------------------------------------------------------------------------------------
    reg [7:0]  tx_slot = 8'd0;
    reg [15:0] tx_cnt  = 16'd0;

    always @(posedge tx_usrclk2) begin
        tx_slot <= tx_slot + 8'd1;
        if (tx_slot == 8'd0) begin
            txdata  <= {2{16'hC5BC}};          // K28.5 (0xBC) in the low byte
            txctrl2 <= {2{8'b0000_0001}};      // low byte is a K character
        end else begin
            txdata  <= {2{tx_cnt}};
            txctrl2 <= 16'd0;
            tx_cnt  <= tx_cnt + 16'd1;
        end
    end

    // ---------------------------------------------------------------------------------------------
    // RX checking (rx_usrclk2 domain), per channel slice
    // ---------------------------------------------------------------------------------------------
    wire        rx_check_en = rx_active && (rx_prbssel_s == 4'd0);
    wire        rx_prbs_en  = rx_active && (rx_prbssel_s != 4'd0);
    wire [1:0]  seq_err, code_err;
    wire [63:0] seq_cnt, code_cnt, prbs_cnt;    // 32 bits per channel

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin : g_rx
            wire [15:0] d       = rxdata [16*i +: 16];
            wire [1:0]  is_k    = rxctrl0[16*i +: 2];
            wire [1:0]  disperr = rxctrl1[16*i +: 2];
            wire [1:0]  nit     = rxctrl3[8*i  +: 2];

            reg  [15:0] prev      = 16'd0;
            reg         have_prev = 1'b0;
            reg         s_err     = 1'b0;
            reg         c_err     = 1'b0;

            always @(posedge rx_usrclk2) begin
                s_err <= 1'b0;
                c_err <= 1'b0;
                if (!rx_check_en || !rxbyteisaligned[i]) begin
                    have_prev <= 1'b0;
                end else begin
                    c_err <= |{disperr, nit};
                    if (is_k == 2'b00) begin                 // data word: must be previous + 1
                        s_err     <= have_prev && (d != prev + 16'd1);
                        prev      <= d;
                        have_prev <= 1'b1;
                    end
                end
            end

            assign seq_err[i]  = s_err;
            assign code_err[i] = c_err;

            sat_counter u_seq_cnt (
                .clk (rx_usrclk2), .rst (rx_cnt_reset_s), .inc (s_err),
                .count (seq_cnt[32*i +: 32]));
            sat_counter u_code_cnt (
                .clk (rx_usrclk2), .rst (rx_cnt_reset_s), .inc (c_err),
                .count (code_cnt[32*i +: 32]));
            sat_counter u_prbs_cnt (
                .clk (rx_usrclk2), .rst (rx_cnt_reset_s), .inc (rx_prbs_en & rxprbserr[i]),
                .count (prbs_cnt[32*i +: 32]));
        end
    endgenerate

    // error counters -> pl_clk0 for the VIO
    // order: [31:0] seq s0, [63:32] seq s1, [95:64] code s0, [127:96] code s1,
    //        [159:128] prbs s0, [191:160] prbs s1
    wire [191:0] err_cnt_rx = {prbs_cnt, code_cnt, seq_cnt};
    wire [191:0] err_cnt;

    generate
        for (i = 0; i < 6; i = i + 1) begin : g_err_cdc
            xpm_cdc_gray #(
                .DEST_SYNC_FF (4),
                .REG_OUTPUT   (1),
                .WIDTH        (32)
            ) u_cdc (
                .src_clk      (rx_usrclk2),
                .src_in_bin   (err_cnt_rx[32*i +: 32]),
                .dest_clk     (pl_clk0),
                .dest_out_bin (err_cnt[32*i +: 32])
            );
        end
    endgenerate

    // ---------------------------------------------------------------------------------------------
    // MMCM on the recovered clock: 62.5 x 16 = 1000 MHz VCO; /4 = 250 MHz, /16 = 62.5 MHz
    // ---------------------------------------------------------------------------------------------
    wire mmcm_fb, mmcm_clk250, mmcm_clk62, mmcm_locked;
    wire clk250, clk62;

    MMCME4_BASE #(
        .CLKIN1_PERIOD    (16.000),
        .DIVCLK_DIVIDE    (1),
        .CLKFBOUT_MULT_F  (16.000),
        .CLKOUT0_DIVIDE_F (4.000),
        .CLKOUT1_DIVIDE   (16)
    ) u_mmcm (
        .CLKIN1   (rx_usrclk2),
        .CLKFBIN  (mmcm_fb),
        .CLKFBOUT (mmcm_fb),
        .CLKOUT0  (mmcm_clk250),
        .CLKOUT1  (mmcm_clk62),
        .LOCKED   (mmcm_locked),
        .PWRDWN   (1'b0),
        .RST      (~rx_active | vio_mmcm_reset)
    );

    BUFG u_bufg_clk250 (.I (mmcm_clk250), .O (clk250));
    BUFG u_bufg_clk62  (.I (mmcm_clk62),  .O (clk62));

    // ---------------------------------------------------------------------------------------------
    // Frequency counters: counts per 1 s gate of pl_clk0 (125,000,000 cycles) = Hz
    // ---------------------------------------------------------------------------------------------
    wire [31:0] f_refclk, f_txusr, f_rxusr, f_clk250, f_clk62;

    freq_counter #(.GATE (125000000)) u_f_refclk (.ref_clk (pl_clk0), .meas_clk (refclk_fabric), .freq (f_refclk));
    freq_counter #(.GATE (125000000)) u_f_txusr  (.ref_clk (pl_clk0), .meas_clk (tx_usrclk2),    .freq (f_txusr));
    freq_counter #(.GATE (125000000)) u_f_rxusr  (.ref_clk (pl_clk0), .meas_clk (rx_usrclk2),    .freq (f_rxusr));
    freq_counter #(.GATE (125000000)) u_f_clk250 (.ref_clk (pl_clk0), .meas_clk (clk250),        .freq (f_clk250));
    freq_counter #(.GATE (125000000)) u_f_clk62  (.ref_clk (pl_clk0), .meas_clk (clk62),         .freq (f_clk62));

    // ---------------------------------------------------------------------------------------------
    // Status into pl_clk0
    // ---------------------------------------------------------------------------------------------
    wire [1:0] s_qsfp;        // {intl, modprsl}            (both active low)
    wire [6:0] s_core;        // {mmcm_locked, rx_active, tx_active, cdr_stable, rx_done, tx_done, qpll0lock}
    wire [1:0] s_powergood;
    wire [3:0] s_pmadone;     // {rxpmaresetdone[1:0], txpmaresetdone[1:0]}
    wire [1:0] s_aligned;     // rxbyteisaligned
    wire [1:0] s_cdrlock;
    wire [1:0] s_prbslocked;
    wire [5:0] s_rxbuf;
    wire [3:0] s_txbuf;

    sync_bits #(.W (2)) u_s_qsfp   (.clk (pl_clk0), .d ({qsfp_intl, qsfp_modprsl}), .q (s_qsfp));
    sync_bits #(.W (7)) u_s_core   (.clk (pl_clk0),
        .d ({mmcm_locked, rx_active, tx_active, cdr_stable, rx_done, tx_done, qpll0lock}), .q (s_core));
    sync_bits #(.W (2)) u_s_pg     (.clk (pl_clk0), .d (gtpowergood),                     .q (s_powergood));
    sync_bits #(.W (4)) u_s_pma    (.clk (pl_clk0), .d ({rxpmaresetdone, txpmaresetdone}), .q (s_pmadone));
    sync_bits #(.W (2)) u_s_align  (.clk (pl_clk0), .d (rxbyteisaligned),                 .q (s_aligned));
    sync_bits #(.W (2)) u_s_cdr    (.clk (pl_clk0), .d (rxcdrlock),                       .q (s_cdrlock));
    sync_bits #(.W (2)) u_s_prbsl  (.clk (pl_clk0), .d (rxprbslocked),                    .q (s_prbslocked));
    sync_bits #(.W (6)) u_s_rxbuf  (.clk (pl_clk0), .d (rxbufstatus),                     .q (s_rxbuf));
    sync_bits #(.W (4)) u_s_txbuf  (.clk (pl_clk0), .d (txbufstatus),                     .q (s_txbuf));

    // ---------------------------------------------------------------------------------------------
    // VIO (pl_clk0)
    // ---------------------------------------------------------------------------------------------
    vio_ctrl u_vio (
        .clk        (pl_clk0),
        .probe_in0  (s_qsfp),
        .probe_in1  (s_core),
        .probe_in2  (s_powergood),
        .probe_in3  (s_pmadone),
        .probe_in4  (s_aligned),
        .probe_in5  (s_cdrlock),
        .probe_in6  (s_prbslocked),
        .probe_in7  (s_rxbuf),
        .probe_in8  (s_txbuf),
        .probe_in9  (f_refclk),
        .probe_in10 (f_txusr),
        .probe_in11 (f_rxusr),
        .probe_in12 (f_clk250),
        .probe_in13 (f_clk62),
        .probe_in14 (err_cnt[31:0]),      // seq errors, slice 0
        .probe_in15 (err_cnt[63:32]),     // seq errors, slice 1
        .probe_in16 (err_cnt[95:64]),     // code errors, slice 0
        .probe_in17 (err_cnt[127:96]),    // code errors, slice 1
        .probe_in18 (err_cnt[159:128]),   // PRBS errors, slice 0
        .probe_in19 (err_cnt[191:160]),   // PRBS errors, slice 1
        .probe_out0 (vio_reset_all),
        .probe_out1 (vio_reset_rx_datapath),
        .probe_out2 (vio_loopback),
        .probe_out3 (vio_rxpolarity),
        .probe_out4 (vio_txpolarity),
        .probe_out5 (vio_prbssel),
        .probe_out6 (vio_txprbsforceerr),
        .probe_out7 (vio_rxcdrhold),
        .probe_out8 (vio_cnt_reset),
        .probe_out9 (vio_mmcm_reset)
    );

    // ---------------------------------------------------------------------------------------------
    // ILA on the RX data (rx_usrclk2)
    //   probe2/3 per slice: {seq_err, code_err, prbserr, commadet, byterealign, byteisaligned,
    //                        notintable[1:0], disperr[1:0], is_k[1:0]}
    // ---------------------------------------------------------------------------------------------
    ila_rx u_ila_rx (
        .clk    (rx_usrclk2),
        .probe0 (rxdata[15:0]),
        .probe1 (rxdata[31:16]),
        .probe2 ({seq_err[0], code_err[0], rxprbserr[0], rxcommadet[0], rxbyterealign[0],
                  rxbyteisaligned[0], rxctrl3[1:0], rxctrl1[1:0], rxctrl0[1:0]}),
        .probe3 ({seq_err[1], code_err[1], rxprbserr[1], rxcommadet[1], rxbyterealign[1],
                  rxbyteisaligned[1], rxctrl3[9:8], rxctrl1[17:16], rxctrl0[17:16]})
    );

endmodule


// -------------------------------------------------------------------------------------------------
// 32-bit saturating event counter
// -------------------------------------------------------------------------------------------------
module sat_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        inc,
    output reg  [31:0] count = 32'd0
);
    always @(posedge clk) begin
        if (rst)
            count <= 32'd0;
        else if (inc && count != 32'hFFFF_FFFF)
            count <= count + 32'd1;
    end
endmodule


// -------------------------------------------------------------------------------------------------
// Frequency counter: meas_clk edges per GATE cycles of ref_clk.
// A free-running counter in meas_clk crosses to ref_clk in Gray code; the result is the difference
// between two snapshots one gate apart. It reads 0 when meas_clk is stopped.
// -------------------------------------------------------------------------------------------------
module freq_counter #(
    parameter integer GATE = 125000000
) (
    input  wire        ref_clk,
    input  wire        meas_clk,
    output reg  [31:0] freq = 32'd0
);
    reg  [31:0] meas_cnt = 32'd0;
    always @(posedge meas_clk)
        meas_cnt <= meas_cnt + 32'd1;

    wire [31:0] meas_sync;
    xpm_cdc_gray #(
        .DEST_SYNC_FF (4),
        .REG_OUTPUT   (1),
        .WIDTH        (32)
    ) u_cdc (
        .src_clk      (meas_clk),
        .src_in_bin   (meas_cnt),
        .dest_clk     (ref_clk),
        .dest_out_bin (meas_sync)
    );

    reg [31:0] gate = 32'd0;
    reg [31:0] last = 32'd0;
    always @(posedge ref_clk) begin
        if (gate == GATE - 1) begin
            gate <= 32'd0;
            freq <= meas_sync - last;
            last <= meas_sync;
        end else begin
            gate <= gate + 32'd1;
        end
    end
endmodule


// -------------------------------------------------------------------------------------------------
// Bit-wise synchronizer for asynchronous or quasi-static status bits
// -------------------------------------------------------------------------------------------------
module sync_bits #(
    parameter integer W = 1
) (
    input  wire         clk,
    input  wire [W-1:0] d,
    output wire [W-1:0] q
);
    xpm_cdc_array_single #(
        .DEST_SYNC_FF  (4),
        .SRC_INPUT_REG (0),
        .WIDTH         (W)
    ) u_sync (
        .src_clk  (1'b0),
        .src_in   (d),
        .dest_clk (clk),
        .dest_out (q)
    );
endmodule
