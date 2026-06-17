`timescale 1ns / 1ps

// Assumes all slave AXI streams have tvalid go high once every 8 aclk cycles, and all tvalids go high on same beat.
module adc_mux_v2 # (parameter NUM_STREAMS=8, IN_DATA_WIDTH=24, OUT_DATA_WIDTH=64, TS_WIDTH=63) (

    input aclk,
    input aresetn,
    
    input use_ramp,
    
    input [TS_WIDTH-1:0] ts,
    
    input [IN_DATA_WIDTH-1:0] s_axis_0_tdata,
    input s_axis_0_tvalid,
    output s_axis_0_tready,
    
    input [IN_DATA_WIDTH-1:0] s_axis_1_tdata,
    input s_axis_1_tvalid,
    output s_axis_1_tready,
    
    input [IN_DATA_WIDTH-1:0] s_axis_2_tdata,
    input s_axis_2_tvalid,
    output s_axis_2_tready,
    
    input [IN_DATA_WIDTH-1:0] s_axis_3_tdata,
    input s_axis_3_tvalid,
    output s_axis_3_tready,
    
    input [IN_DATA_WIDTH-1:0] s_axis_4_tdata,
    input s_axis_4_tvalid,
    output s_axis_4_tready,
    
    input [IN_DATA_WIDTH-1:0] s_axis_5_tdata,
    input s_axis_5_tvalid,
    output s_axis_5_tready,
    
    input [IN_DATA_WIDTH-1:0] s_axis_6_tdata,
    input s_axis_6_tvalid,
    output s_axis_6_tready,
    
    input [IN_DATA_WIDTH-1:0] s_axis_7_tdata,
    input s_axis_7_tvalid,
    output s_axis_7_tready,
    
    output reg [OUT_DATA_WIDTH-1:0] m_axis_tdata,
    output reg m_axis_tvalid = 1'b0,
    input m_axis_tready,
    output reg m_axis_tlast = 1'b0,
    output reg m_axis_tuser = 1'b0       
    );
        
    // We only have one tready, so assign all xtready to one reg. 
    reg tready = 1'b0;
    assign s_axis_0_tready = tready;
    assign s_axis_1_tready = tready;
    assign s_axis_2_tready = tready;
    assign s_axis_3_tready = tready;
    assign s_axis_4_tready = tready;
    assign s_axis_5_tready = tready;
    assign s_axis_6_tready = tready;
    assign s_axis_7_tready = tready;
    
    wire [NUM_STREAMS*IN_DATA_WIDTH-1:0] all_streams;
    assign all_streams = use_ramp ? ramp_signal : {s_axis_0_tdata, s_axis_1_tdata, s_axis_2_tdata, s_axis_3_tdata, s_axis_4_tdata, s_axis_5_tdata, s_axis_6_tdata, s_axis_7_tdata};
    
    wire all_valid;
    assign all_valid = use_ramp ? &ramp_tvalid : s_axis_0_tvalid & s_axis_1_tvalid & s_axis_2_tvalid & s_axis_3_tvalid & s_axis_4_tvalid & s_axis_5_tvalid & s_axis_6_tvalid & s_axis_7_tvalid;
     
    reg [NUM_STREAMS*IN_DATA_WIDTH-1:0] all_streams_buffer; 
     
    
    wire [191:0] ramp_signal;
    wire [7:0] ramp_tvalid;
    
    octet_signal_24bit_signed octet_ramp_signal (
        .aclk(aclk),
        .aresetn(aresetn),
        .m00_axis_tdata(ramp_signal[191:168]),
        .m00_axis_tvalid(ramp_tvalid[7]),
        .m01_axis_tdata(ramp_signal[167:144]),
        .m01_axis_tvalid(ramp_tvalid[6]),
        .m02_axis_tdata(ramp_signal[143:120]),
        .m02_axis_tvalid(ramp_tvalid[5]),
        .m03_axis_tdata(ramp_signal[119:96]),
        .m03_axis_tvalid(ramp_tvalid[4]),
        .m04_axis_tdata(ramp_signal[95:72]),
        .m04_axis_tvalid(ramp_tvalid[3]),
        .m05_axis_tdata(ramp_signal[71:48]),
        .m05_axis_tvalid(ramp_tvalid[2]),
        .m06_axis_tdata(ramp_signal[47:24]),
        .m06_axis_tvalid(ramp_tvalid[1]),
        .m07_axis_tdata(ramp_signal[23:0]),
        .m07_axis_tvalid(ramp_tvalid[0])
    );
       
    reg [2:0] counter = 3'd0; 
        
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            counter <= 3'd0;
            tready <= 1'b0;
            all_streams_buffer <= 192'd0;
            m_axis_tdata <= 0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin 
            if (all_valid == 1'b1) 
                all_streams_buffer <= all_streams;
            if (counter == 3'd0 && tready == 1'b0) begin
                tready <= 1'b1;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                m_axis_tuser <= 1'b0;
            end else if (all_valid == 1'b1 && tready == 1'b1) begin
                // We now have a valid sample in all_streams_buffer. So we need to drive tready low and start the counter
                tready <= 1'b0;
                counter <= counter + 3'd1;
                m_axis_tdata <= {1'b0, ts};
                m_axis_tvalid <= 1'b1;
                m_axis_tuser <= 1'b1; // tuser high denotes a ts, not an ADC sample. 
            end else if (counter != 3'd0) begin
                m_axis_tdata <= all_streams_buffer[(4-counter)*OUT_DATA_WIDTH-1 -: OUT_DATA_WIDTH];
                m_axis_tvalid <= 1'b1;
                m_axis_tuser <= 1'b0;
                if (counter == 3'd3) begin
                    counter <= 3'd0;
                    m_axis_tlast <= 1'b1;
                end else begin
                    counter <= counter + 3'd1;
                    m_axis_tlast <= 1'b0;
                end
            end else begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                m_axis_tuser <= 1'b0;
            end
            
        end
        
    end    
    
endmodule
