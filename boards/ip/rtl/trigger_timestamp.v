`timescale 1ns / 1ps

module trigger_timestamp(

    input aclk,
    input aresetn,
    
    input trigger_self,
    input trigger_ext,
    input [62:0] ts,
    
    input trigger_select,
    input [31:0] num_triggers,
    
    output reg [63:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast    
    );
    
    wire trigger_ext_stable;
    
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),      // number of sync stages
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)      // source is async/no clock, so 0
    ) trigger_cdc (
        .src_clk(1'b0),        // unused when SRC_INPUT_REG=0
        .src_in(trigger_ext),
        .dest_clk(aclk),
        .dest_out(trigger_ext_stable)
    );
        
    wire trigger;
    assign trigger = trigger_select ? trigger_ext_stable : trigger_self;
    
    reg trigger_prev;
    reg [31:0] counter = 32'b0;
    reg first_rising_detected = 1'b0;
    reg assert_tlast = 1'b0;
    
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            m_axis_tdata <= 64'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            trigger_prev <= 1'bx; 
            counter <= 32'd0;
            first_rising_detected <= 1'b0;
            assert_tlast <= 1'b0;
        end else begin
            if ((trigger == 1'b1) & (trigger_prev == 1'b0)) begin
                // We've detected a gate rising edge
                m_axis_tdata <= {1'b0, ts}; // MSB for rising is 0
                m_axis_tvalid <= 1'b1;
                if (counter == 32'b0) begin
                    first_rising_detected <= 1'b1;
                    counter <= counter + 32'd1;
                end else if (counter == num_triggers-1) begin
                    // We've reached the number of gates we want
                    assert_tlast <= 1'b1;
                    counter <= 32'd0;
                end else
                    counter <= counter + 32'd1;
            end else if ((trigger == 1'b0) & (trigger_prev == 1'b1)) begin
                // We've detected a gate falling edge
                if (first_rising_detected) begin
                    m_axis_tdata <= {1'b1, ts}; // MSB for falling is 1
                    m_axis_tvalid <= 1'b1;
                    if (assert_tlast) begin
                        m_axis_tlast <= 1'b1;
                        assert_tlast <= 1'b0;
                        first_rising_detected <= 1'b0;
                    end
                end
            end else begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0; 
            end
            
            trigger_prev <= trigger; 
        end
    end
endmodule
