// Project: General_purpose_reg_file
// Author: Zhang Ningxin

module reg_file(
	input clk,
	input resetn,
	input [4:0] waddr,
	input [4:0] raddr1,
	input [4:0] raddr2,
	input wen,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);

	reg [31:0] gp_reg [31:0];  //General purpose register
	integer i; 

	always@(posedge clk)
	begin
		if (!resetn) 
            for (i = 0; i < 32; i=i+1) gp_reg[i]<=0;
		else if(wen && (waddr!=0))
			gp_reg[waddr]<= wdata;
		else
			;
	end

	assign rdata1=gp_reg[raddr1];
	assign rdata2=gp_reg[raddr2];

	
endmodule