// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/7/2026
//
// Purpose: This is a reusable counter that accepts parameters WIDTH (size of count) and MAX_COUNT.
// 			This counter counts from 0 to MAX_COUNT-1 on each positive clock edge when enable = 1'b1,
//				and wraps back to 0 when MAX_COUNT is reached.

module counter #(
	parameter WIDTH = 		25,
	parameter MAX_COUNT =	20_000_000
)(	
	input	logic				clk,
	input 	logic				reset,
	input 	logic				enable,
	output	logic [WIDTH-1:0] 	count
);
	
	// Clock divider
	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			count <= 0;
		end else if (enable) begin
			if (count == MAX_COUNT-1) begin
				count <= 0;
			end else begin
				count <= count + 1;
			end
		end
	end

endmodule