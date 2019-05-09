// Project: control unit
// Author: Zhang Ningxin

`include "define.h"

module control(
	input  [31:0] de_inst,

	output        op_movz,
	output        op_movn,
	output [19:0] exe_ctrl,  //to module exe
	output [10:0] mem_ctrl,  //to module mem
	output [11:0] wb_ctrl,   //to module wb
	output [12:0] type_j,
	output [ 1:0] special,
	output [ 2:0] exc,
	output  	  sig_ext,
	output        con_sign
);
	wire [ 5:0] opcode;
    wire [ 4:0] rs;
    wire [ 4:0] rt;
    wire [ 4:0] rd;
    wire [ 4:0] sa; 
    wire [15:0] imm;
    wire [ 5:0] funct;

	assign opcode  = de_inst[31:26];
    assign rs      = de_inst[25:21];
    assign rt      = de_inst[20:16];
    assign rd      = de_inst[15:11];
    assign sa      = de_inst[10: 6];
    assign funct   = de_inst[ 5: 0];
    assign imm     = de_inst[15: 0];

	wire op_nop;
	assign op_nop = (de_inst == 0);

	//decoding
	wire op_rtype;
	wire op_addi;
	wire op_addiu;
	wire op_slti;
	wire op_sltiu;
	wire op_andi;
	wire op_lui;
	wire op_ori;
	wire op_xori;
	wire op_beq;
	wire op_bne;
	wire op_bgez;
	wire op_bgtz;
	wire op_blez;
	wire op_bz;
	wire op_j;
	wire op_jal;
	wire op_lb;
	wire op_lbu;
	wire op_lh;
	wire op_lhu;
	wire op_lw;
	wire op_lwl;
	wire op_lwr;
	wire op_sb;
	wire op_sh;
	wire op_sw;
	wire op_swl;
	wire op_swr;

	assign op_rtype	= (opcode == `RTYPE);
	assign op_addi	= (opcode == `ADDI);
	assign op_addiu	= (opcode == `ADDIU);
	assign op_slti	= (opcode == `SLTI);
	assign op_sltiu	= (opcode == `SLTIU);
	assign op_andi	= (opcode == `ANDI);
	assign op_lui	= (opcode == `LUI);
	assign op_ori	= (opcode == `ORI);
	assign op_xori	= (opcode == `XORI);
	assign op_beq	= (opcode == `BEQ);
	assign op_bne	= (opcode == `BNE);

	assign op_bgtz	= (opcode == `BGTZ) & (rt == 5'd0);
	assign op_blez	= (opcode == `BLEZ) & (rt == 5'd0);
	assign op_bz    = (opcode == `BZ);
	assign op_j	    = (opcode == `J);
	assign op_jal	= (opcode == `JAL);
	assign op_lb	= (opcode == `LB);
	assign op_lbu	= (opcode == `LBU);
	assign op_lh	= (opcode == `LH);
	assign op_lhu	= (opcode == `LHU);
	assign op_lw	= (opcode == `LW);
	assign op_lwl	= (opcode == `LWL);
	assign op_lwr	= (opcode == `LWR);
	assign op_sb	= (opcode == `SB);
	assign op_sh	= (opcode == `SH);
	assign op_sw	= (opcode == `SW);
	assign op_swl	= (opcode == `SWL);
	assign op_swr	= (opcode == `SWR);


	//function
	wire op_add;
	wire op_sub;
	wire op_addu;
	wire op_subu;
	wire op_sllv;
	wire op_sll;
	wire op_srav;
	wire op_sra;
	wire op_srlv;
	wire op_srl;
	wire op_jr;
	wire op_jalr;
	wire op_bltz;
	wire op_bgezal;
	wire op_bltzal;

	wire op_div;
	wire op_divu;
	wire op_mult;
	wire op_multu;
	wire op_mfhi;
	wire op_mflo;
	wire op_mthi;
	wire op_mtlo;

	wire op_eret;
	wire op_mfc0;
	wire op_mtc0;
	wire op_break;
	wire op_syscall;

	wire type_i;
	wire type_link;
	wire type_store;
	wire type_load;

	assign op_movz      = op_rtype & (funct == `MOVZ) & (sa == 5'd0);
	assign op_movn      = op_rtype & (funct == `MOVN) & (sa == 5'd0);

	assign op_add       = op_rtype & (funct == `ADD) & (sa == 5'd0);
	assign op_sub       = op_rtype & (funct == `SUB) & (sa == 5'd0);
	assign op_addu      = op_rtype & (funct == `ADDU) & (sa == 5'd0);
	assign op_subu      = op_rtype & (funct == `SUBU) & (sa == 5'd0);
	assign op_sllv	    = op_rtype & (funct == `SLLV) & (sa == 5'd0);
	assign op_sll	    = op_rtype & (funct == `SLL) & (rs == 5'd0);
	assign op_srav	    = op_rtype & (funct == `SRAV) & (sa == 5'd0);
	assign op_sra	    = op_rtype & (funct == `SRA) & (rs == 5'd0);
	assign op_srlv	    = op_rtype & (funct == `SRLV) & (sa == 5'd0);
	assign op_srl	    = op_rtype & (funct == `SRL) & (rs == 5'd0);
	assign op_jr		= op_rtype & (funct == `JR) & ({rt, rd, sa} == 15'd0);
	assign op_jalr		= op_rtype & (funct == `JALR) & (rt == 5'd0) & (sa == 5'd0);

	assign op_bgez		= op_bz   & (rt == `BGEZ);
	assign op_bltz		= op_bz   & (rt == `BLTZ);
	assign op_bgezal	= op_bz   & (rt == `BGEZAL);
	assign op_bltzal	= op_bz   & (rt == `BLTZAL);

	assign op_div       = op_rtype & (funct == `DIV) & ({rd, sa} == 10'd0);
	assign op_divu      = op_rtype & (funct == `DIVU) & ({rd, sa} == 10'd0);
	assign op_mult      = op_rtype & (funct == `MULT) & ({rd, sa} == 10'd0);
	assign op_multu     = op_rtype & (funct == `MULTU) & ({rd, sa} == 10'd0);
	assign op_mfhi      = op_rtype & ({rs, rt} == 10'd0) & (sa == 5'd0) & (funct == `MFHI);
	assign op_mflo      = op_rtype & ({rs, rt} == 10'd0) & (sa == 5'd0) & (funct == `MFLO);
	assign op_mthi      = op_rtype & ({rt, rd, sa} == 15'd0) & (funct == `MTHI);
	assign op_mtlo      = op_rtype & ({rt, rd, sa} == 15'd0) & (funct == `MTLO);

	assign op_eret      = (opcode == `SPEC) & (rs[4]) & ({rs[3:0], rt, rd, sa} == 19'd0) & (funct == `ERET);
	assign op_mfc0      = (opcode == `SPEC) & (rs == `MFC0) & ({sa, funct[5:3]} == 8'd0);
	assign op_mtc0      = (opcode == `SPEC) & (rs == `MTC0) & ({sa, funct[5:3]} == 8'd0);
	assign op_break     = op_rtype & (funct == `BREAK);
	assign op_syscall   = op_rtype & (funct == `SYSCALL);

	assign type_i		= op_addi | op_addiu | op_slti | op_sltiu | op_andi | op_lui | op_ori | op_xori | op_sllv | op_sll | op_srav | op_srlv | op_srl;
	assign type_link	= op_bgezal | op_bltzal | op_jal;
	assign type_store	= op_sb | op_sh | op_sw | op_swl | op_swr;
	assign type_load	= op_lb | op_lbu | op_lh | op_lhu | op_lw | op_lwl | op_lwr;

	wire res_exc;

	assign res_exc = !(type_i | (|type_j) | type_store | type_load | (|special) | op_rtype | (|div_mul) | op_break | op_syscall);
	assign exc = {res_exc, op_break, op_syscall};


	//************************************************************
	//  sig_ext   = 0  -> 16{1'b0},   1  -> 16{imm[15]}; 
	//  ALUSrcA   = 0  -> read_reg1,  1  -> PC;
	//  ALUSrcB   = 00 -> read_reg2,  01 -> ext_imm;
	//            = 10 -> 32'd8,      11 -> 32'd0   
	//  reg_dst   = 00 -> rt,         01 -> rd;
	//            = 10 -> 5'd31,      11 -> 5'd0 
 	//************************************************************

 	wire        ALUSrcA;
	wire [ 1:0]	ALUSrcB;
	wire [ 1:0]	reg_dst;
	wire [ 7:0]	ALUop;
	wire [ 7:0] div_mul;
	wire [ 4:0] mem_read;
	wire [ 4:0] mem_write;
	wire        mem_to_reg, reg_write, mem_unsigned, unsign;


	assign sig_ext      = ~(op_andi | op_ori | op_xori);
	assign ALUSrcA      = type_link | op_jalr;
	assign ALUSrcB[0]   = (type_i & ~(op_sll | op_sllv | op_srav | op_sra | op_srl | op_srlv)) | (|mem_read) | (|mem_write) | op_movn | op_movz | op_mfc0;
	assign ALUSrcB[1]   = type_link | op_jalr | op_movn | op_movz | op_mfc0;
	assign reg_dst[0]   = op_rtype | op_jalr;
	assign reg_dst[1]   = type_link;

	assign ALUop[0]     = op_andi | op_eret | op_j | op_beq | op_bne | op_bgez | op_bgtz | op_blez | op_bltz;
	assign ALUop[1]     = op_ori;
	assign ALUop[2]     = op_xori;
	assign ALUop[3]     = op_addi | op_addiu | type_link | type_store | type_load | op_addu | op_mfhi | op_mflo | op_mthi | op_mtlo | op_movn | op_movz | op_jalr | op_mfc0;
	assign ALUop[4]     = op_beq | op_bne;
	assign ALUop[5]     = op_slti;
	assign ALUop[6]     = op_lui;
	assign ALUop[7]     = op_sltiu;


	assign mem_read  = {op_lw, op_lwl, op_lwr, (op_lhu | op_lh), (op_lb | op_lbu)};
	assign mem_write = {op_sw, op_swl, op_swr, op_sh, op_sb};
	assign mem_unsigned  = op_lbu | op_lhu;

	assign div_mul   = {op_div, op_divu, op_mult, op_multu, op_mfhi, op_mflo, op_mthi, op_mtlo};

	assign exe_ctrl  = {sign, div_mul[7:0], ALUop[7:0], ALUSrcA, ALUSrcB[1:0]};
	assign mem_ctrl  = {mem_unsigned, mem_read, mem_write};
	assign wb_ctrl   = {op_div | op_divu | op_mult | op_multu, div_mul[3:0], special[1:0], type_link, reg_dst[1:0], mem_to_reg, reg_write};
	
	assign mem_to_reg    = type_load;
	assign reg_write     = (op_rtype & ~op_jr) | type_i | type_link | type_load | op_mfc0;

	assign type_j   = {op_eret, op_j, op_jal, op_jr, op_jalr, op_beq, op_bne, op_bgez, op_bgezal, op_bgtz, op_blez, op_bltz, op_bltzal};
	assign con_sign = op_bgezal | op_bltzal;

	assign special  = {op_mfc0, op_mtc0}; 

	assign sign     = op_add | op_sub | op_addi;

endmodule