`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// subsystem_timestamp is lifted from moller_adc firmware with minor modification
// 
//////////////////////////////////////////////////////////////////////////////////

module subsystem_timestamp #(
    parameter WIDTH = 64
)(
    input wire aclk,
    input wire aresetn,

    input wire load,
    input wire [WIDTH-1:0] load_ts,

    output reg [WIDTH-1:0] ts = 1'b0
);

// Timestamp logic
always@(posedge aclk) begin
	ts <= (~aresetn) ? 0 : (load) ? load_ts : ts + 1'b1;
end

endmodule
