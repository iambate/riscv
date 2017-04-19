module RegisterFile
#(
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  REGISTERNO_WIDTH = 5,
  INSTRUCTION_WIDTH = 32
)
(
  input clk,
  input reset,
  input in_wr_enable,
  input display_regs,
  input [REGISTERNO_WIDTH-1:0] in_rs1_regno,
  input [REGISTERNO_WIDTH-1:0] in_rs2_regno,
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input [REGISTER_WIDTH-1:0] in_rd_value,
  output [REGISTER_WIDTH-1:0] out_rs1_value,
  output [REGISTER_WIDTH-1:0] out_rs2_value
);
  reg[REGISTER_WIDTH -1:0] Registers[32];

  always_comb begin
    if(in_rs1_regno >= 'd0 && in_rs1_regno <= 'd31) begin
      assign out_rs1_value = Registers[in_rs1_regno];
    end
    else begin
      assign out_rs1_value = 'd0;
    end
    if(in_rs2_regno >= 'd0 && in_rs2_regno <= 'd31) begin
      assign out_rs2_value = Registers[in_rs2_regno];
    end
    else begin
      assign out_rs2_value = 'd0;
    end
  end

  always_ff @(posedge clk) begin
    if(reset) begin
      Registers[31:0]='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    end
    else if(in_wr_enable) begin
      $display("Writing Register: %d with content %d", in_rd_regno, in_rd_value);
      Registers[in_rd_regno] <= in_rd_value;
    end
    else if(display_regs) begin
      int i;
      for(i=0;i<32;i++)
        $display("Register %0d:\t%0d",i, Registers[i]);
      $display("");
      //$finish;
    end
  end
endmodule
