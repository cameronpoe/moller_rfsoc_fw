`timescale 1ns / 1ps

module self_trigger_tb;

    reg aclk = 1'b1;
    reg aresetn = 1'b1;
    
    wire load;
    assign load = 1'b0;
    
    wire [63:0] load_ts;
    assign load_ts = 63'd0;
    
    wire [63:0] ts;
    
    wire [63:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    
    reg tlast = 1'b0;
    
    always
        #4 aclk = ~aclk;
    
    subsystem_timestamp dut_ts (
        .aclk(aclk),
        .aresetn(aresetn),
        .load(load),
        .load_ts(load_ts),
        .ts(ts)
    );
    
    self_trigger  #(.CLOCK_CYCLES(8)) dut_trigger (
        .aclk(aclk),
        .aresetn(aresetn),
        .ts_in(ts),
        .s_tlast(tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );
        
    initial begin
        
        repeat (200)
            @(posedge aclk);
            
        aresetn <= 1'b0;
        
        repeat (64)
            @(posedge aclk);
            
        aresetn <= 1'b1;
        
        repeat (100)
            @(posedge aclk);
            
        tlast <= 1'b1;
        
        repeat (1)
            @(posedge aclk);
        
        tlast <= 1'b0;
        repeat (203)
            @(posedge aclk);
            
        tlast <= 1'b1;
        
        repeat (1)
            @(posedge aclk);
        
        tlast <= 1'b0;
        repeat (203)
            @(posedge aclk);
            
    end
    
endmodule
