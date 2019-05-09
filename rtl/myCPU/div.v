// Project: div unit
// Author: Zhang Ningxin
`timescale 1ns / 1ps

module div (
	input         div_clk,
	input         resetn,
	input         div,
	input         div_signed,
	input  [31:0] x,
	input  [31:0] y,
	output [31:0] s,
	output [31:0] r,
	output        complete
);

	reg  [65:0] A;
	reg  [65:0] shift_A;
	reg  [32:0] B;
	reg  [ 5:0] cnt; 
	wire [32:0] abs_a; // absolute value
	wire [32:0] abs_b;
	wire        a_sign;
	wire        b_sign;

	assign a_sign = x[31] & div_signed;
	assign b_sign = y[31] & div_signed;
	assign abs_a  = ({32{a_sign}} ^ x) + a_sign;
	assign abs_b  = ({32{b_sign}} ^ y) + b_sign;

	//reg  [32:0] quotient;

	wire [32:0] sub_result;
	wire        cin;
	wire        cout;

	assign cin = 1'b0;
	assign sub_result[32] = shift_A[65] ^ B[32] ^ cout;

	cla_32 sub(
		.A(shift_A[64:33]),
		.B(B[31:0]),
		.cin(cin),
		.result(sub_result[31:0]),
		.cout(cout)
	);

	wire [32:0] result;

	assign result = sub_result[32] ? shift_A[65:33] : sub_result;


	reg c_state, n_state;

	always @(posedge div_clk) 
	begin
		if (!resetn) 
			c_state <= 1'b0;
		else 
			c_state <= n_state;
	end

	always @(*) 
	begin
		if (!resetn) 
		  n_state <= 1'b0;
		else begin
			case(c_state)
				1'b0: 
				begin
					if (div) n_state <= 1'b1;
					else n_state <= 1'b0;
				end
				1'b1: 
				begin
					if (complete) n_state <= 1'b0;
					else n_state <= 1'b1;
				end
				default:
                    n_state <= 1'b0;
			endcase
		end
	end

	reg s_sign, r_sign;

	always @(posedge div_clk) begin
		if (!resetn) begin
			shift_A <= 64'd0;
			B <= 33'd0;
			cnt <= 6'd0;
			A <= 66'd0;
			s_sign <= 1'b0;
			r_sign <= 1'b0;
		end
		else begin
			if (c_state == 1'b0) begin
				shift_A <= {{32{1'b0}}, x};
				B <= ~abs_b + 1'b1;
				cnt <= 6'd1;
				A <= {33'd0, abs_a};
				s_sign <= div_signed & (x[31] ^ y[31]);
				r_sign <= div_signed & x[31];
			end

			else begin
				A <= {result[32:0], A[31:0], !sub_result[32]};
				// remainder 33bits, A 32bits, quotient 1bit << 1
				shift_A <= {result[31:0], A[31:0], !sub_result[32], 1'b0};
				B <= B;
				cnt <= cnt + 1;
				s_sign <= s_sign;
				r_sign <= r_sign;
			end
		end
	end

	wire [33:0] neg_r;

	assign neg_r = A[65] ? (A[65:33] + ~B) : A[65:33];

	assign s = {32{complete}} & (({32{s_sign}}^A[31:0]) + s_sign);
	assign r = {32{complete}} & (({32{r_sign}}^neg_r[31:0]) + r_sign);
	assign complete = (cnt == 6'd34);


endmodule