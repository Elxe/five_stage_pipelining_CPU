// Project: carry-lookahead adder
// Author: Zhang Ningxin

module cla_32(
	input  [31:0] A,
	input  [31:0] B,
	input        cin,
	output [31:0] result,
	output       cout
	);
	wire [31:0] C;  //Carry signals
	wire [31:0] g;  //Carry generating factors
	wire [31:0] p;  //Carry passing factors
	wire [7:0]  D;
	wire [7:0]  T;
	wire [1:0]  temp_d;
	wire [1:0]  temp_t;

	assign g = A & B;
	assign p = A ^ B;

	cla_4 carry_2_0   (.g(g[ 3: 0]),.p(p[ 3: 0]),.cin(cin  ),.carry_out(C[ 2: 0]),.D(D[0]),.T(T[0]));
	cla_4 carry_6_4   (.g(g[ 7: 4]),.p(p[ 7: 4]),.cin(C[ 3]),.carry_out(C[ 6: 4]),.D(D[1]),.T(T[1]));
	cla_4 carry_10_8  (.g(g[11: 8]),.p(p[11: 8]),.cin(C[ 7]),.carry_out(C[10: 8]),.D(D[2]),.T(T[2]));
	cla_4 carry_14_12 (.g(g[15:12]),.p(p[15:12]),.cin(C[11]),.carry_out(C[14:12]),.D(D[3]),.T(T[3]));
	cla_4 carry_18_16 (.g(g[19:16]),.p(p[19:16]),.cin(C[15]),.carry_out(C[18:16]),.D(D[4]),.T(T[4]));
	cla_4 carry_22_20 (.g(g[23:20]),.p(p[23:20]),.cin(C[19]),.carry_out(C[22:20]),.D(D[5]),.T(T[5]));
	cla_4 carry_26_24 (.g(g[27:24]),.p(p[27:24]),.cin(C[23]),.carry_out(C[26:24]),.D(D[6]),.T(T[6]));
	cla_4 carry_30_28 (.g(g[31:28]),.p(p[31:28]),.cin(C[27]),.carry_out(C[30:28]),.D(D[7]),.T(T[7]));

	cla_4 carry_15_11_7_3 (.g(D[3:0]),.p(T[3:0]),.cin(cin),.carry_out({C[11],C[7],C[3]}),.D(temp_d[0]),.T(temp_t[0]));
	cla_4 carry_31_27_23_19 (.g(D[7:4]),.p(T[7:4]),.cin(C[15]),.carry_out({C[27],C[23],C[19]}),.D(temp_d[1]),.T(temp_t[1]));

	assign C[15] = temp_d[0] | temp_t[0]&cin;
	assign C[31] = temp_d[1] | temp_t[1]&C[15];
	assign cout = C[31];

	assign result[0] = p[0] ^ cin;
	generate
		genvar i;
		for(i = 1; i < 32; i = i + 1)
		begin
			assign result[i] = p[i] ^ C[i-1];
		end
	endgenerate

endmodule

module cla_4(
	input  [3:0] g,
	input  [3:0] p,
	input        cin,
	output [2:0] carry_out,
	output       D,
	output       T
	);
	assign carry_out[0] = g[0] | p[0]&cin;
	assign carry_out[1] = g[1] | p[1]&g[0] | p[1]&p[0]&cin;
	assign carry_out[2] = g[2] | p[2]&g[1] | p[2]&p[1]&g[0] | p[2]&p[1]&p[0]&cin;
	assign D            = g[3] | p[3]&g[2] | p[3]&p[2]&g[1] | p[3]&p[2]&p[1]&g[0];
	assign T = p[3]&p[2]&p[1]&p[0];
endmodule