// Project: interface
// Author: Zhang Ningxin

module interface(
    input         clk,
    input         resetn,

    input         inst_sram_en,
    input  [ 3:0] inst_sram_wen,
    input  [31:0] inst_sram_addr,
    input  [31:0] inst_sram_wdata,
    output [31:0] inst_sram_rdata,
    output        inst_sram_ok,
    
    input         data_sram_en,
    input  [ 1:0] data_sram_rsize,
    input  [ 3:0] data_sram_wen,
    input  [31:0] data_sram_addr,
    input  [31:0] data_sram_wdata,
    output [31:0] data_sram_rdata,
    output        data_sram_ok,

    //----inst sram-like----
    output        inst_req,
    output        inst_wr,
    output [ 1:0] inst_size,
    output [31:0] inst_addr,
    output [31:0] inst_wdata,
    input  [31:0] inst_rdata,
    input         inst_addr_ok,
    input         inst_data_ok,
    
    //----data sram-like----
    output         data_req,
    output         data_wr,
    output  [ 1:0] data_size,
    output  [ 3:0] data_strb,
    output  [31:0] data_addr,
    output  [31:0] data_wdata,
    input   [31:0] data_rdata,
    input          data_raddr_ok,
    input          data_waddr_ok,
    input          data_rdata_ok,
    input          data_wdata_ok
);

    wire if_exc = (inst_sram_addr[1:0] != 2'b00);

    reg  instr_rcv;
    wire datar_req = data_req & !data_wr | datar_rcv;

    assign inst_req = inst_sram_en & !instr_rcv & !if_exc;

    always@(posedge clk)
    begin
        if (!resetn)
            instr_rcv <= 1'b0;
        else if (inst_req && inst_addr_ok)
            instr_rcv <= 1'b1;
        else if (inst_data_ok)
            instr_rcv <= 1'b0;
    end

    reg datar_rcv;
    reg dataw_rcv;
    reg wr_state;

    assign data_req = data_sram_en & !datar_rcv;

    always@(posedge clk)
    begin
        if (!resetn)
            datar_rcv <= 1'b0;
        else if (data_req && data_raddr_ok && !wr_state)
            datar_rcv <= 1'b1;
        else if (data_rdata_ok && !dataw_rcv)
            datar_rcv <= 1'b0;

        if (!resetn)
            dataw_rcv <= 1'b0;
        else if (data_req && data_waddr_ok && wr_state)
            dataw_rcv <= 1'b1;
        else if (data_wdata_ok)
            dataw_rcv <= 1'b0;
    end

    always@(posedge clk)
    begin
        if (!resetn) 
            wr_state <= 1'b0;
        else if (data_sram_en)
            wr_state <= data_wr;
    end

    assign inst_sram_rdata = inst_rdata;
    assign inst_sram_ok = (instr_rcv & inst_data_ok & !datar_rcv) | if_exc;
    assign data_sram_rdata = data_rdata;
    assign data_sram_ok = datar_rcv & !dataw_rcv & data_rdata_ok 
                        | dataw_rcv & !datar_rcv & data_wdata_ok & !(data_sram_en & !data_wr); 

    assign inst_wr = 1'b0;
    assign inst_size = 2'd2;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'd0;
    
    assign data_wr = |data_sram_wen;
    assign data_size = (data_sram_wen == 4'b0001) ? 2'd0 :
                       (data_sram_wen == 4'b0011) ? 2'd1 : 
                       (data_sram_wen == 4'b0000) ? data_sram_rsize : 2'd2;
    assign data_strb = data_sram_wen;
    assign data_addr = data_sram_addr;
    assign data_wdata = data_sram_wdata;

endmodule