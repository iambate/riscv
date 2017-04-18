`include "RegisterFile.sv"

module Decode
#(
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  REGISTERNO_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4*8,
  INSTRUCTION_WIDTH = 32,
  INSTRUCTION_NAME_WIDTH = 12*8,
  FLAG_WIDTH = 16
)
(
  input clk,
  input reset,
  input in_decode_enable,
  input [ADDRESS_WIDTH-1:0] in_pcplus1,
  input [INSTRUCTION_WIDTH-1:0] in_instruction_bits,
  input [REGISTER_WIDTH-1:0] in_wb_rd_value,
  input [REGISTERNO_WIDTH-1:0] in_wb_rd_regno,
  input in_wb_enable,
  input in_display_regs,
  output [ADDRESS_WIDTH-1:0] out_pcplus1,
  output [REGISTER_WIDTH-1:0] out_rs1_value,
  output [REGISTER_WIDTH-1:0] out_rs2_value,
  output [REGISTER_WIDTH-1:0] out_imm_value,
  output [REGISTERNO_WIDTH-1:0] out_rs1_regno,
  output [REGISTERNO_WIDTH-1:0] out_rs2_regno,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [INSTRUCTION_NAME_WIDTH-1:0] out_opcode_name,
  output out_ready
);
  logic [REGISTER_NAME_WIDTH-1:0] n_rs1_name;
  logic [REGISTER_NAME_WIDTH-1:0] n_rs2_name;
  logic [REGISTER_NAME_WIDTH-1:0] n_rd_name;
  logic [REGISTER_WIDTH-1:0] n_rs1_value;
  logic [REGISTER_WIDTH-1:0] n_rs2_value;
  logic [REGISTER_WIDTH-1:0] n_imm_value;
  logic [REGISTERNO_WIDTH-1:0] n_rs1_regno;
  logic [REGISTERNO_WIDTH-1:0] n_rs2_regno;
  logic [REGISTERNO_WIDTH-1:0] n_rd_regno;
  logic [INSTRUCTION_NAME_WIDTH-1:0] n_opcode_name;
  logic [FLAG_WIDTH-1:0] n_flag;

  // Get the register no, instruction opcode name,immediate value
  // from process_instrcution module instantiation
  process_instruction pi0  (.instruction(in_instruction_bits),
                            .rs1(n_rs1_name),
                            .rs2(n_rs2_name),
                            .rd(n_rd_name),
                            .rs1_number(n_rs1_regno),
                            .rs2_number(n_rs2_regno),
                            .rd_number(n_rd_regno),
                            .imm(n_imm_value),
                            .flag(n_flag),
                            .instruction_name(n_opcode_name)
                           );

  // Get the register content from register file and write to register file
  // if writeback stage says wb_enable
  RegisterFile rf0 (.clk(clk),
                    .reset(reset),
                    .in_wr_enable(in_wb_enable),
                    .display_regs(in_display_regs),
                    .in_rs1_regno(n_rs1_regno),
                    .in_rs2_regno(n_rs2_regno),
                    .in_rd_regno(in_wb_rd_regno),
                    .in_rd_value(in_wb_rd_value),
                    .out_rs1_value(n_rs1_value),
                    .out_rs2_value(n_rs2_value)
                   );


  always_comb begin
    // There is no reason for now that decode can't be ready
    assign out_ready = 1;
  end
  always_ff @(posedge clk) begin
    if(in_decode_enable) begin
      out_pcplus1 <= in_pcplus1;
      out_rs1_value <= n_rs1_value;
      out_rs2_value <= n_rs2_value;
      out_rs1_regno <= n_rs1_regno;
      out_rs2_regno <= n_rs2_regno;
      out_rd_regno <= n_rd_regno;
      out_imm_value <= n_imm_value;
      out_opcode_name <= n_opcode_name;
    end
  end
endmodule
