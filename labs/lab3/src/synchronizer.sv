// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/21/2026
//
// Purpose: Two-flop synchronizer for asynchronous inputs.

module synchronizer #(
	parameter WIDTH = 4
)(
	input	logic				clk,
	input	logic [WIDTH-1:0]	d,
	output	logic [WIDTH-1:0]	q
);

	logic [WIDTH-1:0] p;

	always_ff @(posedge clk) begin
		p <= d;
		q <= p;
	end

endmodule
