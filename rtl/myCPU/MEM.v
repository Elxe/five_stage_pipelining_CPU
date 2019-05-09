// Project: MEM unit
// Author: Zhang Ningxin

module MEM(
	input         clk,
	input         resetn,
	input         me_stage,
	input         int_exc,

	input         ex_to_me_valid,

    input         me_rs_bd_i,
	input  [31:0] me_pc_i,
	input  [31:0] me_inst_i,
	input  [10:0] me_mem_ctrl_i,
	input  [11:0] me_wb_ctrl_i,
	input  [ 4:0] me_waddr_i,
	input  [31:0] me_address_i,
	input  [31:0] me_write_data_i,
	input  [ 2:0] ex_exc,
	input  [17:0] ex_excode,

	input  [31:0] me_HI_i,
	input  [31:0] me_LO_i,

	input  [31:0] read_data_i,
	input         data_sram_ok,

	output        me_allowin,
	output        me_ex_stall,
	output        me_wb_stage_o,

	output [ 3:0] me_exc_o,
	output [23:0] me_excode_o,

	output [31:0] me_pc_o,
	output [31:0] me_inst_o,
	output [11:0] me_wb_ctrl_o,
	output [ 4:0] me_waddr_o,
	output [31:0] me_ALUout_o,
	output [31:0] me_rdata2_o,
	output [31:0] load_data_o,
	output        me_rs_bd_o,

	output [31:0] me_HI_o,
	output [31:0] me_LO_o,

	output [31:0] address_o,
	output [ 3:0] data_wen,
	output [31:0] write_data_o,
	output        data_ren,
	output [ 1:0] data_rsize,
	output [31:0] read_data_o
);
	wire [ 1:0] ea;
	reg  [ 5:0] save_mem_ctrl;
	reg  [ 1:0] save_ea;
	reg  [31:0] save_write_data;

	assign ea = me_address_i[1:0];
	
	wire op_lb;
	wire op_lh;
	wire op_lw;
	wire op_lwl;
	wire op_lwr;
	wire op_sb;
	wire op_sh;
	wire op_sw;
	wire op_swl;
	wire op_swr;

	assign op_lw  = save_mem_ctrl[4];
	assign op_lwl = save_mem_ctrl[3];
	assign op_lwr = save_mem_ctrl[2];
	assign op_lh  = save_mem_ctrl[1];
	assign op_lb  = save_mem_ctrl[0];

	assign op_sw  = me_mem_ctrl_i[4];
	assign op_swl = me_mem_ctrl_i[3];
	assign op_swr = me_mem_ctrl_i[2];
	assign op_sh  = me_mem_ctrl_i[1];
	assign op_sb  = me_mem_ctrl_i[0];

	wire data_ren_s;
	//wire data_ren_o;
	
	assign data_ren_s  = me_stage & !int_exc & (|me_mem_ctrl_i[9:0]);
	assign data_ren    = data_ren_s & !me_exc; 
	//assign data_ren    = data_ren_o;
