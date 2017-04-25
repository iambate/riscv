`include "RegisterFile.sv"
`define DECODE_DEBUG
module decode
#(
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  IMMEDIATE_WIDTH = 32,
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
  input in_branch_taken_bool,
  input in_display_regs,
  input in_syscall_flush,
  output [ADDRESS_WIDTH-1:0] out_pcplus1,
  output [REGISTER_WIDTH-1:0] out_rs1_value,
  output [REGISTER_WIDTH-1:0] out_rs2_value,
  output [REGISTER_WIDTH-1:0] out_imm_value,
  output [REGISTERNO_WIDTH-1:0] out_rs1_regno,
  output [REGISTERNO_WIDTH-1:0] out_rs2_regno,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [REGISTER_WIDTH-1:0] out_a0,
  output [REGISTER_WIDTH-1:0] out_a1,
  output [REGISTER_WIDTH-1:0] out_a2,
  output [REGISTER_WIDTH-1:0] out_a3,
  output [REGISTER_WIDTH-1:0] out_a4,
  output [REGISTER_WIDTH-1:0] out_a5,
  output [REGISTER_WIDTH-1:0] out_a6,
  output [REGISTER_WIDTH-1:0] out_a7,
  output [INSTRUCTION_NAME_WIDTH-1:0] out_opcode_name,
  output out_ready
);
  logic [REGISTER_NAME_WIDTH-1:0] n_rs1_name;
  logic [REGISTER_NAME_WIDTH-1:0] n_rs2_name;
  logic [REGISTER_NAME_WIDTH-1:0] n_rd_name;
  logic [REGISTER_WIDTH-1:0] n_rs1_value;
  logic [REGISTER_WIDTH-1:0] n_rs2_value;
  logic signed [IMMEDIATE_WIDTH-1:0] n_imm_value;
  logic [REGISTERNO_WIDTH-1:0] n_rs1_regno;
  logic [REGISTERNO_WIDTH-1:0] n_rs2_regno;
  logic [REGISTERNO_WIDTH-1:0] n_rd_regno;
  logic [INSTRUCTION_NAME_WIDTH-1:0] n_opcode_name;
  logic unsigned [FLAG_WIDTH-1:0] n_flag;

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
                    .out_rs2_value(n_rs2_value),
                    .out_a0(out_a0),
                    .out_a1(out_a1),
                    .out_a2(out_a2),
                    .out_a3(out_a3),
                    .out_a4(out_a4),
                    .out_a5(out_a5),
                    .out_a6(out_a6),
                    .out_a7(out_a7)
                   );


  always_comb begin
    // There is no reason for now that decode can't be ready
    assign out_ready = 1;
  end
  always_ff @(posedge clk) begin
    if(in_syscall_flush) begin
      $display("DECODE flushed due to syscall_flush signal");
      out_pcplus1 <= 0;
      out_rs1_value <= 0;
      out_rs2_value <= 0;
      out_rs1_regno <= 0;
      out_rs2_regno <= 0;
      out_rd_regno <= 0;
      out_imm_value <= 0;
      out_opcode_name <= 0;
    end else if(in_decode_enable) begin
      if(in_branch_taken_bool) begin
        // If branch taken then flush and send nop instruction
        $display("DECODE flushed due to branch taken");
        out_pcplus1 <= 0;
        out_rs1_value <= 0;
        out_rs2_value <= 0;
        out_rs1_regno <= 0;
        out_rs2_regno <= 0;
        out_rd_regno <= 0;
        out_imm_value <= 0;
        out_opcode_name <= 0;
      end else begin
`ifdef DECODE_DEBUG
        $display("DECODE pc %x", in_pcplus1);
        $display("DECODE rs1 val %d", n_rs1_value);
        $display("DECODE rs2 val %d", n_rs2_value);
        $display("DECODE rs1 name %s", n_rs1_name);
        $display("DECODE rs2 name %s", n_rs2_name);
        $display("DECODE rd name %s", n_rd_name);
        $display("DECODE rs1 regno %d", n_rs1_regno);
        $display("DECODE rs2 regno %d", n_rs2_regno);
        $display("DECODE rd regno %d", n_rd_regno);
        $display("DECODE imm value %d", n_imm_value);
        $display("DECODE opcode name %s", n_opcode_name);
`endif
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
  end
endmodule
