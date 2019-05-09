// Project: WB unit
// Author: Zhang Ningxin

module WB(
	input         clk,
	input         resetn,
	input         wb_stage,

    input  [ 6:0] hw_int,
    input  [ 3:0] me_exc,
    input  [23:0] me_excode,

    input         wb_rs_bd,
    input  [31:0] wb_pc_i,
    input  [31:0] wb_inst_i,

	input  [11:0] wb_ctrl,
	input  [ 4:0] wb_dst_i,
    input  [31:0] wb_HI_i,
    input  [31:0] wb_LO_i,
	input  [31:0] read_data,
	input  [31:0] ALU_result,
    input  [31:0] wb_rdata2_i,

    input         op_eret,

    output        int_exc,
    output [31:0] epc_value,

	output        wb_wen,
	output [ 4:0] wb_waddr, 
	output [31:0] wb_wdata
);

    wire [11:0] de_wb_ctrl;

    assign de_wb_ctrl = wb_ctrl & {12{wb_stage}};

	wire [1:0] reg_dst;
	wire       mem_to_reg;
	wire       reg_write;
	wire       op_link;
    wire       op_mfc0;
    wire       op_mtc0;
    wire       div_mul;
    wire       op_mfhi;
    wire       op_mflo;
    wire       op_mthi;
    wire       op_mtlo;

    assign div_mul    = wb_ctrl[11];
    assign op_mfhi    = wb_ctrl[10];
    assign op_mflo    = wb_ctrl[9];
    assign op_mthi    = wb_ctrl[8];
    assign op_mtlo    = wb_ctrl[7];
    assign op_mfc0    = wb_ctrl[6];
    assign op_mtc0    = wb_ctrl[5];
	assign op_link    = wb_ctrl[4];
	assign reg_dst    = wb_ctrl[3:2];
	assign mem_to_reg = wb_ctrl[1];
	assign reg_write  = wb_ctrl[0];

    wire [2:0] sel;
    wire [4:0] rt;
    wire [4:0] rd;

    assign sel = wb_inst_i[2:0];
    assign rt  = wb_inst_i[20:16];
    assign rd  = wb_inst_i[15:11];

	assign wb_wen = (reg_write & wb_stage)  & (wb_waddr != 5'd0) & !int_exc;
	assign wb_waddr = wb_dst_i & ~{5{op_mfc0 | op_mtc0}} | rt & {5{op_mfc0}};
	
    wire [31:0] mux_wdata;

	mux_2 #(32) mux_wb_data (
		.data_0		(ALU_result	  ),	
		.data_1		(read_data	  ),
		.condition	(mem_to_reg   ),
		.data_out	(mux_wdata     )
	);
	
	assign wb_wdata = op_mfc0 ? cp0_rd_value :
                      op_mfhi ? hi_value     :
                      op_mflo ? lo_value     : mux_wdata;

    reg [31:0] HI;
    reg [31:0] LO;

    wire [31:0] hi_value;
    wire [31:0] lo_value;

    assign hi_value = HI;
    assign lo_value = LO;

    always @(posedge clk)
    begin
        if(!resetn)
            HI <= 32'd0;
        else if(div_mul | op_mthi)
            HI <= wb_HI_i;
    end

    always @(posedge clk)
    begin
        if(!resetn)
            LO <= 32'd0;
        else if(div_mul | op_mtlo)
            LO <= wb_LO_i;
    end

    // interupt

    wire       wb_exc_s;
    wire [5:0] wb_excode_s;

    assign wb_exc_s    = (|int_vec) & !cp0_status_EXL & cp0_status_IE & wb_stage;
    assign wb_excode_s = {5{wb_exc_s}} & `LS132R_EX_INT;

    wire if_exc_s;
    wire id_exc_s;
    wire ex_exc_s;
    wire me_exc_s;
    
    assign if_exc_s = me_exc[0];
    assign id_exc_s = me_exc[1];
    assign ex_exc_s = me_exc[2];
    assign me_exc_s = me_exc[3];
    
    wire [5:0] if_excode_s;
    wire [5:0] id_excode_s;
    wire [5:0] ex_excode_s;
    wire [5:0] me_excode_s;
    
    assign if_excode_s = me_excode[ 5: 0];
    assign id_excode_s = me_excode[11: 6];
    assign ex_excode_s = me_excode[17:12];
    assign me_excode_s = me_excode[23:18];
            
    wire [5:0] cause;

    assign cause = wb_exc_s ? wb_excode_s :
                   if_exc_s ? if_excode_s :
                   id_exc_s ? id_excode_s :
                   ex_exc_s ? ex_excode_s :
                   me_exc_s ? me_excode_s : 6'd0;

    assign int_exc = wb_stage ? if_exc_s | id_exc_s | ex_exc_s | me_exc_s | wb_exc_s : 1'b0;

	wire [5:0] int_pending;

    assign int_pending[5] = hw_int[5] | timer_int;
    assign int_pending[4:0] = hw_int[4:0];

    // cp0 registers
    wire count_cmp_eq;
    assign count_cmp_eq = (cp0_compare == cp0_count);

    wire cp0_wen;
    wire cp0_ren;
    wire [7:0] cp0_addr;
    wire [7:0] cp0_raddr;
    wire [7:0] cp0_waddr;
    wire [31:0] cp0_wr_value;
    wire [31:0] cp0_rd_value;
   
    reg  [31:0] cp0_epc;
    wire [31:0] epc;

    wire [7:0] int_vec;

    always@(posedge clk)
    begin
        if(!resetn)
            cp0_epc <= 32'd0;
        else if(int_exc && !cp0_status_EXL)
            cp0_epc <= epc;
        else if (cp0_wen && cp0_waddr == {5'd14, 3'd0})
            cp0_epc <= cp0_wr_value[31:0];
    end

    assign epc_value = cp0_epc;

    wire [29:0] pc_w_4 = wb_pc_i[31:2] - 1'b1;
    assign epc = wb_rs_bd ? {pc_w_4, wb_pc_i[1:0]} : wb_pc_i;

    reg  [31:0] cp0_badvaddr;

    wire [31:0] badvaddr_value;
    assign badvaddr_value = cp0_badvaddr;

    wire badaddr;
    assign badaddr = (cause == `LS132R_EX_ADEL || cause == `LS132R_EX_ADES);

    always@(posedge clk)
    begin
        if(!resetn)
            cp0_badvaddr <= 32'd0;
        else if (badaddr & if_exc_s)
            cp0_badvaddr <= wb_pc_i;
        else if (badaddr & me_exc_s)
            cp0_badvaddr <= ALU_result;
    end

    reg count_add_en;
    always @(posedge clk)
        count_add_en <= (!resetn || cp0_cause_DC) ? 1'b0 : ~count_add_en;

    reg  [31:0] cp0_count;

    wire [31:0] count_value;
    assign count_value = cp0_count;

    reg  [31:0] cp0_compare;

    wire [31:0] compare_value;
    assign compare_value = cp0_compare;

    wire        cp0_status_CU3   = 1'b0;
    wire        cp0_status_CU2   = 1'b0;
    wire        cp0_status_CU1   = 1'b0;
    reg         cp0_status_CU0;
    wire        cp0_status_RP    = 1'b0;
    wire        cp0_status_FR    = 1'b0;
    wire        cp0_status_RE    = 1'b0;
    wire        cp0_status_MX    = 1'b0;
    reg         cp0_status_BEV;
    wire        cp0_status_TS    = 1'b0;
    wire        cp0_status_SR    = 1'b0;
    reg         cp0_status_NMI;
    wire        cp0_status_ASE   = 1'b0;
    reg         cp0_status_IM7;
    reg         cp0_status_IM6;
    reg         cp0_status_IM5;
    reg         cp0_status_IM4;
    reg         cp0_status_IM3;
    reg         cp0_status_IM2;
    reg         cp0_status_IM1;
    reg         cp0_status_IM0;
    reg  [ 1:0] cp0_status_KSU;
    reg         cp0_status_ERL;
    reg         cp0_status_EXL;
    reg         cp0_status_IE;

    wire [31:0] status_value;
    assign status_value = {cp0_status_CU3, cp0_status_CU2, cp0_status_CU1, cp0_status_CU0,
            cp0_status_RP, cp0_status_FR, cp0_status_RE, cp0_status_MX, 1'b0, cp0_status_BEV,
            cp0_status_TS, cp0_status_SR, cp0_status_NMI, cp0_status_ASE, 2'b00, 
            cp0_status_IM7, cp0_status_IM6, cp0_status_IM5, cp0_status_IM4, cp0_status_IM3,
            cp0_status_IM2, cp0_status_IM1, cp0_status_IM0, 3'b000, cp0_status_KSU,
            cp0_status_ERL, cp0_status_EXL, cp0_status_IE};

    reg         cp0_cause_BD;
    reg  [1:0]  cp0_cause_CE;
    reg         cp0_cause_IV;
    reg         cp0_cause_IP7;
    reg         cp0_cause_IP6;
    reg         cp0_cause_IP5;
    reg         cp0_cause_IP4;
    reg         cp0_cause_IP3;
    reg         cp0_cause_IP2;
    reg         cp0_cause_IP1;
    reg         cp0_cause_IP0;
    reg  [4:0]  cp0_cause_ExcCode;
    reg         cp0_cause_TI;
    reg         cp0_cause_DC;
    wire        cp0_cause_PCI    = 1'b0;
    reg         cp0_cause_FDCI;
    wire        cp0_cause_WP     = 1'b0;

    wire [31:0] cause_value;
    assign cause_value = {cp0_cause_BD, cp0_cause_TI, cp0_cause_CE, cp0_cause_DC, 
            cp0_cause_PCI, 2'b00, cp0_cause_IV, cp0_cause_WP, cp0_cause_FDCI, 3'b000,
            2'b00, cp0_cause_IP7, cp0_cause_IP6, cp0_cause_IP5, cp0_cause_IP4, 
            cp0_cause_IP3, cp0_cause_IP2, cp0_cause_IP1, cp0_cause_IP0, 1'b0,
            cp0_cause_ExcCode, 2'b00};

    wire timer_int;
    assign timer_int = cp0_cause_TI;

    //cp0_count
    always@(posedge clk)
    begin
        if (!resetn)
            cp0_count <= 32'd0;
        else if (cp0_wen && cp0_waddr == {5'd9, 3'd0})
            cp0_count <= cp0_wr_value[31:0];
        else if (count_add_en)
            cp0_count <= cp0_count + 1;
    end
    // cp0_compare
    always@(posedge clk)
    begin
        if (!resetn)
            cp0_compare <= 32'd0;
        else if (cp0_wen && cp0_waddr == {5'd11, 3'd0})
            cp0_compare <= cp0_wr_value[31:0];
    end
    // cp0_status
    always@(posedge clk)
    begin
        if (!resetn)
        begin
            cp0_status_CU0   <= 1'b1;
            cp0_status_BEV   <= 1'b1;
            cp0_status_NMI   <= 1'b0;
            cp0_status_IM7   <= 1'b0;
            cp0_status_IM6   <= 1'b0;
            cp0_status_IM5   <= 1'b0;
            cp0_status_IM4   <= 1'b0;
            cp0_status_IM3   <= 1'b0;
            cp0_status_IM2   <= 1'b0;
            cp0_status_IM1   <= 1'b0;
            cp0_status_IM0   <= 1'b0;
            cp0_status_KSU   <= 2'b00; 
            cp0_status_ERL   <= 1'b1;
            cp0_status_EXL   <= 1'b0;
            cp0_status_IE    <= 1'b0;
        end
        else 
        begin 
            if (int_exc)
                cp0_status_EXL <= 1'b1;
            else if (op_eret)
                cp0_status_EXL <= 1'b0;
            else if (cp0_wen && cp0_waddr == {5'd12, 3'd0})
                cp0_status_EXL <= cp0_wr_value[1];

            if (cp0_wen && cp0_waddr=={5'd12, 3'd0})
                cp0_status_ERL <= cp0_wr_value[2];
            
            if (cp0_wen && cp0_waddr=={5'd12, 3'd0})
            begin
                cp0_status_CU0 <= cp0_wr_value[28];
                cp0_status_IM7 <= cp0_wr_value[15];
                cp0_status_IM6 <= cp0_wr_value[14];
                cp0_status_IM5 <= cp0_wr_value[13];
                cp0_status_IM4 <= cp0_wr_value[12];
                cp0_status_IM3 <= cp0_wr_value[11];
                cp0_status_IM2 <= cp0_wr_value[10];
                cp0_status_IM1 <= cp0_wr_value[ 9];
                cp0_status_IM0 <= cp0_wr_value[ 8];
                cp0_status_KSU <= cp0_wr_value[4:3]; 
                cp0_status_IE  <= cp0_wr_value[ 0];
            end
        end
    end
    // cp0_cause
    always@ (posedge clk)
    begin
        if (!resetn)
            cp0_cause_TI <= 1'b0;
        else if (cp0_wen && cp0_waddr=={5'd11, 3'd0})  //compare_wen
            cp0_cause_TI <= 1'b0;
        else if (count_cmp_eq)
            cp0_cause_TI <= 1'b1;


        if (!resetn)
        begin
            cp0_cause_BD     <= 1'b0;
            cp0_cause_CE     <= 2'b00;
            cp0_cause_IV     <= 1'b0;
            cp0_cause_IP7    <= 1'b0;
            cp0_cause_IP6    <= 1'b0;
            cp0_cause_IP5    <= 1'b0;
            cp0_cause_IP4    <= 1'b0;
            cp0_cause_IP3    <= 1'b0;
            cp0_cause_IP2    <= 1'b0;
            cp0_cause_IP1    <= 1'b0;
            cp0_cause_IP0    <= 1'b0;
            cp0_cause_ExcCode<= 5'h1f;
            cp0_cause_FDCI   <= 1'b0;
            cp0_cause_DC     <= 1'b0;
            cp0_cause_TI     <= 1'b0;
        end
        else 
        begin

            if (!cp0_status_EXL)
                cp0_cause_BD <= wb_rs_bd;

            if (int_exc)
                cp0_cause_ExcCode <= cause;
            
            if (cp0_wen && cp0_waddr=={5'd13, 3'd0})
            begin
                cp0_cause_DC   <= cp0_wr_value[27];
                cp0_cause_IV   <= cp0_wr_value[23];
                cp0_cause_IP1  <= cp0_wr_value[ 9];
                cp0_cause_IP0  <= cp0_wr_value[ 8];
            end

            cp0_cause_IP7    <= int_pending[5];
            cp0_cause_IP6    <= int_pending[4];
            cp0_cause_IP5    <= int_pending[3];
            cp0_cause_IP4    <= int_pending[2];
            cp0_cause_IP3    <= int_pending[1];
            cp0_cause_IP2    <= int_pending[0];
        end
    end
    
    // cp0 operation
    assign cp0_ren      = op_mfc0;
    assign cp0_wen      = op_mtc0;
    assign cp0_addr     = {rd, sel};
    assign cp0_raddr    = op_mfc0 ? cp0_addr : 8'h0;
    assign cp0_waddr    = op_mtc0 ? cp0_addr : 8'h0;
    assign cp0_wr_value = wb_rdata2_i[31:0];

    assign cp0_rd_value = 
          {32{cp0_raddr=={5'd8 , 3'd0}}}&badvaddr_value    
        | {32{cp0_raddr=={5'd12, 3'd0}}}&status_value     
        | {32{cp0_raddr=={5'd13, 3'd0}}}&cause_value      
        | {32{cp0_raddr=={5'd14, 3'd0}}}&cp0_epc        
        | {32{cp0_raddr=={5'd9,  3'd0}}}&count_value
        | {32{cp0_raddr=={5'd11, 3'd0}}}&compare_value
        ;

    assign int_vec   = {cp0_cause_IP7 & cp0_status_IM7,
                        cp0_cause_IP6 & cp0_status_IM6,
                        cp0_cause_IP5 & cp0_status_IM5,
                        cp0_cause_IP4 & cp0_status_IM4,
                        cp0_cause_IP3 & cp0_status_IM3,
                        cp0_cause_IP2 & cp0_status_IM2,
                        cp0_cause_IP1 & cp0_status_IM1,
                        cp0_cause_IP0 & cp0_status_IM0};

endmodule