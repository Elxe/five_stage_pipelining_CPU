// Project: EX unit
// Author: Zhang Ningxin

module EX(
	input         clk,
	input         resetn,
	input         ex_stage,
	input         int_exc,

    input         id_to_ex_valid,
	input         me_allowin,
	input         me_ex_stall,

	input  [ 1:0] id_exc,
	input  [11:0] id_excode,

    input         ex_rs_bd_i,
	input  [31:0] ex_pc_i,
	input  [31:0] ex_inst_i,
	input  [19:0] ex_exe_ctrl_i,
	input  [10:0] ex_mem_ctrl_i,
	input  [11:0] ex_wb_ctrl_i,
	input  [31:0] ex_ext_imm_i,
	input  [31:0] ex_rdata1_i,
	input  [31:0] ex_rdata2_i,
	input  [ 4:0] ex_waddr_i,
	input  [31:0] ex_HI_i,
	input  [31:0] ex_LO_i,

	output        ex_allowin,
	output        ex_to_me_valid,
	output        ex_me_stage_o,

	output [ 1:0] mul_ctrl_o,
	output [ 1:0] div_ctrl_o,
	output [31:0] ex_pc_o,
	output [31:0] ex_inst_o,
	output [10:0] ex_mem_ctrl_o,
	output [11:0] ex_wb_ctrl_o,
	output [ 4:0] ex_waddr_o,
	output [31:0] ex_address_o,
	output [31:0] ex_write_data_o,
	output [ 2:0] ex_exc_o,
	output [17:0] ex_excode_o,
	output        ex_rs_bd_o,

	output [31:0] ex_HI_o,
	output [31:0] ex_LO_o,

	output [31:0] ex_rdata1_o,
	output [31:0] ex_rdata2_o,
	output [31:0] ex_ALUout_o
);

	wire [19:0] de_exe_ctrl;
	wire [31:0] de_inst;

	assign de_inst     = ex_inst_i & {32{ex_stage}};
	assign de_exe_ctrl = ex_exe_ctrl_i & {20{ex_stage}};

	wire [25:0] index;
	wire [ 4:0] shamt;
	wire [ 5:0] funct;
	wire [ 7:0] ALUop;
	wire        ALUSrcA;
	wire [ 1:0] ALUSrcB;

	assign index   = de_inst[25:0];
	assign shamt   = de_inst[10:6];
	assign funct   = de_inst[5:0];
	assign ALUop   = de_exe_ctrl[10:3];
	assign ALUSrcA = de_exe_ctrl[2];
	assign ALUSrcB = de_exe_ctrl[1:0];

	assign div_ctrl_o = de_exe_ctrl[18:17];
	assign mul_ctrl_o = de_exe_ctrl[16:15];

	wire [14:0] ALUctl;

	ALU_control acu(
		.ALUop  (ALUop  ),
		.funct  (funct  ),
		.ALUctl (ALUctl )
	);

	wire        Zero;
	wire [31:0] ALUout;
	wire        op_mfhi;
	wire        op_mflo;

	assign op_mfhi = de_exe_ctrl[14];
	assign op_mflo = de_exe_ctrl[13];

	wire [31:0] mux_ALU_A;
	wire [31:0] mux_ALU_B;

	wire [31:0] ALU_A_i;
	wire [31:0] ALU_B_i;


	assign mux_ALU_A = ex_rdata1_i;

	assign mux_ALU_B = ex_rdata2_i;

	mux_2 #(32) mux_ALUSrcA (
		.data_0	   (mux_ALU_A  ),
		.data_1	   (ex_pc_i    ),
		.condition (ALUSrcA    ),
		.data_out  (ALU_A_i    )
	);

	mux_4 #(32) mux_ALUSrcB (
		.data_0	   (mux_ALU_B    ),
		.data_1	   (ex_ext_imm_i ),
		.data_2    (32'd8        ),
		.data_3	   (32'd0        ), 
		.condition (ALUSrcB      ),
		.data_out  (ALU_B_i      )
	);

	wire Overflow;

	alu op(
		.A        (ALU_A_i  ),
		.B        (ALU_B_i  ),
		.shamt    (shamt    ),
		.ALUop    (ALUctl   ),
		.CarryOut (         ),
		.Overflow (Overflow ),
		.Zero     (Zero     ),
		.Result   (ALUout   )
	);

	wire [31:0] address;
	wire [31:0] write_data;

	assign address     = ALUout;
	assign write_data  = ex_rdata2_o;
	assign ex_rdata1_o = mux_ALU_A;
	assign ex_rdata2_o = mux_ALU_B;
	assign ex_ALUout_o = ALUout;

	// intrupt
	wire       ex_exc;
	wire [5:0] ex_excode;

	assign ex_exc = Overflow & ex_stage & de_exe_ctrl[19];
	assign ex_excode = {6{ex_exc}} & `LS132R_EX_OV;

	// pipe

	reg  [31:0] ex_pc_reg;
	reg  [31:0] ex_inst_reg;
    reg  [10:0] ex_mem_ctrl_reg;
    reg  [11:0] ex_wb_ctrl_reg;
    reg  [ 4:0] ex_waddr_reg;
    reg  [31:0] ex_address_reg;
    reg  [31:0] ex_write_data_reg; 
	reg  [ 2:0] ex_exc_reg;
	reg  [17:0] ex_excode_reg;
	reg         ex_rs_bd_reg;

	reg [31:0] ex_hi_reg;
	reg [31:0] ex_lo_reg;

	reg  ex_valid;
    wire ex_ready_go;

    assign ex_ready_go = resetn & !me_ex_stall;
    assign ex_allowin  = !ex_valid | ex_ready_go & me_allowin;
    assign ex_to_me_valid = ex_valid & ex_ready_go;

    always @(posedge clk) 
    begin
        if (!resetn || int_exc) 
            ex_valid     <=  1'b0;
        else if (ex_allowin)
            ex_valid     <=  id_to_ex_valid;

        if(!resetn || int_exc)
        begin
        	ex_pc_reg          <= 32'hbfc00000;
        	ex_inst_reg        <= 32'd0;
            ex_mem_ctrl_reg    <= 11'd0;
            ex_wb_ctrl_reg     <= 12'd0;
            ex_waddr_reg       <=  5'd0;
            ex_address_reg     <= 32'd0;
            ex_write_data_reg  <= 32'd0;
			ex_exc_reg         <=  3'd0;
			ex_excode_reg      <= 18'd0;
			ex_rs_bd_reg       <=  1'b0;
			ex_hi_reg          <= 32'd0;
			ex_lo_reg          <= 32'd0;
        end
        else if (id_to_ex_valid & ex_allowin) 
        begin
        	ex_pc_reg          <= ex_pc_i;
        	ex_inst_reg        <= ex_inst_i;
            ex_mem_ctrl_reg    <= ex_mem_ctrl_i;
            ex_wb_ctrl_reg     <= ex_wb_ctrl_i;
            ex_waddr_reg       <= ex_waddr_i; 
            ex_address_reg     <= address;
            ex_write_data_reg  <= write_data;
			ex_exc_reg         <= {ex_exc, id_exc};
			ex_excode_reg      <= {ex_excode, id_excode};
			ex_rs_bd_reg       <= ex_rs_bd_i;

			if (|de_exe_ctrl[18:11]) 
			begin
				ex_hi_reg <= ex_HI_i;
				ex_lo_reg <= ex_LO_i;
			end
        end
    end

    // assign ex_mem_ctrl_o    = {me_wb_mem_ctrl_reg[10:5], ex_mem_ctrl_reg[4:0]};
	assign ex_pc_o          = ex_pc_reg;
	assign ex_inst_o        = ex_inst_reg;
	assign ex_mem_ctrl_o    = ex_mem_ctrl_reg;
	assign ex_wb_ctrl_o     = ex_wb_ctrl_reg;
	assign ex_waddr_o       = ex_waddr_reg;
    assign ex_address_o     = ex_address_reg;
    assign ex_write_data_o  = ex_write_data_reg;
	assign ex_exc_o         = ex_exc_reg;
	assign ex_excode_o      = ex_excode_reg;
	assign ex_me_stage_o    = ex_valid;
	assign ex_rs_bd_o       = ex_rs_bd_reg;
	assign ex_HI_o          = ex_hi_reg;
	assign ex_LO_o          = ex_lo_reg;
	
endmodule