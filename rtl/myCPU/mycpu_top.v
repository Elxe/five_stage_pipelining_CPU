// Project: cpu_top
// Author: Zhang Ningxin


module mycpu_top(
    input  [ 5:0] int,   //high active
    
    input         aclk,
    input         aresetn,   //low active
    
    //axi
    //ar
    output [ 3:0] arid,
    output [31:0] araddr,
    output [ 7:0] arlen, // fix 0
    output [ 2:0] arsize,
    output [ 1:0] arburst, // fix 01
    output [ 1:0] arlock, // fix 0
    output [ 3:0] arcache, // fix 0
    output [ 2:0] arprot, // fix 0
    output        arvalid,
    input         arready,
    //r              
    input  [ 3:0] rid,
    input  [31:0] rdata,
    input  [ 1:0] rresp, // ignore
    input         rlast, // ignore
    input         rvalid,
    output        rready,
    //aw           
    output [ 3:0] awid, // fix 1
    output [31:0] awaddr,
    output [ 7:0] awlen, // fix 0
    output [ 2:0] awsize,
    output [ 1:0] awburst, // fix 01
    output [ 1:0] awlock, // fix 0
    output [ 3:0] awcache, // fix 0
    output [ 2:0] awprot, // fix 0
    output        awvalid,
    input         awready,
    //w          
    output [ 3:0] wid, // fix 1
    output [31:0] wdata,
    output [ 3:0] wstrb,
    output        wlast, // fix 1
    output        wvalid,
    input         wready,
    //b              
    input  [ 3:0] bid, // ignore
    input  [ 1:0] bresp,
    input         bvalid,
    output        bready,

    //debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

    wire clk = aclk;
    wire resetn = aresetn;
    
    wire        inst_sram_en;
    wire [ 3:0] inst_sram_wen;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;
    wire        inst_sram_ok;
    
    wire        data_sram_en;
    wire [ 1:0] data_sram_rsize;
    wire [ 3:0] data_sram_wen;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;
    wire        data_sram_ok;

    // inst ROM only
    assign inst_sram_wen   = 4'd0;
    assign inst_sram_wdata = 32'd0;

    //----inst sram-like----
    wire        inst_req;
    wire        inst_wr;
    wire [ 1:0] inst_size;
    wire [31:0] inst_addr;
    wire [31:0] inst_wdata;
    wire [31:0] inst_rdata;
    wire        inst_addr_ok;
    wire        inst_data_ok;
    
    //----data sram-like----
    wire         data_req;
    wire         data_wr;
    wire  [1 :0] data_size;
    wire  [ 3:0] data_strb;
    wire  [31:0] data_addr;
    wire  [31:0] data_wdata;
    wire  [31:0] data_rdata;
    wire         data_raddr_ok;
    wire         data_waddr_ok;
    wire         data_rdata_ok;
    wire         data_wdata_ok;

    cpu_axi_interface brige(
        .clk          (clk          ),
        .resetn       (resetn       ),

        .inst_req     (inst_req     ),
        .inst_wr      (inst_wr      ),
        .inst_size    (inst_size    ),
        .inst_addr    (inst_addr    ),
        .inst_wdata   (inst_wdata   ),
        .inst_rdata   (inst_rdata   ),
        .inst_addr_ok (inst_addr_ok ),
        .inst_data_ok (inst_data_ok ),

        .data_req     (data_req     ),
        .data_wr      (data_wr      ),
        .data_size    (data_size    ),
        .data_strb    (data_strb    ),
        .data_addr    (data_addr    ),
        .data_wdata   (data_wdata   ),
        .data_rdata   (data_rdata   ),

        .data_raddr_ok (data_raddr_ok ),
        .data_waddr_ok (data_waddr_ok ),
        .data_rdata_ok (data_rdata_ok ),
        .data_wdata_ok (data_wdata_ok ),

        .arid         (arid         ),
        .araddr       (araddr       ),
        .arlen        (arlen        ),
        .arsize       (arsize       ),
        .arburst      (arburst      ),
        .arlock       (arlock       ),
        .arcache      (arcache      ),
        .arprot       (arprot       ),
        .arvalid      (arvalid      ),
        .arready      (arready      ),

        .rid          (rid          ),
        .rdata        (rdata        ),
        .rresp        (rresp        ),
        .rlast        (rlast        ),
        .rvalid       (rvalid       ),
        .rready       (rready       ),

        .awid         (awid         ),
        .awaddr       (awaddr       ),
        .awlen        (awlen        ),
        .awsize       (awsize       ),
        .awburst      (awburst      ),
        .awlock       (awlock       ),
        .awcache      (awcache      ),
        .awprot       (awprot       ),
        .awvalid      (awvalid      ),
        .awready      (awready      ),

        .wid          (wid          ),
        .wdata        (wdata        ),
        .wstrb        (wstrb        ),
        .wlast        (wlast        ),
        .wvalid       (wvalid       ),
        .wready       (wready       ),

        .bid          (bid          ),
        .bresp        (bresp        ),
        .bvalid       (bvalid       ),
        .bready       (bready       )
    );

    interface sram_trans (
        .clk             (clk             ),
        .resetn          (resetn          ),

        .inst_sram_en    (inst_sram_en    ),
        .inst_sram_wen   (inst_sram_wen   ),
        .inst_sram_addr  (inst_sram_addr  ),
        .inst_sram_wdata (inst_sram_wdata ),
        .inst_sram_rdata (inst_sram_rdata ),
        .inst_sram_ok    (inst_sram_ok    ),

        .data_sram_en    (data_sram_en    ),
        .data_sram_rsize (data_sram_rsize ),
        .data_sram_wen   (data_sram_wen   ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata ),
        .data_sram_rdata (data_sram_rdata ),
        .data_sram_ok    (data_sram_ok    ),

        .inst_req        (inst_req        ),
        .inst_wr         (inst_wr         ),
        .inst_size       (inst_size       ),
        .inst_addr       (inst_addr       ),
        .inst_wdata      (inst_wdata      ),
        .inst_rdata      (inst_rdata      ),
        .inst_addr_ok    (inst_addr_ok    ),
        .inst_data_ok    (inst_data_ok    ),

        .data_req        (data_req        ),
        .data_wr         (data_wr         ),
        .data_size       (data_size       ),
        .data_strb       (data_strb       ),
        .data_addr       (data_addr       ),
        .data_wdata      (data_wdata      ),
        .data_rdata      (data_rdata      ),
        .data_raddr_ok   (data_raddr_ok   ),
        .data_waddr_ok   (data_waddr_ok   ),
        .data_rdata_ok   (data_rdata_ok   ),
        .data_wdata_ok   (data_wdata_ok   )
    );

    // IF part
    wire        stop;
    wire        j_token;
    wire        op_eret;
    wire        int_exc;
    wire        load_forward;
    wire        id_allowin;

    wire        if_to_id_valid;
    wire        if_id_stage_o;

    wire [31:0] id_next_pc_o;

    wire [31:0] pc_add_4; 
    wire [31:0] if_pc_o;
    wire [31:0] if_pc_add4_o;
    wire [31:0] if_inst_o;

    wire        if_exc_o;
    wire [ 5:0] if_excode_o;

    IF if_part (
        .clk            (clk             ),
        .resetn         (resetn          ),
        .int_exc        (int_exc         ),

        .stop           (stop            ),
        .load_forward   (load_forward    ),
        .j_token        (j_token         ),
        .op_eret        (op_eret         ),
        .id_allowin     (id_allowin      ),

        .irom_inst_i    (inst_sram_rdata ),
        .inst_sram_ok   (inst_sram_ok    ),
        .id_next_pc_i   (id_next_pc_o    ),

        .if_to_id_valid (if_to_id_valid  ),
        .if_id_stage_o  (if_id_stage_o   ),

        .inst_ren       (inst_sram_en    ),
        .irom_pc_o      (inst_sram_addr  ),
        
        .pc_add_4       (pc_add_4        ),

        .if_pc_o        (if_pc_o         ),
        .if_pc_add4_o   (if_pc_add4_o    ),
        .if_inst_o      (if_inst_o       ),

        .if_exc_o       (if_exc_o        ),
        .if_excode_o    (if_excode_o     )
    );

    // ID part

    wire        ex_allowin;

    wire        wb_wen;
    wire [ 4:0] wb_waddr;
    wire [31:0] wb_wdata;

    wire [ 2:0] forwardA;
    wire [ 2:0] forwardB;
    wire [31:0] ex_address_o;
    wire [31:0] for_ex_wdata;
    wire [31:0] read_data_o;
    wire [31:0] load_data_o;
    
    wire [31:0] epc_value;

    wire        id_to_ex_valid;
    wire        id_ex_stage_o;

    wire [11:0] id_wb_ctrl;

    wire [31:0] id_pc_o;
    wire [31:0] id_inst_o;
    wire [19:0] id_exe_ctrl_o;
    wire [10:0] id_mem_ctrl_o;
    wire [11:0] id_wb_ctrl_o;
    wire [31:0] id_ext_imm_o;
    wire [31:0] id_rdata1_o;
    wire [31:0] id_rdata2_o;
    wire [ 4:0] id_waddr_o;

    wire        id_rs_bd_o;
    wire [ 1:0] id_exc_o;
    wire [11:0] id_excode_o;

    wire [ 4:0] for_SrcA;
    wire [ 4:0] for_SrcB;

    ID id_part (
        .clk            (clk             ),
        .resetn         (resetn          ),
        .id_stage       (if_id_stage_o   ),
        .int_exc        (int_exc         ),

        .stop           (stop            ),
        .if_to_id_valid (if_to_id_valid  ),
        .ex_allowin     (ex_allowin      ),

        .if_exc         (if_exc_o        ),
        .if_excode      (if_excode_o     ),

        .id_pc_i        (if_pc_o         ),
        .id_pc_add4_i   (if_pc_add4_o    ),
        .id_inst_i      (if_inst_o       ),

        .wb_wen         (wb_wen          ),
        .wb_waddr       (wb_waddr        ),
        .wb_wdata       (wb_wdata        ),

        .forwardA       (forwardA        ),
        .forwardB       (forwardB        ),
        .ex_wdata       (for_ex_wdata    ),
        .me_wdata       (ex_address_o    ),
        .load_data      (load_data_o     ),
        
        .epc_value      (epc_value       ),

        .id_allowin     (id_allowin      ),
        .id_to_ex_valid (id_to_ex_valid  ),
        .id_ex_stage_o  (id_ex_stage_o   ),

        .wb_ctrl        (id_wb_ctrl      ),

        .j_token        (j_token         ),
        .id_pc_o        (id_pc_o         ),
        .id_inst_o      (id_inst_o       ),
        .id_next_pc_o   (id_next_pc_o    ),
        .id_exe_ctrl_o  (id_exe_ctrl_o   ),
        .id_mem_ctrl_o  (id_mem_ctrl_o   ),
        .id_wb_ctrl_o   (id_wb_ctrl_o    ),

        .id_ext_imm_o   (id_ext_imm_o    ),
        .id_rdata1_o    (id_rdata1_o     ),
        .id_rdata2_o    (id_rdata2_o     ),
        .id_waddr_o     (id_waddr_o      ),

        .id_rs_bd_o     (id_rs_bd_o      ),
        .id_exc_o       (id_exc_o        ),
        .id_excode_o    (id_excode_o     ),

        .op_eret        (op_eret         ),
        
        .for_SrcA       (for_SrcA        ),
        .for_SrcB       (for_SrcB        )
    );
  
    // EX part
    wire        me_allowin;
    wire        me_ex_stall;

    wire [31:0] ex_HI_i;
    wire [31:0] ex_LO_i;
    
    wire        ex_rs_bd_o;

    wire        ex_to_me_valid;
    wire        ex_me_stage_o;

    wire [ 1:0] mul_ctrl_o;
    wire [ 1:0] div_ctrl_o;
    wire [31:0] ex_pc_o;
    wire [31:0] ex_inst_o;
    wire [10:0] ex_mem_ctrl_o;
    wire [11:0] ex_wb_ctrl_o;
    wire [ 4:0] ex_waddr_o;
    wire [31:0] ex_write_data_o;
    wire [ 2:0] ex_exc_o;
    wire [17:0] ex_excode_o;

    wire [31:0] ex_HI_o;
    wire [31:0] ex_LO_o;

    wire [31:0] ex_rdata1_o;
    wire [31:0] ex_rdata2_o;

    EX ex_part (
        .clk             (clk             ),
        .resetn          (resetn          ),
        .ex_stage        (id_ex_stage_o   ),
        .int_exc         (int_exc         ),

        .id_to_ex_valid  (id_to_ex_valid  ),
        .me_allowin      (me_allowin      ),
        .me_ex_stall     (me_ex_stall     ),

        .id_exc          (id_exc_o        ),
        .id_excode       (id_excode_o     ),
        
        .ex_rs_bd_i      (id_rs_bd_o      ),
        .ex_pc_i         (id_pc_o         ),
        .ex_inst_i       (id_inst_o       ),
        .ex_exe_ctrl_i   (id_exe_ctrl_o   ),
        .ex_mem_ctrl_i   (id_mem_ctrl_o   ),
        .ex_wb_ctrl_i    (id_wb_ctrl_o    ),
        .ex_ext_imm_i    (id_ext_imm_o    ),
        .ex_rdata1_i     (id_rdata1_o     ),
        .ex_rdata2_i     (id_rdata2_o     ),
        .ex_waddr_i      (id_waddr_o      ),
        .ex_HI_i         (ex_HI_i         ),
        .ex_LO_i         (ex_LO_i         ),

        .ex_allowin      (ex_allowin      ),
        .ex_to_me_valid  (ex_to_me_valid  ),
        .ex_me_stage_o   (ex_me_stage_o   ),

        .mul_ctrl_o      (mul_ctrl_o      ),
        .div_ctrl_o      (div_ctrl_o      ),
        .ex_pc_o         (ex_pc_o         ),
        .ex_inst_o       (ex_inst_o       ),
        .ex_mem_ctrl_o   (ex_mem_ctrl_o   ),
        .ex_wb_ctrl_o    (ex_wb_ctrl_o    ),
        .ex_waddr_o      (ex_waddr_o      ),
        .ex_address_o    (ex_address_o    ),
        .ex_write_data_o (ex_write_data_o ),
        .ex_exc_o        (ex_exc_o        ),
        .ex_excode_o     (ex_excode_o     ),
        .ex_rs_bd_o      (ex_rs_bd_o      ),

        .ex_HI_o         (ex_HI_o         ),
        .ex_LO_o         (ex_LO_o         ),

        .ex_rdata1_o     (ex_rdata1_o     ),
        .ex_rdata2_o     (ex_rdata2_o     ),
        .ex_ALUout_o     (for_ex_wdata    )
    );

    // MEM part

    wire        me_wb_stage_o;
    wire        me_rs_bd_o;

    wire [ 3:0] me_exc_o;
    wire [23:0] me_excode_o;

    wire [31:0] me_pc_o;
    wire [31:0] me_inst_o;
    wire [11:0] me_wb_ctrl_o;
    wire [ 4:0] me_waddr_o;
    wire [31:0] me_ALUout_o;
    wire [31:0] me_rdata2_o;

    wire [31:0] me_HI_o;
    wire [31:0] me_LO_o;

    MEM mem_part (
        .clk             (clk             ),
        .resetn          (resetn          ),
        .me_stage        (ex_me_stage_o   ),
        .int_exc         (int_exc         ),

        .me_rs_bd_i      (ex_rs_bd_o      ),
        .ex_to_me_valid  (ex_to_me_valid  ),
        .me_pc_i         (ex_pc_o         ),
        .me_inst_i       (ex_inst_o       ),
        .me_mem_ctrl_i   (ex_mem_ctrl_o   ),
        .me_wb_ctrl_i    (ex_wb_ctrl_o    ),
        .me_waddr_i      (ex_waddr_o      ),
        .me_address_i    (ex_address_o    ),
        .me_write_data_i (ex_write_data_o ),
        .ex_exc          (ex_exc_o        ),
        .ex_excode       (ex_excode_o     ),

        .me_HI_i         (ex_HI_o         ),
        .me_LO_i         (ex_LO_o         ),

        .read_data_i     (data_sram_rdata ),
        .data_sram_ok    (data_sram_ok    ),

        .me_allowin      (me_allowin      ),
        .me_ex_stall     (me_ex_stall     ),
        .me_wb_stage_o   (me_wb_stage_o   ),

        .me_exc_o        (me_exc_o        ),
        .me_excode_o     (me_excode_o     ),

        .me_pc_o         (me_pc_o         ),
        .me_inst_o       (me_inst_o       ),
        .me_wb_ctrl_o    (me_wb_ctrl_o    ),
        .me_waddr_o      (me_waddr_o      ),
        .me_ALUout_o     (me_ALUout_o     ),
        .me_rdata2_o     (me_rdata2_o     ),
        .load_data_o     (load_data_o     ),
        .me_rs_bd_o      (me_rs_bd_o      ),

        .me_HI_o         (me_HI_o         ),
        .me_LO_o         (me_LO_o         ),

        .address_o       (data_sram_addr  ),
        .data_wen        (data_sram_wen   ),
        .write_data_o    (data_sram_wdata ),
        .data_ren        (data_sram_en    ),
        .data_rsize      (data_sram_rsize ),
        .read_data_o     (read_data_o     )
    );

    // WB part

    WB wb_part (
        .clk        (clk           ),
        .resetn     (resetn        ),
        .wb_stage   (me_wb_stage_o ),

        .hw_int     (~{7'b111_1111}),

        .me_exc     (me_exc_o      ),
        .me_excode  (me_excode_o   ),
        
        .wb_rs_bd   (me_rs_bd_o    ),
        .wb_pc_i    (me_pc_o       ),
        .wb_inst_i  (me_inst_o     ),
        
        .wb_ctrl    (me_wb_ctrl_o  ),
        .wb_dst_i   (me_waddr_o    ),
        .wb_HI_i    (me_HI_o       ),
        .wb_LO_i    (me_LO_o       ),
        .read_data  (read_data_o   ),
        .ALU_result (me_ALUout_o   ),
        .wb_rdata2_i(me_rdata2_o   ),

        .op_eret    (op_eret       ),

        .int_exc    (int_exc       ),
        .epc_value  (epc_value     ),

        .wb_wen     (wb_wen        ),
        .wb_waddr   (wb_waddr      ),
        .wb_wdata   (wb_wdata      )
    );

    // forward unit

    wire [2:0] for_load_i;
    wire [4:0] for_ex_dst;
    wire [4:0] for_me_dst;
    wire [4:0] for_wb_dst;
    wire       for_mtc0_i;
    wire       for_mthilo;

    assign for_load_i = {id_wb_ctrl_o[1], ex_wb_ctrl_o[1], me_wb_ctrl_o[1]};
    assign for_ex_dst = id_waddr_o & {5{id_wb_ctrl_o[0] & id_ex_stage_o}};
    assign for_me_dst = ex_waddr_o & {5{ex_wb_ctrl_o[0] & ex_me_stage_o}};
    assign for_wb_dst = wb_waddr & {5{me_wb_ctrl_o[0] & me_wb_stage_o}};

    assign for_mtc0_i = id_wb_ctrl_o[5] & id_ex_stage_o | ex_wb_ctrl_o[5] & ex_me_stage_o 
                      | me_wb_ctrl_o[5] & me_wb_stage_o | for_mthilo;

    assign for_mthilo = (id_wb_ctrl_o[11] | (|id_wb_ctrl_o[8:7])) & id_ex_stage_o 
                      | (ex_wb_ctrl_o[11] | (|ex_wb_ctrl_o[8:7])) & ex_me_stage_o 
                      | (me_wb_ctrl_o[11] | (|me_wb_ctrl_o[8:7])) & me_wb_stage_o;

    forward forward_unit(
        .clk          (clk             ),
        .resetn       (resetn          ),

        .ALUSrcA      (for_SrcA        ),
        .ALUSrcB      (for_SrcB        ),
        .mem_load     (for_load_i      ),
        .op_mtc0      (for_mtc0_i      ),
        .ex_dst       (for_ex_dst      ),
        .me_dst       (for_me_dst      ),
        .wb_dst       (for_wb_dst      ),

        .forwardA     (forwardA        ),
        .forwardB     (forwardB        ),
        .load_forward (load_forward    )
    );

    // mul & div part

    wire [63:0] mul_result;
    wire        mul_completed;
    wire        mul;
    wire        mul_signed;
    
    assign mul = (mul_ctrl_o[1] | mul_ctrl_o[0]) & id_ex_stage_o;
    assign mul_signed = !mul_ctrl_o[0] & id_ex_stage_o;

    multi mul_unit(
        .mul_clk    (clk           ),
        .resetn     (resetn        ),
        .mul        (mul           ),
        .mul_signed (mul_signed    ),
        .x          (ex_rdata1_o   ),
        .y          (ex_rdata2_o   ),

        .result     (mul_result    ),
        .complete   (mul_completed )
    );

    wire [31:0] div_quotient;
    wire [31:0] div_remainder;
    wire        div_completed;
    wire        div;
    wire        div_signed;
        
    assign div = (div_ctrl_o[1] | div_ctrl_o[0]) & id_ex_stage_o;
    assign div_signed = !div_ctrl_o[0] & id_ex_stage_o;

    div div_unit(
        .div_clk    (clk           ),
        .resetn     (resetn        ),
        .div        (div           ),
        .div_signed (div_signed    ),
        .x          (ex_rdata1_o   ),
        .y          (ex_rdata2_o   ),

        .s          (div_quotient  ),
        .r          (div_remainder ),
        .complete   (div_completed )
    );

    assign stop = (div & !div_completed) | (mul & !mul_completed);

    assign ex_HI_i = mul_completed ? mul_result[63:32] :
                     div_completed ? div_remainder     : 
                 id_exe_ctrl_o[12] ? ex_rdata1_o       : 32'd0;
    assign ex_LO_i = mul_completed ? mul_result[31: 0] :
                     div_completed ? div_quotient      : 
                 id_exe_ctrl_o[11] ? ex_rdata1_o       : 32'd0;

    // debug part

    assign debug_wb_rf_wen   = {4{wb_wen}};
    assign debug_wb_rf_wnum  = wb_waddr;
    assign debug_wb_rf_wdata = wb_wdata;
    assign debug_wb_pc       = me_pc_o;

endmodule