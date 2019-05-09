// Project: multi unit
// Author: Zhang Ningxin
`timescale 1ns / 1ps

module multi(
	input         mul_clk,
	input         resetn,
	input         mul,
	input         mul_signed,
	input  [31:0] x,
	input  [31:0] y,
 
	output [63:0] result,
	output reg    complete
);
	/*
	reg pipe_en;

	always @(posedge mul_clk) 
	begin
		if (!resetn) 
		begin
			complete <= 1'b0;
			pipe_en  <= 1'b0;
		end
		else if (mul & !pipe_en) 
		begin
			pipe_en  <= 1'b1;
			complete <= 1'b0;
		end
		else if (mul & pipe_en) 
		begin
			pipe_en  <= 1'b0;
			complete <= 1'b1;
		end
		else 
		begin
			complete <= 1'b0;
			pipe_en  <= 1'b0;
		end
	end
	*/
	always @(posedge mul_clk) 
	begin
		if(!resetn) complete <= 1'b0;
		else if (mul) complete <=1'b1;
		else complete <= 1'b0;
	end
	wire [63:0] level_1 [16:0];
	wire [63:0] level_2 [ 9:0];
	wire [63:0] level_3 [ 7:0];
	wire [63:0] level_4 [ 3:0];
	wire [63:0] level_5 [ 3:0];
	wire [63:0] level_6 [ 1:0];
	wire [63:0] level_7 [ 1:0];
	wire [63:0] level_8;

	wire [33:0] A, B;
	wire [34:0] multiplier;
	wire        cout;

	assign A = {{2{mul_signed & x[31]}}, x};
	assign B = {{2{mul_signed & y[31]}}, y};
	assign multiplier = {B, 1'b0};

	wire [34:0] X_co, X_nco, X_dou, X_ndou;

	assign X_co   = {A[33] ,A};
	assign X_nco  = ~X_co + 1'd1;
	assign X_dou  = X_co << 1;
	assign X_ndou = ~X_dou + 1'd1;

	integer j;
	
	reg [63:0] pipe_1 [7:0];

	always @(posedge mul_clk) 
	begin
		if (!resetn) 
			for (j = 0; j < 8; j = j + 1) pipe_1[j] <= 64'd0;
		else if (mul) 
			for (j = 0; j < 8; j = j + 1) pipe_1[j] <= level_3[j];
		else 
			for (j = 0; j < 8; j = j + 1) pipe_1[j] <= 64'd0;
	end

	generate
		genvar i;
		for (i = 0; i < 17; i = i + 1)
		begin: level_0
			mux_8 #(64) partial_0 (
				.data_0    (64'd0         								            ),
				.data_1    ({{29{X_co[34]}}, X_co} << i * 2     		  			),
				.data_2    ({{29{X_co[34]}}, X_co} << i * 2   			  			),
				.data_3    ({{29{X_dou[34]}}, X_dou} << i * 2	          			),
				.data_4    ({{29{X_ndou[34]}}, X_ndou} << i * 2	          			),
				.data_5    ({{29{X_nco[34]}}, X_nco} << i * 2	          			),
				.data_6    ({{29{X_nco[34]}}, X_nco} << i * 2	          			),
				.data_7    (64'd0        								  			),
				.condition ({multiplier[i*2+2], multiplier[i*2+1], multiplier[i*2]} ),
				.data_out  (level_1[i]               					  			)
			);
		end
	endgenerate


	cra level_1_0 (.A(level_1[0]), .B(level_1[1]), .C(level_1[2]), .result(level_2[0]), .carry(level_2[1]));
	cra level_1_1 (.A(level_1[3]), .B(level_1[4]), .C(level_1[5]), .result(level_2[2]), .carry(level_2[3]));
	cra level_1_2 (.A(level_1[6]), .B(level_1[7]), .C(level_1[8]), .result(level_2[4]), .carry(level_2[5]));
	cra level_1_3 (.A(level_1[9]), .B(level_1[10]), .C(level_1[11]), .result(level_2[6]), .carry(level_2[7]));
	cra level_1_4 (.A(level_1[12]), .B(level_1[13]), .C(level_1[14]), .result(level_2[8]), .carry(level_2[9]));

	cra level_2_0 (.A(level_1[15]), .B(level_1[16]), .C(level_2[0]), .result(level_3[0]), .carry(level_3[1]));
	cra level_2_1 (.A(level_2[1]), .B(level_2[2]), .C(level_2[3]), .result(level_3[2]), .carry(level_3[3]));
	cra level_2_2 (.A(level_2[4]), .B(level_2[5]), .C(level_2[6]), .result(level_3[4]), .carry(level_3[5]));
	cra level_2_3 (.A(level_2[7]), .B(level_2[8]), .C(level_2[9]), .result(level_3[6]), .carry(level_3[7]));

	cra level_3_0 (.A(pipe_1[0]), .B(pipe_1[1]), .C(pipe_1[2]), .result(level_4[0]), .carry(level_4[1]));
	cra level_3_1 (.A(pipe_1[3]), .B(pipe_1[4]), .C(pipe_1[5]), .result(level_4[2]), .carry(level_4[3]));
   
	cra level_4_0 (.A(pipe_1[6]), .B(pipe_1[7]), .C(level_4[0]), .result(level_5[0]), .carry(level_5[1]));
	cra level_4_1 (.A(level_4[1]), .B(level_4[2]), .C(level_4[3]), .result(level_5[2]), .carry(level_5[3]));

	cra level_5_0 (.A(level_5[0]), .B(level_5[1]), .C(level_5[2]), .result(level_6[0]), .carry(level_6[1]));

	cra level_6_0 (.A(level_5[3]), .B(level_6[0]), .C(level_6[1]), .result(level_7[0]), .carry(level_7[1]));
	/*
	cla_32 level_7_0 (.A(pipe_2[0][31:0]), .B(pipe_2[1][31:0]), .cin(1'b0), .result(level_8[31:0]), .cout(cout));
	cla_32 level_7_1 (.A(pipe_2[0][63:32]), .B(pipe_2[1][63:32]), .cin(cout), .result(level_8[63:32]), .cout());
	*/
	assign result = level_7[0] + level_7[1];

endmodule


module cra(
	input  [63:0] A,
	input  [63:0] B,
	input  [63:0] C,

	output [63:0] result,
	output [63:0] carry
);

	assign result = A ^ B ^ C;
	assign carry[0] = 1'b0;

	generate
		genvar i;
		for (i = 1; i < 64; i = i + 1)
		begin: carry_o
			assign carry[i] = (A[i-1] & B[i-1]) | (A[i-1] & C[i-1]) | (B[i-1] & C[i-1]);
		end
	endgenerate

endmodule