`timescale 1ns / 1ps

module self_trigger #(
    // CLOCK_CYCLES is the number of aclk cycles between trigger.
    // For 1.92 kHz, this is 
    parameter CLOCK_CYCLES = 65104
)(
    input aclk,
    input aresetn,
    
    input [63:0] ts_in,
    
    input s_tlast,
    
    output reg [63:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast
    );
    
    reg [63:0] counter = 64'd0;
    
    reg s_tlast_prior_clk_cycle = 1'b0;
    reg assert_tlast = 1'b0;
    
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            counter <= 64'd0;
            m_axis_tdata <= 64'd0;
            m_axis_tvalid <= 1'b0;
            s_tlast_prior_clk_cycle <= 1'b0;
            assert_tlast <= 1'b0;
        end else begin
        
            if ((s_tlast_prior_clk_cycle == 1'b0) & (s_tlast == 1'b1))
                assert_tlast <= 1'b1;
            
            if (counter == CLOCK_CYCLES-1) begin
                m_axis_tdata <= ts_in;
                m_axis_tvalid <= 1'b1;
                if (assert_tlast)
                    m_axis_tlast <= 1'b1;
                counter <= 64'd0;
                assert_tlast <= 1'b0;
            end else begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                counter <= counter + 1'b1;
            end
            
            s_tlast_prior_clk_cycle <= s_tlast;
        end
    end
endmodule
