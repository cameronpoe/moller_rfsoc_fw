`timescale 1ns / 1ps

module octet_signal_24bit_signed_tb;

    reg aclk = 1'b1; 
    always
        # 8 aclk = ~aclk;
        
    reg aresetn = 1'b1;
    
    wire [23:0] m00_axis_tdata;
    wire m00_axis_tvalid;
    
    wire [23:0] m01_axis_tdata;
    wire m01_axis_tvalid;
    
    wire [23:0] m02_axis_tdata;
    wire m02_axis_tvalid;
    
    wire [23:0] m03_axis_tdata;
    wire m03_axis_tvalid;
    
    wire [23:0] m04_axis_tdata;
    wire m04_axis_tvalid;
    
    wire [23:0] m05_axis_tdata;
    wire m05_axis_tvalid;
    
    wire [23:0] m06_axis_tdata;
    wire m06_axis_tvalid;
    
    wire [23:0] m07_axis_tdata;
    wire m07_axis_tvalid;
        
    octet_signal_24bit_signed dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .m00_axis_tdata(m00_axis_tdata),
        .m00_axis_tvalid(m00_axis_tvalid),
        .m01_axis_tdata(m01_axis_tdata),
        .m01_axis_tvalid(m01_axis_tvalid),
        .m02_axis_tdata(m02_axis_tdata),
        .m02_axis_tvalid(m02_axis_tvalid),
        .m03_axis_tdata(m03_axis_tdata),
        .m03_axis_tvalid(m03_axis_tvalid),
        .m04_axis_tdata(m04_axis_tdata),
        .m04_axis_tvalid(m04_axis_tvalid),
        .m05_axis_tdata(m05_axis_tdata),
        .m05_axis_tvalid(m05_axis_tvalid),
        .m06_axis_tdata(m06_axis_tdata),
        .m06_axis_tvalid(m06_axis_tvalid),
        .m07_axis_tdata(m07_axis_tdata),
        .m07_axis_tvalid(m07_axis_tvalid)
    );
    
    initial begin
    
        repeat(40)
            @(posedge aclk);
            
        aresetn <= 1'b0;
        
        repeat(51)
            @(posedge aclk);
            
        aresetn <= 1'b1;
        
        repeat(400)
            @(posedge aclk);      
    
    end
endmodule
