// Project: ALU control
// Author: Zhang Ningxin
`include "define.h"

module ALU_control(
	input  [7:0]  ALUop,
	input  [5:0]  funct,
	output [14:0] ALUctl
	);
	
	wire zero;

	assign zero = ~|ALUop;

	assign ALUctl[0]  = (zero & (funct==`AND)) | ALUop[0];                 //and
	assign ALUctl[1]  = (zero & (funct==`OR)) | ALUop[1];                  //or
	assign ALUctl[2]  = (zero & (funct==`XOR)) | ALUop[2];                 //xor
	assign ALUctl[3]  = zero & (funct==`NOR);                              //nor
	assign ALUctl[4]  = (zero & (funct==`ADD|funct==`ADDU)) | ALUop[3];    //add
	assign ALUctl[5]  = (zero & (funct==`SUB|funct==`SUBU)) | ALUop[4];    //sub
	assign ALUctl[6]  = (zero & (funct==`SLT)) | ALUop[5];                 //slt
	assign ALUctl[7]  = zero & (funct==`SLL);                              //sll
	assign ALUctl[8]  = zero & (funct==`SRL);                              //srl
	assign ALUctl[9]  = zero & (funct==`SLLV);                             //sllv
	assign ALUctl[10] = zero & (funct==`SRLV);                             //srlv
	assign ALUctl[11] = (zero & (funct==`SLTU)) | ALUop[7];                //sltu
	assign ALUctl[12] = ALUop[6];                                          //lui
	assign ALUctl[13] = zero & (funct==`SRA);                              //sra
	assign ALUctl[14] = zero & (funct==`SRAV);                             //srav

	

endmodule