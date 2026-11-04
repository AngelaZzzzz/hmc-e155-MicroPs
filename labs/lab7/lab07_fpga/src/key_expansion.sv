// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	10/30/2026
//
// Purpose: One step of KeyExpansion (FIPS-197 5.2) for Nk = 4, producing the next round key
//			from the previous one.

module key_expansion(
	input	logic			clk,
	input	logic [127:0]	prev_key,
	input	logic [7:0]		rcon,
	output	logic [127:0]	next_key
);

	logic [31:0] w0, w1, w2, w3, rot_word, sub_word, temp;

	assign {w0, w1, w2, w3} = prev_key;
	assign rot_word = {w3[23:0], w3[31:24]};

	sbox_sync sb0(rot_word[31:24], clk, sub_word[31:24]);
	sbox_sync sb1(rot_word[23:16], clk, sub_word[23:16]);
	sbox_sync sb2(rot_word[15:8],  clk, sub_word[15:8]);
	sbox_sync sb3(rot_word[7:0],   clk, sub_word[7:0]);

	assign temp = sub_word ^ {rcon, 24'h0};

	assign next_key[127:96] = w0 ^ temp;
	assign next_key[95:64]  = w1 ^ next_key[127:96];
	assign next_key[63:32]  = w2 ^ next_key[95:64];
	assign next_key[31:0]   = w3 ^ next_key[63:32];

endmodule
