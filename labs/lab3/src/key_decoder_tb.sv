// Author:	Angela Zheng
// Email: 	angzheng@hmc.edu
// Date: 	9/21/2026
//
// Purpose: Testbench for key_decoder. Checks every one-hot row/column pair against the
//			printed keypad legend, and that inputs that are not one-hot decode to 0.

`timescale 1 ns/1 ns

module key_decoder_tb();
	logic [3:0]	row;
	logic [3:0]	col;
	logic [3:0]	key;

	key_decoder dut(row, col, key);

	// expected digit for a row/column pair, from the printed legend
	function automatic logic [3:0] legend(input int r, c);
		case ({r[1:0], c[1:0]})
			4'b0000: legend = 4'h1; 4'b0001: legend = 4'h2; 4'b0010: legend = 4'h3; 4'b0011: legend = 4'hA;
			4'b0100: legend = 4'h4; 4'b0101: legend = 4'h5; 4'b0110: legend = 4'h6; 4'b0111: legend = 4'hB;
			4'b1000: legend = 4'h7; 4'b1001: legend = 4'h8; 4'b1010: legend = 4'h9; 4'b1011: legend = 4'hC;
			4'b1100: legend = 4'hE; 4'b1101: legend = 4'h0; 4'b1110: legend = 4'hF; 4'b1111: legend = 4'hD;
		endcase
	endfunction

	// apply stimuli and check outputs
	initial begin
		#2

		// Tests 1-16: every key on the pad
		for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) begin
			row = 4'b1 << r;
			col = 4'b1 << c;
			#1;
			assert (key == legend(r, c))
				$display("PASSED! Row %0d col %0d decodes to %h at time: %0t.", r, c, key, $time);
			else
				$error("FAILED! Row %0d col %0d decodes to %h instead of %h at time: %0t.", r, c, key, legend(r, c), $time);
		end

		// Test 17: no row selected decodes to 0
		row = 4'b0000; col = 4'b0001; #1;
		assert (key == 4'h0)
			$display("PASSED! No row selected decodes to 0 at time: %0t.", $time);
		else
			$error("FAILED! No row selected decodes to %h instead of 0 at time: %0t.", key, $time);

		// Test 18: two columns decodes to 0
		row = 4'b0001; col = 4'b0011; #1;
		assert (key == 4'h0)
			$display("PASSED! Two columns decode to 0 at time: %0t.", $time);
		else
			$error("FAILED! Two columns decode to %h instead of 0 at time: %0t.", key, $time);

		// Test 19: two rows decodes to 0
		row = 4'b0110; col = 4'b0100; #1;
		assert (key == 4'h0)
			$display("PASSED! Two rows decode to 0 at time: %0t.", $time);
		else
			$error("FAILED! Two rows decode to %h instead of 0 at time: %0t.", key, $time);

		// Test 20: nothing at all decodes to 0
		row = 4'b0000; col = 4'b0000; #1;
		assert (key == 4'h0)
			$display("PASSED! No key decodes to 0 at time: %0t.", $time);
		else
			$error("FAILED! No key decodes to %h instead of 0 at time: %0t.", key, $time);

		#100 $stop;
	end

endmodule
