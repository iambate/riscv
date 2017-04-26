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
  input [REGISTER_WIDTH-1:0] in_stackptr,
  input [REGISTERNO_WIDTH-1:0] in_rs1_regno,
  input [REGISTERNO_WIDTH-1:0] in_rs2_regno,
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input [REGISTER_WIDTH-1:0] in_rd_value,
  output [REGISTER_WIDTH-1:0] out_rs1_value,
  output [REGISTER_WIDTH-1:0] out_rs2_value,
  output [REGISTER_WIDTH-1:0] out_a0,
  output [REGISTER_WIDTH-1:0] out_a1,
  output [REGISTER_WIDTH-1:0] out_a2,
  output [REGISTER_WIDTH-1:0] out_a3,
  output [REGISTER_WIDTH-1:0] out_a4,
  output [REGISTER_WIDTH-1:0] out_a5,
  output [REGISTER_WIDTH-1:0] out_a6,
  output [REGISTER_WIDTH-1:0] out_a7
);
  reg[REGISTER_WIDTH -1:0] Registers[32];

  always_comb begin
    assign out_a0 = Registers[10];
    assign out_a1 = Registers[11];
    assign out_a2 = Registers[12];
    assign out_a3 = Registers[13];
    assign out_a4 = Registers[14];
    assign out_a5 = Registers[15];
    assign out_a6 = Registers[16];
    assign out_a7 = Registers[17];
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
      Registers[0] <= 0;
      Registers[1] <= 0; //TODO: Figureout the correct value
      Registers[2] <= in_stackptr;
      Registers[3] <= 0;
      Registers[4] <= 0;
      Registers[5] <= 0;
      Registers[6] <= 0;
      Registers[7] <= 0;
      Registers[8] <= 0;
      Registers[9] <= 0;
      Registers[10] <= 0;
      Registers[11] <= 0;
      Registers[12] <= 0;
      Registers[13] <= 0;
      Registers[14] <= 0;
      Registers[15] <= 0;
      Registers[16] <= 0;
      Registers[17] <= 0;
      Registers[18] <= 0;
      Registers[19] <= 0;
      Registers[20] <= 0;
      Registers[21] <= 0;
      Registers[22] <= 0;
      Registers[23] <= 0;
      Registers[24] <= 0;
      Registers[25] <= 0;
      Registers[26] <= 0;
      Registers[27] <= 0;
      Registers[28] <= 0;
      Registers[29] <= 0;
      Registers[30] <= 0;
      Registers[31] <= 0;
    end
    else if(in_wr_enable) begin
      $display("display_regs :%d", display_regs);
      if(in_rd_regno) begin
        $display("Writing Register: %0d with content %0d", in_rd_regno, in_rd_value);
        Registers[in_rd_regno] <= in_rd_value;
      end
    end
    else if(display_regs) begin
      int i;
      for(i=0;i<32;i++)
        $display("Register %0d:\t%0d",i, Registers[i]);
      $finish;
    end
  end
endmodule
