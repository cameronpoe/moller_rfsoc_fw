`timescale 1ns / 1ps

module mux_packet_pipeline_tb;
    
    reg aclk = 1'b1;
    always
        # 8 aclk <= ~aclk;
        
    reg aresetn = 1'b1;
    
    wire [23:0] m00_axis_tdata_sig;
    wire m00_axis_tvalid_sig;
    wire [23:0] m01_axis_tdata_sig;
    wire m01_axis_tvalid_sig;
    wire [23:0] m02_axis_tdata_sig;
    wire m02_axis_tvalid_sig;
    wire [23:0] m03_axis_tdata_sig;
    wire m03_axis_tvalid_sig;
    wire [23:0] m04_axis_tdata_sig;
    wire m04_axis_tvalid_sig;
    wire [23:0] m05_axis_tdata_sig;
    wire m05_axis_tvalid_sig;
    wire [23:0] m06_axis_tdata_sig;
    wire m06_axis_tvalid_sig;
    wire [23:0] m07_axis_tdata_sig;
    wire m07_axis_tvalid_sig;
    
    reg [62:0] ts = 0;
    
    always @(posedge aclk)
        ts = ts + 1;
    
    wire s_axis_0_tready_dut;
    wire s_axis_1_tready_dut;
    wire s_axis_2_tready_dut;
    wire s_axis_3_tready_dut;
    wire s_axis_4_tready_dut;
    wire s_axis_5_tready_dut;
    wire s_axis_6_tready_dut;
    wire s_axis_7_tready_dut;
    
    wire [63:0] m_axis_tdata_dut;
    wire m_axis_tvalid_dut;
    wire m_axis_tready_dut;
    wire m_axis_tlast_dut;
    wire m_axis_tuser_dut;
    
    wire [63:0] m_axis_tdata_fifo;
    wire m_axis_tvalid_fifo;
    wire m_axis_tready_fifo;
    wire m_axis_tlast_fifo;
    wire m_axis_tuser_fifo;
    
    wire [63:0] m_axis_tdata_packet;
    wire m_axis_tvalid_packet;
    reg m_axis_tready_packet = 1'b1;
    wire m_axis_tlast_packet;
                
    reg [31:0] num_words = 32'd14;
        
    octet_signal_24bit_signed signal_gen (
        .aclk(aclk),
        .aresetn(aresetn),
        .m00_axis_tdata(m00_axis_tdata_sig),
        .m00_axis_tvalid(m00_axis_tvalid_sig),
        .m01_axis_tdata(m01_axis_tdata_sig),
        .m01_axis_tvalid(m01_axis_tvalid_sig),
        .m02_axis_tdata(m02_axis_tdata_sig),
        .m02_axis_tvalid(m02_axis_tvalid_sig),
        .m03_axis_tdata(m03_axis_tdata_sig),
        .m03_axis_tvalid(m03_axis_tvalid_sig),
        .m04_axis_tdata(m04_axis_tdata_sig),
        .m04_axis_tvalid(m04_axis_tvalid_sig),
        .m05_axis_tdata(m05_axis_tdata_sig),
        .m05_axis_tvalid(m05_axis_tvalid_sig),
        .m06_axis_tdata(m06_axis_tdata_sig),
        .m06_axis_tvalid(m06_axis_tvalid_sig),
        .m07_axis_tdata(m07_axis_tdata_sig),
        .m07_axis_tvalid(m07_axis_tvalid_sig)
    );
    
    adc_mux_v2 dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .ts(ts),
        .s_axis_0_tdata(m00_axis_tdata_sig),
        .s_axis_0_tvalid(m00_axis_tvalid_sig),
        .s_axis_0_tready(s_axis_0_tready_dut),
        .s_axis_1_tdata(m01_axis_tdata_sig),
        .s_axis_1_tvalid(m01_axis_tvalid_sig),
        .s_axis_1_tready(s_axis_1_tready_dut),
        .s_axis_2_tdata(m02_axis_tdata_sig),
        .s_axis_2_tvalid(m02_axis_tvalid_sig),
        .s_axis_2_tready(s_axis_2_tready_dut),
        .s_axis_3_tdata(m03_axis_tdata_sig),
        .s_axis_3_tvalid(m03_axis_tvalid_sig),
        .s_axis_3_tready(s_axis_3_tready_dut),
        .s_axis_4_tdata(m04_axis_tdata_sig),
        .s_axis_4_tvalid(m04_axis_tvalid_sig),
        .s_axis_4_tready(s_axis_4_tready_dut),
        .s_axis_5_tdata(m05_axis_tdata_sig),
        .s_axis_5_tvalid(m05_axis_tvalid_sig),
        .s_axis_5_tready(s_axis_5_tready_dut),
        .s_axis_6_tdata(m06_axis_tdata_sig),
        .s_axis_6_tvalid(m06_axis_tvalid_sig),
        .s_axis_6_tready(s_axis_6_tready_dut),
        .s_axis_7_tdata(m07_axis_tdata_sig),
        .s_axis_7_tvalid(m07_axis_tvalid_sig),
        .s_axis_7_tready(s_axis_7_tready_dut),
        .m_axis_tdata(m_axis_tdata_dut),
        .m_axis_tvalid(m_axis_tvalid_dut),
        .m_axis_tready(m_axis_tready_dut),
        .m_axis_tlast(m_axis_tlast_dut),
        .m_axis_tuser(m_axis_tuser_dut)
    );
    
    xpm_fifo_axis #(
        .CLOCKING_MODE       ("common_clock"),  // "common_clock" or "independent_clock"
        .FIFO_DEPTH          (128),            // power of 2, >= 16
        .FIFO_MEMORY_TYPE    ("auto"),          // "auto", "block", "distributed", "ultra"
        .PACKET_FIFO         ("false"),         // "true" enables store-and-forward on TLAST
        .TDATA_WIDTH         (64),
        .TDEST_WIDTH         (1),               // set to 1 even if unused
        .TID_WIDTH           (1),
        .TUSER_WIDTH         (1),
        .USE_ADV_FEATURES    ("1000"),          // see notes below
        .PROG_FULL_THRESH    (10),
        .PROG_EMPTY_THRESH   (10),
        .RD_DATA_COUNT_WIDTH (11),
        .WR_DATA_COUNT_WIDTH (11),
        .CDC_SYNC_STAGES     (2),               // only matters for independent_clock
        .RELATED_CLOCKS      (0),
        .ECC_MODE            ("no_ecc"),
        .SIM_ASSERT_CHK      (0)
    ) u_axis_fifo (
        // Slave (input) side
        .s_aclk        (aclk),
        .s_aresetn     (aresetn),               // active-low, hold low >= 3 cycles
        .s_axis_tvalid (m_axis_tvalid_dut),
        .s_axis_tready (m_axis_tready_dut),
        .s_axis_tdata  (m_axis_tdata_dut),
        .s_axis_tkeep  (4'hF),                  // tie off if unused
        .s_axis_tstrb  (4'hF),
        .s_axis_tlast  (m_axis_tlast_dut),
        .s_axis_tid    (1'b0),
        .s_axis_tdest  (1'b0),
        .s_axis_tuser  (m_axis_tuser_dut),
    
        // Master (output) side
        .m_aclk        (aclk),                   // same as s_aclk in common_clock mode
        .m_axis_tvalid (m_axis_tvalid_fifo),
        .m_axis_tready (m_axis_tready_fifo),
        .m_axis_tdata  (m_axis_tdata_fifo),
        .m_axis_tkeep  (),
        .m_axis_tstrb  (),
        .m_axis_tlast  (m_axis_tlast_fifo),
        .m_axis_tid    (),
        .m_axis_tdest  (),
        .m_axis_tuser  (m_axis_tuser_fifo),
    
        // Status / optional
        .prog_full_axis     (),
        .wr_data_count_axis (),
        .almost_full_axis   (),
        .prog_empty_axis    (),
        .rd_data_count_axis (),
        .almost_empty_axis  (),
    
        // ECC (unused here)
        .injectsbiterr_axis (1'b0),
        .injectdbiterr_axis (1'b0),
        .sbiterr_axis       (),
        .dbiterr_axis       ()
    );
    
    adc_packetizer dut_packetizer (
        .aclk(aclk),
        .aresetn(aresetn),
        .words_per_packet(num_words),
        .s_axis_tdata(m_axis_tdata_fifo),
        .s_axis_tvalid(m_axis_tvalid_fifo),
        .s_axis_tready(m_axis_tready_fifo),
        .s_axis_tlast(m_axis_tlast_fifo),
        .s_axis_tuser(m_axis_tuser_fifo),
        .m_axis_tdata(m_axis_tdata_packet),
        .m_axis_tvalid(m_axis_tvalid_packet),
        .m_axis_tready(m_axis_tready_packet),
        .m_axis_tlast(m_axis_tlast_packet)
    );
        
    initial begin
    
        repeat (10)
            @(posedge aclk);
            
        aresetn <= 1'b0;
        
        repeat (53)
            @(posedge aclk);
            
        aresetn <= 1'b1;
        
        repeat (400)
            @(posedge aclk);
    end

endmodule
