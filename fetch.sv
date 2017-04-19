/*
 * TODO:
 * Add instruction cache module and respective buslines
 */
module Fetch
#(
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  INSTRUCTION_WIDTH = 32
)
(
  input clk,
  input reset,
  input in_branch_taken_taken,
  input [ADDRESS_WIDTH-1:0] in_target,
  input in_enable,
  output [ADDRESS_WIDTH-1:0] out_pcplus1,
  output [INSTRUCTION_WIDTH-1:0] out_instruction_bits,
  output out_ready
);
  logic [ADDRESS_WIDTH-1:0] old_pc;
  logic [ADDRESS_WIDTH-1:0] pc;
  logic [INSTRUCTION_WIDTH-1:0] cache_instruction_bits;
  logic cache_ready;

  // TODO: Instantiate Instruction Cache module

  always_comb begin
    // PC MUX
    if(in_branch_taken_bool) begin
      assign pc = in_target;
    end else begin
      assign pc = old_pc + 1;
    end

    // Decide to stall or not
    if(cache_ready) begin
      assign out_ready = 1;
    end else begin
      assign out_ready = 0;
    end
  end

  always_ff @ (posedge clk) begin
    if(reset) begin
      old_pc <= -1;
      out_instruction_bits <= 0;
      out_pcplus1 <= 0;
    end else if(out_ready && in_enable) begin
      $display("instruction bits %d", cache_instruction_bits);
      $display("this pc %d", pc);
      out_instruction_bits <= cache_instruction_bits;
      out_pcplus1 <= pc + 1;
      old_pc <= pc;
    end
  end
endmodule
