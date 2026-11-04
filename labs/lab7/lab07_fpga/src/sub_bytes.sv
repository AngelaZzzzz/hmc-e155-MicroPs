// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	10/30/2026
//
// Purpose: SubBytes (FIPS-197 5.1.1).

module sub_bytes(
	input	logic			clk,
	input	logic [127:0]	a,
	output	logic [127:0]	y
);

	sbox_sync sb0 (a[7:0],      clk, y[7:0]);
	sbox_sync sb1 (a[15:8],     clk, y[15:8]);
	sbox_sync sb2 (a[23:16],    clk, y[23:16]);
	sbox_sync sb3 (a[31:24],    clk, y[31:24]);
	sbox_sync sb4 (a[39:32],    clk, y[39:32]);
	sbox_sync sb5 (a[47:40],    clk, y[47:40]);
	sbox_sync sb6 (a[55:48],    clk, y[55:48]);
	sbox_sync sb7 (a[63:56],    clk, y[63:56]);
	sbox_sync sb8 (a[71:64],    clk, y[71:64]);
	sbox_sync sb9 (a[79:72],    clk, y[79:72]);
	sbox_sync sb10(a[87:80],    clk, y[87:80]);
	sbox_sync sb11(a[95:88],    clk, y[95:88]);
	sbox_sync sb12(a[103:96],   clk, y[103:96]);
	sbox_sync sb13(a[111:104],  clk, y[111:104]);
	sbox_sync sb14(a[119:112],  clk, y[119:112]);
	sbox_sync sb15(a[127:120],  clk, y[127:120]);

endmodule
