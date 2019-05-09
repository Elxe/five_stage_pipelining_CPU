// Project: cpu_axi_interface
// Author: Zhang Ningxin

module cpu_axi_interface (
    input         clk,
    input         resetn,

    //inst sram-like 
    input         inst_req,
    input         inst_wr,
    input  [ 1:0] inst_size,
    input  [31:0] inst_addr,
    input  [31:0] inst_wdata,
    output [31:0] inst_rdata,
    output        inst_addr_ok,
    output        inst_data_ok,
    
    //data sram-like 
    input         data_req,
    input         data_wr,
    input  [ 1:0] data_size,
    input  [ 3:0] data_strb,
    input  [31:0] data_addr,
    input  [31:0] data_wdata,
    output [31:0] data_rdata,
    
    output        data_raddr_ok,
    output        data_waddr_ok,
    output        data_rdata_ok,
    output        data_wdata_ok,

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
    input  [ 1:0] bresp, // ignore
    input         bvalid,
    output        bready
);

    assign arid    = 4'd0;
    assign arlen   = 8'd0;
    assign arburst = 2'b01;
    assign arlock  = 2'd0;
    assign arcache = 4'd0;
    assign arprot  = 3'd0;

    assign awid    = 4'd1;
    assign awlen   = 8'd0;
    assign awburst = 2'b01;
    assign awlock  = 2'd0;
    assign awcache = 4'd0;
    assign awprot  = 3'd0;

    assign wid     = 1'b1;
    assign wlast   = 1'b1;

    wire inst_read, inst_write, data_read, data_write;

    assign inst_read  = inst_req & (inst_wr == 1'b0);
    assign inst_write = inst_req & (inst_wr == 1'b1);
    assign data_read  = data_req & (data_wr == 1'b0);
    assign data_write = data_req & (data_wr == 1'b1);

    reg rreq_reg, rreq_reg_s;
    reg wreq_reg;

    reg [ 1:0] rsize_reg;
    reg [31:0] raddr_reg;

    reg [ 1:0] wsize_reg;
    reg [ 3:0] wstrb_reg;
    reg [31:0] waddr_reg;
    reg [31:0] wdata_reg;

    wire rdata_ok, wdata_ok;

    // read
    always@(posedge clk)
    begin
        if (!resetn)
        begin
            rreq_reg   <=  1'b0;
            rreq_reg_s <=  1'b0;
            rsize_reg  <=  2'd0;
            raddr_reg  <= 32'd0;
        end
        else 
        begin
            if ((inst_read || data_read) && !rreq_reg)
                rreq_reg <= 1'b1;
            else if (rdata_ok)
                rreq_reg <= 1'b0;

            if (!rreq_reg)
                rreq_reg_s <= inst_read;

            if (data_read && data_raddr_ok)
            begin
                rsize_reg  <= data_size;
                raddr_reg  <= data_addr;
            end
            else if (inst_read && inst_addr_ok)
            begin
                rsize_reg  <= inst_size;
                raddr_reg  <= inst_addr;
            end
        end
    end

    // write
    always@(posedge clk)
    begin
        if (!resetn)
        begin
            wreq_reg   <=  1'b0;
            wsize_reg  <=  2'd0;
            wstrb_reg  <=  4'd0;
            waddr_reg  <= 32'd0;
            wdata_reg  <= 32'd0;
        end
        else 
        begin
            if (data_write && !wreq_reg)
                wreq_reg <= 1'b1;
            else if (wdata_ok)
                wreq_reg <= 1'b0;

            if (data_write && data_waddr_ok)
            begin
                wsize_reg  <= data_size;
                wstrb_reg  <= data_strb;
                waddr_reg  <= data_addr;
                wdata_reg  <= data_wdata;
            end
        end
    end

    assign inst_addr_ok = !rreq_reg & inst_read & !data_read;
    assign inst_data_ok = rreq_reg & rreq_reg_s & rdata_ok;
    assign data_raddr_ok = !rreq_reg & data_read;
    assign data_waddr_ok = !wreq_reg & data_write;
    assign data_rdata_ok = rreq_reg & rdata_ok;
    assign data_wdata_ok =  wreq_reg & wdata_ok;

    assign inst_rdata = rdata;
    assign data_rdata = rdata;

    reg raddr_rcv, waddr_rcv, wdata_rcv;

    assign rdata_ok = raddr_rcv & (rvalid & rready);
    assign wdata_ok = waddr_rcv & (bvalid & bready);

    always@(posedge clk)
    begin
        if (!resetn)
        begin
            raddr_rcv <= 1'b0;
            waddr_rcv <= 1'b0;
            wdata_rcv <= 1'b0;
        end
        else 
        begin
            if (arvalid && arready)
                raddr_rcv <= 1'b1;
            else if (rdata_ok)
                raddr_rcv <= 1'b0;

            if (awvalid && awready)
                waddr_rcv <= 1'b1;
            else if (wdata_ok)
                waddr_rcv <= 1'b0;
            
            if (wvalid && wready)
                wdata_rcv <= 1'b1;
            else if (wdata_ok)
                wdata_rcv <= 1'b0;
        end
    end

    assign araddr  = raddr_reg;
    assign arsize  = rsize_reg;
    assign arvalid = rreq_reg & !raddr_rcv;

    assign rready  = 1'b1;

    assign awaddr  = waddr_reg;
    assign awsize  = wsize_reg;
    assign awvalid = wreq_reg & !waddr_rcv;

    assign wdata   = wdata_reg;
    assign wstrb   = wstrb_reg;
    assign wvalid  = wreq_reg & !wdata_rcv;

    assign bready  = 1'b1;

endmodule