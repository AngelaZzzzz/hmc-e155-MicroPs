// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/21/2026
//
// Purpose: Keypad row scanner, non-canonical FSM with instantiated counter +
//					output logic. Rotates through the four rows, driving one at a time, while
//					enable is high.

module keypad_scanner #(
	parameter	WIDTH		= 19,
	parameter	MAX_COUNT	= 480_000
)(
	input	logic		clk,
	input	logic		reset,
	input	logic		enable,
	output	logic [3:0]	row
);

	logic [WIDTH-1:0] count;

	// State
	counter #(WIDTH, MAX_COUNT) scan_counter(clk, reset, enable, count);

	// Output logic
	always_ff @(posedge clk, posedge reset) begin
		if (reset) row <= 4'b1000;
		else begin
    	row[3] <=  (count <  MAX_COUNT / 4);
    	row[2] <=  (count >= MAX_COUNT / 4) && (count <     MAX_COUNT / 2);
    	row[1] <=  (count >= MAX_COUNT / 2) && (count < 3 * MAX_COUNT / 4);
    	row[0] <=  (count >= 3 * MAX_COUNT / 4);
		end
	end

endmodule
