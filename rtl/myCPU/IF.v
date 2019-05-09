// Project: IF unit
// Author: Zhang Ningxin
`include "define.h"

module IF(
	input         clk,
	input         resetn,
	input         int_exc,

	input         stop,
	input         load_forward,
	input         j_token,
	input         op_eret,
	input         id_allowin,

	input  [31:0] irom_inst_i,
	input         inst_sram_ok,
	input  [31:0] id_next_pc_i,

	output        if_to_id_valid,
	output        if_id_stage_o,

	output        inst_ren,
	output [31:0] irom_pc_o,
	
	output [31:0] pc_add_4,

	output [31:0] if_pc_o,
	output [31:0] if_pc_add4_o,
	output [31:0] if_inst_o,

	output        if_exc_o,
	output [ 5:0] if_excode_o
);

	wire if_validin;
    assign if_validin = 1'b1;

	wire if_stage;
	assign if_stage = if_validin;

	reg  [31:0] pc;
	wire [31:0] next_pc;

	always @(posedge clk) begin
		if (!resetn)
			pc <= 32'hbfc0_0000;
		else if (int_exc)
			pc <= 32'hbfc00380;
		else if (pc_stall)
			pc <= pc;
		else if (if_stage)
			pc <= next_pc;
	end

	/*
	cla_32 pc_ad_4 (
		.A      (pc_o     ), 
		.B      (32'd4    ), 
		.cin    (1'b0     ), 
		.result (pc_add_4 ), 
		.cout   (         )
	);
	*/
	reg int_pc_ok;

	always@(posedge clk)
	begin
		if (!resetn) int_pc_ok <= 1'b1;
		else if (int_exc) int_pc_ok <= 1'b0;
		else if (inst_sram_ok) int_pc_ok <= 1'b1;
	end

	wire [31:0] inst_o;
	wire [31:0] pc_o;

	assign pc_add_4 = pc_o + 3'd4;

	wire pc_stall = stop | load_forward | !inst_sram_ok | !int_pc_ok | !if_allowin;
	wire inst_stall = int_exc | if_exc | op_eret | !inst_sram_ok | (inst_sram_ok & !int_pc_ok);

	assign next_pc = !resetn ? 32'hbfc00000 :
                     j_token ? id_next_pc_i : pc_add_4;

	//for latency
	assign irom_pc_o = pc;
	assign inst_o    = {32{!inst_stall}} & irom_inst_i;
	assign pc_o      = pc;
    assign inst_ren  = if_stage & !int_exc;

    wire if_exc_s;
	assign if_exc_s = (irom_pc_o[1:0] != 2'b00) & if_stage;

	wire if_exc;
	wire [5:0] if_excode;

	assign if_exc = (pc[1:0] != 2'b00) & if_stage;
	assign if_excode = {6{if_exc}} & `LS132R_EX_ADEL;

	// pipe

	reg  [31:0] if_inst_reg;
    reg  [31:0] if_pc_reg;
    reg  [31:0] if_pc_add4_reg; 
	reg         if_exc_reg;
	reg  [ 5:0] if_excode_reg;  

	reg  if_valid;
    wire if_allowin;
    wire if_ready_go;

    assign if_ready_go     = resetn & !load_forward & inst_sram_ok;
    assign if_allowin      = !if_valid | if_ready_go & id_allowin;
    assign if_to_id_valid  = if_valid & if_ready_go;

    always @(posedge clk) 
    begin
        if (!resetn || int_exc)
            if_valid     <= 1'b0;
        else if (if_allowin) 
            if_valid     <= if_validin;

        if (!resetn || int_exc)
        begin
            if_inst_reg      <= 32'd0;
            if_pc_reg        <= 32'hbfc00000;
            if_pc_add4_reg   <= 32'hbfc00004;
			if_exc_reg       <= 1'b0;
			if_excode_reg    <= 6'd0;
        end
        else if(if_validin & if_allowin)
        begin
            if_inst_reg      <= inst_o;
            if_pc_reg        <= pc_o;
            if_pc_add4_reg   <= pc_add_4;
			if_exc_reg       <= if_exc;
			if_excode_reg    <= if_excode;
        end
    end

    assign if_pc_o       = if_pc_reg;
    assign if_pc_add4_o  = if_pc_add4_reg;
    assign if_inst_o     = if_inst_reg;
	assign if_exc_o      = if_exc_reg;
	assign if_excode_o   = if_excode_reg;
	assign if_id_stage_o = if_valid;

endmodule