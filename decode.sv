//`include "process_instruction.sv"
`include "RegisterFile.sv"

module Decode
#(
  BUS_DATA_WIDTH = 64,
  TYPE_WIDTH = 3,
  REGISTER_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4,
  IMMEDIATE_WIDTH = 32,
  FLAG_WIDTH = 16,
  INSTRUCTION_NAME_WIDTH = 12
)
(
  input clk,
  input reset,
  input [BUS_DATA_WIDTH/2-1:0] stage1_instruction_bits,
  input [63:0] stage1_pc,
  output [63:0] nstage2_valA,//p-obtain from register file
  output [63:0] nstage2_valB,//p -assign 
  output [63:0] nstage2_immediate,
  output [63:0] nstage2_pc,
  output [4:0] nstage2_dest,//p-assign to rd_number only for certain instructions
  output [INSTRUCTION_NAME_WIDTH*8:0] nstage2_op,
  input [4:0] stage3_dest_reg,
  input [63:0] stage3_alu_result,
  input wr_en
);
  logic [REGISTER_NAME_WIDTH*8:0] rs1;
  logic [REGISTER_NAME_WIDTH*8:0] rs2;
  logic [REGISTER_NAME_WIDTH*8:0] rd;
  logic signed [IMMEDIATE_WIDTH-1:0] imm;
  logic unsigned [FLAG_WIDTH-1: 0] flag;
  logic [INSTRUCTION_NAME_WIDTH*8:0] instruction_name;
  logic [4:0] rd_number;
  logic [4:0] rs1_number;
  logic [4:0] rs2_number;
  process_instruction inst_1 (.instruction(stage1_instruction_bits), 
                              .rd(rd), .rs1(rs1), .rs2(rs2), .imm(imm), 
                              .flag(flag), .instruction_name(nstage2_op), 
                              .rd_number(rd_number), .rs1_number(rs1_number), .rs2_number(rs2_number));
  RegisterFile regfile(.stage1_rs1(rs1_number),
		       .stage1_rs2(rs2_number),
  		       .nstage_rs1_content(nstage2_valA),
		       .nstage_rs2_content(nstage2_valB),
		       .clk(clk),
		       .wr_en(wr_en),
		       .reset(reset),
		       .stage5_rd(stage3_dest_reg),
		       .stage5_result(stage3_alu_result));
  always_comb begin
     assign nstage2_pc = stage1_pc;
     assign nstage2_immediate = imm;
     assign nstage2_dest = rd_number;
  end
endmodule
