// Project: ID unit
// Author: Zhang Ningxin

`include "define.h"

module ID (
	input         clk,
	input         resetn,
    input         id_stage,
    input         int_exc,

    input         stop,
    input         if_to_id_valid,
    input         ex_allowin,

    input         if_exc,
    input  [ 5:0] if_excode,

    input  [31:0] id_pc_i,
	input  [31:0] id_pc_add4_i,
	input  [31:0] id_inst_i,

	input         wb_wen,
	input  [ 4:0] wb_waddr,
	input  [31:0] wb_wdata,

    input  [ 2:0] forwardA,
    input  [ 2:0] forwardB,
    input  [31:0] ex_wdata,
    input  [31:0] me_wdata,
    input  [31:0] load_data,

    input  [31:0] epc_value,

    output        id_allowin,
    output        id_to_ex_valid,
    output        id_ex_stage_o,

    output [11:0] wb_ctrl,
	
    output        j_token,
    output [31:0] id_pc_o,
    output [31:0] id_inst_o,
    output [31:0] id_next_pc_o,
	output [19:0] id_exe_ctrl_o,  //to module exe
	output [10:0] id_mem_ctrl_o,  //to module mem
	output [11:0] id_wb_ctrl_o,   //to module wb
	output [31:0] id_ext_imm_o,
	output [31:0] id_rdata1_o,
	output [31:0] id_rdata2_o,
    output [ 4:0] id_waddr_o,

    output        id_rs_bd_o,
    output [ 1:0] id_exc_o,
    output [11:0] id_excode_o,

    output        op_eret,

    output [ 4:0] for_SrcA,
    output [ 4:0] for_SrcB
);

    wire [31:0] de_inst;

    assign de_inst = (id_stage & !int_exc) ? id_inst_i : 32'd0;

	wire [ 5:0] opcode;
    wire [ 4:0] rs;
    wire [ 4:0] rt;
    wire [ 4:0] rd;
    wire [ 4:0] sa; 
    wire [15:0] imm;
    wire [ 5:0] funct;
    wire [ 2:0] sel;

    wire        sig_ext;
    wire        op_movz;
    wire        op_movn;
    wire        con_sign;
    wire [11:0] cu_wb_ctrl_o;
    
    wire [12:0] type_j;
    wire [ 1:0] special;
    wire [ 2:0] exc;

    assign opcode  = de_inst[31:26];
    assign rs      = de_inst[25:21];
    assign rt      = de_inst[20:16];
    assign rd      = de_inst[15:11];
    assign sa      = de_inst[10: 6];
    assign imm     = de_inst[15: 0];
    assign funct   = de_inst[ 5: 0];
    assign sel     = de_inst[ 2: 0];

    wire [19:0] exe_ctrl;
	wire [10:0] mem_ctrl;
	wire [31:0] ext_imm;

    control cu (
        .de_inst  (de_inst      ),

        .op_movz  (op_movz      ),
        .op_movn  (op_movn      ),
        .exe_ctrl (exe_ctrl     ),
        .mem_ctrl (mem_ctrl     ),
        .wb_ctrl  (cu_wb_ctrl_o ),
        .type_j   (type_j       ),
        .special  (special      ),
        .exc      (exc          ),
        .sig_ext  (sig_ext      ),
        .con_sign (con_sign     )
    );

    wire op_res;
    wire op_syscall;
    wire op_break;
    wire op_mfc0;
    wire op_mtc0;
 
    assign op_res     = exc[2];
    assign op_syscall = exc[0];
    assign op_break   = exc[1];
    assign op_mfc0    = special[1];
    assign op_mtc0    = special[0];

    assign ext_imm = sig_ext ? {{16{imm[15]}}, imm[15:0]} : {{16{1'b0}}, imm[15:0]};

    wire [31:0] rdata1;
    wire [31:0] rdata2;

    reg_file rf_i(
    	.clk    (clk      ),
		.resetn (resetn   ),
		.waddr  (wb_waddr ),
		.raddr1 (rs       ),
		.raddr2 (rt       ),
		.wen    (wb_wen   ),
		.wdata  (wb_wdata ),

		.rdata1 (rdata1   ),
		.rdata2 (rdata2   )
    );

    wire [3:0] rdata1_mux;
    wire [3:0] rdata2_mux;

    assign rdata1_mux[3] = (forwardA==3'd1);
    assign rdata1_mux[2] = (forwardA==3'd2);
    assign rdata1_mux[1] = (forwardA==3'd4 || forwardA==3'd5 || forwardA==3'd6);
    assign rdata1_mux[0] = (forwardA==3'd3);

    assign rdata2_mux[3] = (forwardB==3'd1);
    assign rdata2_mux[2] = (forwardB==3'd2);
    assign rdata2_mux[1] = (forwardB==3'd4 || forwardB==3'd5 || forwardB==3'd6);
    assign rdata2_mux[0] = (forwardB==3'd3);
    
    wire [31:0] reg_rdata1;
    wire [31:0] reg_rdata2;

    assign reg_rdata1 = rdata1_mux[3] ? ex_wdata  :
                        rdata1_mux[2] ? me_wdata  :
                        rdata1_mux[1] ? load_data :
                        rdata1_mux[0] ? wb_wdata  : rdata1;

    assign reg_rdata2 = rdata2_mux[3] ? ex_wdata  :
                        rdata2_mux[2] ? me_wdata  :
                        rdata2_mux[1] ? load_data :
                        rdata2_mux[0] ? wb_wdata  : rdata2;

    wire mov;

    assign mov = ((reg_rdata2==32'd0) & op_movz) | ((reg_rdata2!=32'd0) & op_movn);

    assign wb_ctrl = {cu_wb_ctrl_o[11:1], cu_wb_ctrl_o[0] | mov};

    wire [4:0] id_waddr;
    mux_4 #(5) mux_waddr (
        .data_0     (rt             ),
        .data_1     (rd             ),
        .data_2     (5'd31          ),
        .data_3     (5'd0           ),
        .condition  (wb_ctrl[3:2]   ),
        .data_out   (id_waddr       )
    );

    // forward part

	assign for_SrcA = de_inst[25:21] & {5{!exe_ctrl[2] | con_sign | type_j[8]}};
	assign for_SrcB = de_inst[20:16] & {5{~(|exe_ctrl[14:11])}};

    // jump or branch

	wire [31:0] b_pc;
	wire [31:0] j_pc;
	wire [31:0] jr_pc;
	wire [31:0] ext_imm_sll_2;
	wire        j_hit;
	wire        jr_hit;
	wire        b_hit;
	wire        none_hit;
    wire        eret_hit;

	assign j_token = jr_hit | j_hit | b_hit | eret_hit;

	assign ext_imm_sll_2 = ext_imm << 2'd2;


	cla_32 branch (
		.A      (id_pc_add4_i    ), 
		.B      (ext_imm_sll_2 ), 
		.cin    (1'b0          ), 
		.result (b_pc          ), 
		.cout   (              )
	);

    assign op_eret = type_j[12];

	//assign type_j = {op_eret, op_j, op_jal, op_jr, op_jalr, op_beq, op_bne, op_bgez, op_bgezal, op_bgtz, op_blez, op_bltz, op_bltzal};

	assign j_pc  = {id_pc_i[31:28], de_inst[25:0], 2'b00};
	assign jr_pc = reg_rdata1;

    assign eret_hit = op_eret;
	assign j_hit  = type_j[11] | type_j[10];
	assign jr_hit = type_j[9] | type_j[8];

	wire beq_hit;
	wire bne_hit;
	wire bgez_hit;
	wire bgtz_hit;
	wire blez_hit;
	wire bltz_hit;

	assign beq_hit  = type_j[7] & (reg_rdata1 == reg_rdata2);
	assign bne_hit  = type_j[6] & (reg_rdata1 != reg_rdata2);
	assign bgez_hit = (type_j[5] | type_j[4]) & !reg_rdata1[31];
	assign bgtz_hit = type_j[3] & !reg_rdata1[31] & (|reg_rdata1);
	assign blez_hit = type_j[2] & (reg_rdata1[31] | ~(|reg_rdata1));
	assign bltz_hit = (type_j[1] | type_j[0]) & reg_rdata1[31];

	assign b_hit    = beq_hit | bne_hit | bgez_hit | bgtz_hit | blez_hit | bltz_hit; 
	assign none_hit = ~(j_hit | jr_hit | b_hit | eret_hit | int_exc);
	
	wire [31:0] id_next_pc;

	assign id_next_pc = id_stage ?
	                  ( ({32{none_hit}} & id_pc_add4_i )
					  | ({32{j_hit}}    & j_pc         )
					  | ({32{jr_hit}}   & jr_pc        )
					  | ({32{b_hit}}    & b_pc         )
                      | ({32{eret_hit}} & epc_value    ) ) : id_pc_i;

    // interupt part

    wire       id_exc;
    wire [5:0] id_excode;

    assign id_exc = (op_syscall | op_break | op_res) & id_stage;
    assign id_excode = op_res     ? `LS132R_EX_RI  :
                       op_break   ? `LS132R_EX_BP  :
                       op_syscall ? `LS132R_EX_SYS : 6'd0;
    
    //pipe

    reg  [31:0] id_pc_reg;
    reg  [31:0] id_inst_reg;
    reg  [19:0] id_exe_ctrl_reg;
    reg  [10:0] id_mem_ctrl_reg;
    reg  [11:0] id_wb_ctrl_reg;
    reg  [31:0] id_ext_imm_reg;
    reg  [31:0] id_rdata1_reg;
    reg  [31:0] id_rdata2_reg;
    reg  [ 4:0] id_waddr_reg; 
    reg         rs_bd;
    reg         id_rs_bd_reg;
    reg  [ 1:0] id_exc_reg;
    reg  [11:0] id_excode_reg;

    reg  id_valid;
    wire id_ready_go;

    assign id_ready_go    = resetn & !stop;
    assign id_allowin     = !id_valid | id_ready_go & ex_allowin;
    assign id_to_ex_valid = id_valid & id_ready_go;

    always @(posedge clk)
    begin
        if (!resetn || int_exc) 
            id_valid     <= 1'b0;
        else if (id_allowin)
            id_valid     <= if_to_id_valid;

        if (!resetn || int_exc)
        begin
            id_pc_reg       <= 32'hbfc00000;
            id_inst_reg     <= 32'd0;

            id_exe_ctrl_reg <= 20'd0;
            id_mem_ctrl_reg <= 11'd0;
            id_wb_ctrl_reg  <= 12'd0;
            id_ext_imm_reg  <= 32'd0;
            id_rdata1_reg   <= 32'd0;
            id_rdata2_reg   <= 32'd0;
            id_waddr_reg    <=  5'd0;
            rs_bd           <=  1'b0;
            id_rs_bd_reg    <=  1'b0;
            id_exc_reg      <=  2'd0;
            id_excode_reg   <= 12'd0;
        end
        else if (if_to_id_valid & id_allowin) 
        begin
            id_pc_reg       <= id_pc_i;
            id_inst_reg     <= id_inst_i;

            id_exe_ctrl_reg <= exe_ctrl;
            id_mem_ctrl_reg <= mem_ctrl;
            id_wb_ctrl_reg  <= wb_ctrl;
            id_ext_imm_reg  <= ext_imm;
            id_rdata1_reg   <= reg_rdata1;
            id_rdata2_reg   <= reg_rdata2; 
            id_waddr_reg    <= id_waddr;
            rs_bd           <= |type_j[11:0];
            id_rs_bd_reg    <= rs_bd;
            id_exc_reg      <= {id_exc, if_exc};
            id_excode_reg   <= {id_excode, if_excode};
        end
    end

    assign id_pc_o       = id_pc_reg;
    assign id_inst_o     = id_inst_reg;
    assign id_next_pc_o  = id_next_pc;
	assign id_exe_ctrl_o = id_exe_ctrl_reg;
	assign id_mem_ctrl_o = id_mem_ctrl_reg;
	assign id_wb_ctrl_o  = id_wb_ctrl_reg & {12{id_valid}};
	assign id_ext_imm_o  = id_ext_imm_reg;
	assign id_rdata1_o   = id_rdata1_reg;
	assign id_rdata2_o   = id_rdata2_reg;
    assign id_waddr_o    = id_waddr_reg;
    assign id_rs_bd_o    = id_rs_bd_reg;
    assign id_exc_o      = id_exc_reg;
    assign id_excode_o   = id_excode_reg; 
    assign id_ex_stage_o = id_valid;

endmodule


