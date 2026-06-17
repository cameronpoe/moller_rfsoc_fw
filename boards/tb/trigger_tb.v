`timescale 1ns / 1ps

module trigger_tb;
    
    reg aclk = 1'b1;    
    always
        #4 aclk = ~aclk;
        
    reg aresetn = 1'b1;
    
    reg trigger_select = 1'b0;
    reg [31:0] num_triggers = 32'd11;
    
    wire trigger_self;
    wire trigger_ext;
    
    reg [31:0] aclk_cycles_full = 32'd23;
    reg [31:0] aclk_cycles_stable = 32'd19;
    
    wire [63:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    
    wire [62:0] ts;
    
    self_trigger_signal dut_trigger_self (
        .aclk(aclk),
        .aresetn(aresetn),
        .aclk_cycles_full(aclk_cycles_full),
        .aclk_cycles_stable(aclk_cycles_stable),
        .trigger_signal(trigger_self)
    );
    
    self_trigger_signal dut_trigger_ext (
        .aclk(aclk),
        .aresetn(aresetn),
        .aclk_cycles_full(aclk_cycles_full),
        .aclk_cycles_stable(aclk_cycles_stable),
        .trigger_signal(trigger_ext)
    );
    
    trigger_timestamp trigger_timestamp_dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .trigger_self(trigger_self),
        .trigger_ext(trigger_ext),
        .ts(ts),
        .trigger_select(trigger_select),
        .num_triggers(num_triggers),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );
    
    subsystem_timestamp #(.WIDTH(63)) subsystem_timestamp_dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .load(1'b0),
        .load_ts(63'd0),
        .ts(ts)
    );
    
    initial begin
        repeat(27)
            @(posedge aclk);
        
        aresetn <= 1'b0;
        
        repeat(32)
            @(posedge aclk);
        
        aresetn <= 1'b1;
        
        repeat(500)
            @(posedge aclk);
            
        trigger_select <= 1'b1;
        
        repeat(500)
            @(posedge aclk);
            
    end

endmodule
