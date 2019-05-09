// Project: ALU
// Author: Zhang Ningxin

module alu(
	input  [31:0] A,
	input  [31:0] B,
	input  [4:0]  shamt,
	input  [14:0] ALUop,
	output        CarryOut,
	output        Overflow,
	output        Zero,
	output [31:0] Result
);
	wire op_and;
	wire op_or;
	wire op_xor;
	wire op_nor;
	wire op_add;
	wire op_sub;
	wire op_slt;
	wire op_sll;
	wire op_srl;
	wire op_sllv;
	wire op_srlv;
	wire op_stlu;
	wire op_lui;
	wire op_sra;
	wire op_srav;

	assign op_and  = ALUop[0];
	assign op_or   = ALUop[1];
	assign op_xor  = ALUop[2];
	assign op_nor  = ALUop[3];
	assign op_add  = ALUop[4];
	assign op_sub  = ALUop[5];
	assign op_slt  = ALUop[6];
	assign op_sll  = ALUop[7];
	assign op_srl  = ALUop[8];
	assign op_sllv = ALUop[9];
	assign op_srlv = ALUop[10];
	assign op_stlu = ALUop[11];
	assign op_lui  = ALUop[12];
	assign op_sra  = ALUop[13];
	assign op_srav = ALUop[14];

	wire [31:0] and_result;
	wire [31:0] or_result;
	wire [31:0] xor_result;
	wire [31:0] nor_result;
	wire [31:0] add_result;
	wire [31:0] sub_result;
	wire [31:0] slt_result;
	wire [31:0] sll_result;
	wire [31:0] srl_result;
	wire [31:0] sllv_result;
	wire [31:0] srlv_result;
	wire [31:0] stlu_result;
	wire [31:0] lui_result;
	wire [31:0] sra_result;
	wire [31:0] srav_result;

	wire oflow_add;                     //signal for Overflow of adder
	wire oflow_sub;                     //signal for Overflow of suber
	wire carryout_add;                  //signal for carryout_add
	wire carryout_sub;                  //signal for carryout_sub
	wire slt;                           //signal for slt

	assign Zero = (32'd0 == Result);

	assign oflow_add = ((A[31]&B[31]) & (!add_result[31])) 
					|((!A[31]&!B[31]) & (add_result[31]));
	assign oflow_sub = ((!A[31])&B[31] & sub_result[31]) 
					|(A[31] & (!B[31]) & (!sub_result[31]));

	assign Overflow = op_add ? oflow_add : 
	                  op_sub ? oflow_sub : 1'b0;
	assign CarryOut = op_add ? carryout_add : 
                      op_sub ? carryout_sub : 1'b0;

	assign slt = sub_result[31];

	assign and_result  = A & B;			                   	             
	assign or_result   = A | B;				                               
	assign xor_result  = A ^ B;				                                
	assign nor_result  = ~(A | B);			                                
	assign {carryout_add, add_result} = A + B;
	assign {carryout_sub, sub_result} = A + (~B) + {{31{1'b0}},1'b1};
	assign slt_result  = {{31{1'b0}}, slt^oflow_sub};
	assign sll_result  = B << shamt;                                        
	assign srl_result  = B >> shamt;                                        
	assign sllv_result = B << A[4:0];
	assign srlv_result = B >> A[4:0];
	assign stlu_result = {{31{1'b0}}, carryout_sub}; 
	assign lui_result  = B << 16;
	assign sra_result  = ({32{B[31]}} << (32 - shamt)) | (B >> shamt);   
	assign srav_result = ({32{B[31]}} << (32 - A[4:0])) | (B >> A[4:0]);
	
	assign Result =  ({32{op_and}}  & and_result)
					|({32{op_or}}   & or_result)
					|({32{op_xor}}  & xor_result)
					|({32{op_nor}}  & nor_result)
					|({32{op_add}}  & add_result)
					|({32{op_sub}}  & sub_result)
					|({32{op_slt}}  & slt_result)
					|({32{op_sll}}  & sll_result)
					|({32{op_srl}}  & srl_result)
					|({32{op_sllv}} & sllv_result)
					|({32{op_srlv}} & srlv_result)
					|({32{op_stlu}} & stlu_result)
					|({32{op_lui}}  & lui_result)
					|({32{op_sra}}  & sra_result)
					|({32{op_srav}} & srav_result);

endmodule