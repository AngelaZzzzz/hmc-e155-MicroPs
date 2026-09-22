// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/21/2026
//
// Purpose: This is a combinational decoder that maps the keypad input to the hex digit printed
//			on that key.

module key_decoder(
	input	logic [3:0]	row,
	input	logic [3:0]	col,
	output	logic [3:0]	key
);

	always_comb begin
		case ({row, col})
			{4'b0001, 4'b0001}: key = 4'h1;	// row 0, col 0
			{4'b0001, 4'b0010}: key = 4'h2;	// row 0, col 1
			{4'b0001, 4'b0100}: key = 4'h3;	// row 0, col 2
			{4'b0001, 4'b1000}: key = 4'hA;	// row 0, col 3

			{4'b0010, 4'b0001}: key = 4'h4;	// row 1, col 0
			{4'b0010, 4'b0010}: key = 4'h5;	// row 1, col 1
			{4'b0010, 4'b0100}: key = 4'h6;	// row 1, col 2
			{4'b0010, 4'b1000}: key = 4'hB;	// row 1, col 3

			{4'b0100, 4'b0001}: key = 4'h7;	// row 2, col 0
			{4'b0100, 4'b0010}: key = 4'h8;	// row 2, col 1
			{4'b0100, 4'b0100}: key = 4'h9;	// row 2, col 2
			{4'b0100, 4'b1000}: key = 4'hC;	// row 2, col 3

			{4'b1000, 4'b0001}: key = 4'hE;	// row 3, col 0
			{4'b1000, 4'b0010}: key = 4'h0;	// row 3, col 1
			{4'b1000, 4'b0100}: key = 4'hF;	// row 3, col 2
			{4'b1000, 4'b1000}: key = 4'hD;	// row 3, col 3

			default:            key = 4'h0; // default should be 00
		endcase
	end

endmodule
