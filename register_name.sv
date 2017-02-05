module get_reg_name
#(
  REGISTER_NAME_WIDTH = 4,
  REGISTER_WIDTH = 5
)
(
  input [REGISTER_WIDTH-1:0] reg_number,
  output [REGISTER_NAME_WIDTH*8:0] reg_name
);
  always_comb begin
    casez(reg_number)
      5'b00000: assign reg_name = "zero";
      5'b00001: assign reg_name = "ra";
      5'b00010: assign reg_name = "sp";
      5'b00011: assign reg_name = "gp";
      5'b00100: assign reg_name = "tp";
      5'b00101: assign reg_name = "t0";
      5'b00110: assign reg_name = "t1";
      5'b00111: assign reg_name = "t2";
      5'b01000: assign reg_name = "s0";
      5'b01001: assign reg_name = "a0";
      5'b01010: assign reg_name = "a1";
      5'b01011: assign reg_name = "a2";
      5'b01100: assign reg_name = "a3";
      5'b01101: assign reg_name = "a4";
      5'b01110: assign reg_name = "a5";
      5'b01111: assign reg_name = "a6";
      5'b10000: assign reg_name = "a7";
      5'b10001: assign reg_name = "s2";
      5'b10010: assign reg_name = "s3";
      5'b10011: assign reg_name = "s4";
      5'b10100: assign reg_name = "s5";
      5'b10101: assign reg_name = "s6";
      5'b10110: assign reg_name = "s7";
      5'b10111: assign reg_name = "s8";
      5'b11000: assign reg_name = "s9";
      5'b11001: assign reg_name = "s10";
      5'b11010: assign reg_name = "s11";
      5'b11011: assign reg_name = "t3";
      5'b11100: assign reg_name = "t4";
      5'b11101: assign reg_name = "t5";
      5'b11110: assign reg_name = "t6";
      5'b11111: assign reg_name = "t7";
      default: assign reg_name = "unkn";
    endcase
  end
endmodule
