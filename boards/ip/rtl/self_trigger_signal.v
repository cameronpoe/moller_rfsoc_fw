`timescale 1ns / 1ps

module self_trigger_signal (
    
    input aclk,
    input aresetn,
    
    input [31:0] aclk_cycles_full,
    input [31:0] aclk_cycles_stable,
    
    output reg trigger_signal = 1'b0
    
    );
    
    reg [63:0] counter = 64'd0;
    
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            trigger_signal <= 1'b0;
            counter <= 64'd0;
        end else begin
            if (counter < aclk_cycles_stable-1) begin
                trigger_signal <= 1'b1;
            end else if ((counter >= aclk_cycles_stable) & (counter < aclk_cycles_full-1)) begin
                trigger_signal <= 1'b0;
            end
            
            if (counter < aclk_cycles_full-1)
                counter <= counter + 64'd1;
            else
                counter <= 64'd0;
        end
    end
    
endmodule