// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/18/2026
//
// Purpose: Two-digit shift register for the display. When key_valid, the new digit
//			enters on the right and the previous right digit moves to the left.

module digit_register(
	input	logic		clk,
	input	logic		reset,
	input	logic		key_valid,
	input	logic [3:0]	key,
	output	logic [3:0]	digit_left,
	output	logic [3:0]	digit_right
);

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			digit_left  <= 4'h0;
			digit_right <= 4'h0;
		end else if (key_valid) begin
			digit_left  <= digit_right;
			digit_right <= key;
		end
	end

endmodule
