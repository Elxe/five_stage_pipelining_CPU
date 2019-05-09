// Project: forward unit
// Author: Zhang Ningxin

module forward (
	input        clk,
	input        resetn,

	input  [4:0] ALUSrcA,
	input  [4:0] ALUSrcB,
	input  [2:0] mem_load,
  input        op_mtc0,
	input  [4:0] ex_dst,
  input  [4:0] me_dst,
  input  [4:0] wb_dst,

	output [2:0] forwardA,
	output [2:0] forwardB,

	output       load_forward
);

    wire [5:0] for_SrcA;
    wire [5:0] for_SrcB;

    assign for_SrcA[0] = !resetn ? 1'b0 : (ALUSrcA == ex_dst && ex_dst != 'd0 && mem_load[2] == 1'b0);
    assign for_SrcA[1] = !resetn ? 1'b0 : (ALUSrcA == me_dst && me_dst != 'd0 && mem_load[1] == 1'b0);
    assign for_SrcA[2] = !resetn ? 1'b0 : (ALUSrcA == wb_dst && wb_dst != 'd0 && mem_load[0] == 1'b0);
    assign for_SrcA[3] = !resetn ? 1'b0 : (ALUSrcA == ex_dst && ex_dst != 'd0 && mem_load[2] == 1'b1);
    assign for_SrcA[4] = !resetn ? 1'b0 : (ALUSrcA == me_dst && me_dst != 'd0 && mem_load[1] == 1'b1);
    assign for_SrcA[5] = !resetn ? 1'b0 : (ALUSrcA == wb_dst && wb_dst != 'd0 && mem_load[0] == 1'b1);

    assign for_SrcB[0] = !resetn ? 1'b0 : (ALUSrcB == ex_dst && ex_dst != 'd0 && mem_load[2] == 1'b0);
    assign for_SrcB[1] = !resetn ? 1'b0 : (ALUSrcB == me_dst && me_dst != 'd0 && mem_load[1] == 1'b0);
    assign for_SrcB[2] = !resetn ? 1'b0 : (ALUSrcB == wb_dst && wb_dst != 'd0 && mem_load[0] == 1'b0);
    assign for_SrcB[3] = !resetn ? 1'b0 : (ALUSrcB == ex_dst && ex_dst != 'd0 && mem_load[2] == 1'b1);
    assign for_SrcB[4] = !resetn ? 1'b0 : (ALUSrcB == me_dst && me_dst != 'd0 && mem_load[1] == 1'b1);
    assign for_SrcB[5] = !resetn ? 1'b0 : (ALUSrcB == wb_dst && wb_dst != 'd0 && mem_load[0] == 1'b1);

    assign forwardA = for_SrcA[0] ? 3'd1 :
                      for_SrcA[1] ? 3'd2 :
                      for_SrcA[2] ? 3'd3 :
                      for_SrcA[3] ? 3'd4 :
                      for_SrcA[4] ? 3'd5 :
                      for_SrcA[5] ? 3'd6 : 3'd0;

    assign forwardB = for_SrcB[0] ? 3'd1 :
                      for_SrcB[1] ? 3'd2 :
                      for_SrcB[2] ? 3'd3 :
                      for_SrcB[3] ? 3'd4 :
                      for_SrcB[4] ? 3'd5 :
                      for_SrcB[5] ? 3'd6 : 3'd0;
    
    assign load_forward = for_SrcA[3] | for_SrcA[4] | for_SrcA[5] | for_SrcB[3] | for_SrcB[4] | for_SrcB[5] | op_mtc0;

endmodule 