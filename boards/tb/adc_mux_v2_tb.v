`timescale 1ns / 1ps

module adc_mux_v2_tb;
    
    reg aclk = 1'b1;
    always 
        # 8 aclk = ~aclk;
        
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
    reg m_axis_tready_dut;
    wire m_axis_tlast_dut;
    wire m_axis_tuser_dut;
    
    always @(posedge aclk)
        m_axis_tready_dut <= 1'b1;
        
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
        .use_ramp(1'b0),
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
        
    initial begin
        
        repeat (10)
            @(posedge aclk);
            
        aresetn <= 1'b0;
        
        repeat (53)
            @(posedge aclk);
            
        aresetn <= 1'b1;
        
        repeat (300)
            @(posedge aclk);
            
    end

endmodule