/*
	reg data_reading;

	always@(posedge clk)
	begin
		if (!resetn)
			data_reading <= 1'b0;
		else if (data_ren_o)
			data_reading <= 1'b1;
		else if (data_sram_ok)
			data_reading <= 1'b0;
	end
*/
    //assign address_o   = (op_swl | op_swr | me_mem_ctrl_i[8] | me_mem_ctrl_i[7]) ? {me_address_i[31:2], 2'b00} : me_address_i[31:0];
	assign address_o   = {me_address_i[31:2], 2'b00};

	wire [31:0] lw_rdata;
	wire [31:0] lwl_rdata;
	wire [31:0] lwr_rdata;
	wire [31:0] lh_rdata;
	wire [31:0] lb_rdata;
	wire [31:0] sw_wdata;
	wire [31:0] swl_wdata;
	wire [31:0] swr_wdata;
	wire [31:0] sh_wdata;
	wire [31:0] sb_wdata;
	wire [ 3:0] sw_wen;
	wire [ 3:0] swl_wen;
	wire [ 3:0] swr_wen;
	wire [ 3:0] sh_wen;
	wire [ 3:0] sb_wen;

	reg  [31:0] save_data_reg;

	// load part

	assign lw_rdata = save_data_reg;

	mux_4 #(32) mux_lwl_rdata (
		.data_0		({save_data_reg[ 7:0], save_write_data[23:0]} ),	
		.data_1		({save_data_reg[15:0], save_write_data[15:0]} ),
		.data_2		({save_data_reg[23:0], save_write_data[ 7:0]} ),
		.data_3		(save_data_reg                                ), 
		.condition	(save_ea                                      ),
		.data_out	(lwl_rdata                                    )
	);

	mux_4 #(32) mux_lwr_rdata (
		.data_0		(save_data_reg                                  ),
		.data_1		({save_write_data[31:24], save_data_reg[31: 8]} ),
		.data_2		({save_write_data[31:16], save_data_reg[31:16]} ),
		.data_3		({save_write_data[31: 8], save_data_reg[31:24]} ),
		.condition	(save_ea                                        ),
		.data_out	(lwr_rdata                                      )
	);

	mux_4 #(32) mux_lh_rdata (
		.data_0		({{16{save_data_reg[15]}}, save_data_reg[15: 0]} ),	
		.data_1		({{16{save_data_reg[31]}}, save_data_reg[31:16]} ),
		.data_2		({{16{1'b0}},            save_data_reg[15: 0]}   ),
		.data_3		({{16{1'b0}},            save_data_reg[31:16]}   ),
		.condition	({save_mem_ctrl[5], save_ea[1]}                  ),
		.data_out	(lh_rdata                                        )
	);

	mux_8 #(32) mux_lb_rdata (
		.data_0		({{24{save_data_reg[ 7]}}, save_data_reg[ 7: 0]} ),	
		.data_1		({{24{save_data_reg[15]}}, save_data_reg[15: 8]} ),
		.data_2		({{24{save_data_reg[23]}}, save_data_reg[23:16]} ),
		.data_3		({{24{save_data_reg[31]}}, save_data_reg[31:24]} ),
		.data_4		({{24{1'b0}},              save_data_reg[ 7: 0]} ),	
		.data_5		({{24{1'b0}},              save_data_reg[15: 8]} ),
		.data_6		({{24{1'b0}},              save_data_reg[23:16]} ),
		.data_7		({{24{1'b0}},              save_data_reg[31:24]} ),
		.condition	({save_mem_ctrl[5], save_ea[1:0]}                ),
		.data_out	(lb_rdata                                        )
	);

	assign read_data_o = ({32{op_lw }}  & lw_rdata  )
					   | ({32{op_lwl}}  & lwl_rdata )
					   | ({32{op_lwr}}  & lwr_rdata )
					   | ({32{op_lh }}  & lh_rdata  )
					   | ({32{op_lb }}  & lb_rdata  );

	// store part

	assign sw_wdata = me_write_data_i;
	assign sw_wen   = 4'b1111;

	mux_4 #(36) mux_swl_wdata (
		.data_0		({{4'b0001}, {24{1'b0}}, me_write_data_i[31:24]} ),	
		.data_1		({{4'b0011}, {16{1'b0}}, me_write_data_i[31:16]} ),
		.data_2		({{4'b0111}, { 8{1'b0}}, me_write_data_i[31: 8]} ),
		.data_3		({{4'b1111},             me_write_data_i[31: 0]} ),                        
		.condition	(ea                                              ),
		.data_out	({swl_wen, swl_wdata}                            )
	);

	mux_4 #(36) mux_swr_wdata (
		.data_0		({{4'b1111}, me_write_data_i[31: 0]}             ),	
		.data_1		({{4'b1110}, me_write_data_i[23: 0], { 8{1'b0}}} ),
		.data_2		({{4'b1100}, me_write_data_i[15: 0], {16{1'b0}}} ),
		.data_3		({{4'b1000}, me_write_data_i[ 7: 0], {24{1'b0}}} ),                        
		.condition	(ea                                              ),
		.data_out	({swr_wen, swr_wdata}                            )   
	);

	mux_2 #(36) mux_sh_wdata (
		.data_0		({{4'b0011}, {16{1'b0}}, me_write_data_i[15:0]}  ),
		.data_1		({{4'b1100}, me_write_data_i[15:0], {16{1'b0}}}  ),
		.condition	(ea[1]                                           ),
		.data_out	({sh_wen, sh_wdata}                              )
	);

	mux_4 #(36) mux_sb_wdata (
		.data_0		({{4'b0001}, {24{1'b0}}, me_write_data_i[7:0]            } ),	
		.data_1		({{4'b0010}, {16{1'b0}}, me_write_data_i[7:0], { 8{1'b0}}} ),
		.data_2		({{4'b0100}, { 8{1'b0}}, me_write_data_i[7:0], {16{1'b0}}} ),
		.data_3		({{4'b1000},             me_write_data_i[7:0], {24{1'b0}}} ),
		.condition	(ea                                                        ),
		.data_out	({sb_wen, sb_wdata}                                        )
	);

	assign write_data_o = ({32{op_sw }} & sw_wdata  )
						| ({32{op_swl}} & swl_wdata )
						| ({32{op_swr}} & swr_wdata )
						| ({32{op_sh }} & sh_wdata  )
						| ({32{op_sb }} & sb_wdata  );

	wire [3:0] data_wen_s;

	assign data_wen_s   = ({4{op_sw }} & sw_wen  )
						| ({4{op_swl}} & swl_wen )
						| ({4{op_swr}} & swr_wen )
						| ({4{op_sh }} & sh_wen  )
						| ({4{op_sb }} & sb_wen  );
	assign data_rsize   = op_lb ? 2'd0 :
						  op_lh ? 2'd1 : 2'd2;
	assign data_wen     = data_wen_s & {4{!me_exc}};

	always@(posedge clk) save_data_reg <= data_sram_ok ? read_data_i : save_data_reg;

	// intrupter

	wire       me_exc;
	wire [5:0] me_excode;
	wire       store_error;
	wire       load_error;

	assign store_error = (me_address_i[1:0] != 2'b00) & op_sw | (me_address_i[0] != 1'b0) & op_sh;
	assign load_error = (me_address_i[1:0] != 2'b00) & me_mem_ctrl_i[9] | (me_address_i[0] != 1'b0) & me_mem_ctrl_i[6];

	assign me_exc    = (store_error | load_error) & me_stage & (data_ren_s | (data_wen_s == 4'b1111));
	assign me_excode = {6{load_error}} & `LS132R_EX_ADEL
					 | {6{store_error}} & `LS132R_EX_ADES;

	// pipe
	reg  me_valid;
    wire me_ready_go;

	assign me_ex_stall = data_ren & !data_sram_ok;

    assign me_ready_go = resetn;
    assign me_allowin  = !me_valid | me_ready_go;

    reg  [31:0] me_pc_reg;
    reg  [31:0] me_inst_reg;
    reg  [11:0] me_wb_ctrl_reg;
    reg  [31:0] me_rdata2_reg;
    reg  [31:0] me_ALUout_reg;
    reg  [ 4:0] me_waddr_reg;
    reg  [31:0] me_load_data_reg;
	reg  [ 3:0] me_exc_reg;
	reg  [23:0] me_excode_reg;
	reg         me_rs_bd_reg;

	reg  [31:0] me_HI_reg;
	reg  [31:0] me_LO_reg;

    always@(posedge clk)
    begin
        if(!resetn || int_exc || !me_ready_go)
            me_valid     <=  1'b0;
        else if (me_allowin)
            me_valid     <= ex_to_me_valid;
			
        if(!resetn || int_exc)
        begin
        	me_pc_reg        <= 32'hbfc00000;
        	me_inst_reg      <= 32'd0;
            me_wb_ctrl_reg   <= 12'd0;
            me_ALUout_reg    <= 32'd0;
            me_rdata2_reg    <= 32'd0;
            me_waddr_reg     <=  5'd0;
            me_load_data_reg <= 32'd0;
			me_exc_reg       <=  4'd0;
			me_excode_reg    <= 24'd0;
			me_rs_bd_reg     <=  1'b0;
			me_HI_reg        <= 32'd0;
			me_LO_reg        <= 32'd0;

			save_mem_ctrl    <=  6'd0;
			save_ea          <=  2'd0;
			save_write_data  <= 32'd0;
        end
        else if(ex_to_me_valid & me_allowin)
        begin
        	me_pc_reg        <= me_pc_i;
        	me_inst_reg      <= me_inst_i;
            me_wb_ctrl_reg   <= me_wb_ctrl_i;
            me_ALUout_reg    <= me_address_i;
            me_rdata2_reg    <= me_write_data_i;
            me_waddr_reg     <= me_waddr_i;
            me_load_data_reg <= read_data_o;
			me_exc_reg       <= {me_exc, ex_exc};
			me_excode_reg    <= {me_excode, ex_excode};
			me_rs_bd_reg     <= me_rs_bd_i;
			me_HI_reg        <= me_HI_i;
			me_LO_reg        <= me_LO_i;

			save_mem_ctrl    <= me_mem_ctrl_i[10:5];
			save_ea          <= ea;
			save_write_data  <= me_write_data_i;
        end
    end

	assign me_exc_o      = me_exc_reg;
	assign me_excode_o   = me_excode_reg;
	assign load_data_o   = me_load_data_reg;
	assign me_pc_o       = me_pc_reg;
	assign me_inst_o     = me_inst_reg;
	assign me_wb_ctrl_o  = me_wb_ctrl_reg & {12{me_valid}};
	assign me_ALUout_o   = me_ALUout_reg;
	assign me_rdata2_o   = me_rdata2_reg;
	assign me_waddr_o    = me_waddr_reg;
	assign me_wb_stage_o = me_valid;
	assign me_rs_bd_o    = me_rs_bd_reg;
	assign me_HI_o       = me_HI_reg;
	assign me_LO_o       = me_LO_reg;

endmodule