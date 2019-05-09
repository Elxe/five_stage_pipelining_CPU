// Project: Two-channel multiplexer
// Author: Zhang Ningxin

module mux_2 (data_0, data_1, condition, data_out);
	parameter WIDTH = 32;

	input  [WIDTH-1:0] data_0;
	input  [WIDTH-1:0] data_1;
	input              condition;
	output [WIDTH-1:0] data_out;

	assign data_out = ({WIDTH{condition==1'd0}} & data_0)
					| ({WIDTH{condition==1'd1}} & data_1);
endmodule