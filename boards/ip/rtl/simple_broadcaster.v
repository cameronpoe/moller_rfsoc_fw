`timescale 1ns / 1ps

module simple_broadcaster(

    input aclk,
    input aresetn,
    
    input wire [1:0] dma_select, 
    
    input wire [63:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    output reg [63:0] m0_axis_tdata,
    output reg m0_axis_tvalid,
    output reg m0_axis_tlast,
    input wire m0_axis_tready,
    
    output reg [63:0] m1_axis_tdata,
    output reg m1_axis_tvalid,
    output reg m1_axis_tlast,
    input wire m1_axis_tready

    );
    
    // Maybe can expand this at some later time if need be (leaving option open)
    assign s_axis_tready = (dma_select == 2'b00) ? m0_axis_tready :
                           (dma_select == 2'b01) ? m1_axis_tready : m0_axis_tready;
                               
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
        
            m0_axis_tvalid <= 1'b0;
            m1_axis_tvalid <= 1'b0;
            
        end else begin
            
            m0_axis_tdata <= s_axis_tdata;
            m0_axis_tvalid <= s_axis_tvalid;
            m0_axis_tlast <= s_axis_tlast;
            m1_axis_tdata <= s_axis_tdata;
            m1_axis_tvalid <= s_axis_tvalid;
            m1_axis_tlast <= s_axis_tlast;
            
        end
    end  
    
endmodule
