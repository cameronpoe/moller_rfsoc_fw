`timescale 1ns / 1ps

module signal_source_24bit(

    input wire aclk,
    input wire aresetn,
    
    input wire [23:0] offset,
    input wire [7:0] increment,
    
    output reg [23:0] m_axis_tdata,
    output reg m_axis_tvalid = 1'b0
    );
    
    reg [2:0] counter = 1'b0;
    reg reset_state = 1'b1;
    
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            counter = 3'd0;
            m_axis_tdata = 16'b0 + offset;
            m_axis_tvalid = 1'b0;
            reset_state = 1'b1;
        end else begin
            if (aresetn == 1'b1 && reset_state == 1'b1) begin
                m_axis_tvalid <= 1'b1;
                reset_state <= 1'b0;
                
            end else begin
                if (counter == 7) begin
                    m_axis_tdata = m_axis_tdata + increment;
                    m_axis_tvalid = 1'b1;
                end else begin
                    m_axis_tvalid = 1'b0;
                end
                counter <= counter + 3'b1;
            end
        end
    end
    
endmodule
