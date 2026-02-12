`timescale 1ns / 1ps

module octet_signal_24bit(

    input wire aclk,
    input wire aresetn,
    
    output [23:0] m00_axis_tdata,
    output m00_axis_tvalid,
    
    output [23:0] m01_axis_tdata,
    output m01_axis_tvalid,
    
    output [23:0] m02_axis_tdata,
    output m02_axis_tvalid, 
    
    output [23:0] m03_axis_tdata,
    output m03_axis_tvalid, 
    
    output [23:0] m04_axis_tdata,
    output m04_axis_tvalid, 
    
    output [23:0] m05_axis_tdata,
    output m05_axis_tvalid, 
    
    output [23:0] m06_axis_tdata,
    output m06_axis_tvalid, 
    
    output [23:0] m07_axis_tdata,
    output m07_axis_tvalid 

    );
    
    wire [7:0] increment;
    assign increment = 8'd8;
    
    wire [23:0] offset_0;
    assign offset_0 = 8'd0;
    
    wire [23:0] offset_1;
    assign offset_1 = 8'd1;
    
    wire [23:0] offset_2;
    assign offset_2 = 8'd2;
    
    wire [23:0] offset_3;
    assign offset_3 = 8'd3;
    
    wire [23:0] offset_4;
    assign offset_4 = 8'd4;
    
    wire [23:0] offset_5;
    assign offset_5 = 8'd5;
    
    wire [23:0] offset_6;
    assign offset_6 = 8'd6;
    
    wire [23:0] offset_7;
    assign offset_7 = 8'd7;
    
    signal_source_24bit signal_0 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_0),
        .increment(increment),
        .m_axis_tdata(m00_axis_tdata),
        .m_axis_tvalid(m00_axis_tvalid)
    );
    
    signal_source_24bit signal_1 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_1),
        .increment(increment),
        .m_axis_tdata(m01_axis_tdata),
        .m_axis_tvalid(m01_axis_tvalid)
    );
    
    signal_source_24bit signal_2 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_2),
        .increment(increment),
        .m_axis_tdata(m02_axis_tdata),
        .m_axis_tvalid(m02_axis_tvalid)
    );
    
    signal_source_24bit signal_3 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_3),
        .increment(increment),
        .m_axis_tdata(m03_axis_tdata),
        .m_axis_tvalid(m03_axis_tvalid)
    );
    
    signal_source_24bit signal_4 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_4),
        .increment(increment),
        .m_axis_tdata(m04_axis_tdata),
        .m_axis_tvalid(m04_axis_tvalid)
    );
    
    signal_source_24bit signal_5 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_5),
        .increment(increment),
        .m_axis_tdata(m05_axis_tdata),
        .m_axis_tvalid(m05_axis_tvalid)
    );
    
    signal_source_24bit signal_6 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_6),
        .increment(increment),
        .m_axis_tdata(m06_axis_tdata),
        .m_axis_tvalid(m06_axis_tvalid)
    );
    
    signal_source_24bit signal_7 (
        .aclk(aclk),
        .aresetn(aresetn),
        .offset(offset_7),
        .increment(increment),
        .m_axis_tdata(m07_axis_tdata),
        .m_axis_tvalid(m07_axis_tvalid)
    );
    
endmodule
