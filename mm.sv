
module mm
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
  input in_enable,
  input [REGISTER_WIDTH-1:0] in_alu_result,
  input [REGISTER_WIDTH-1:0] in_rs2_value,
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input in_mm_load_bool,
  input in_update_rd_bool,
  input [INSTRUCTION_NAME_WIDTH-1:0] in_opcode_name,
  output out_update_rd_bool,
  output out_mm_load_bool,
  output [REGISTER_WIDTH-1:0] out_mdata,
  output [REGISTER_WIDTH-1:0] out_alu_result,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno
);
  always_ff @(posedge clk) begin
    if(reset) begin
      //TODO: Add reset things here
    end else begin
      if(in_enable) begin
        $display("MM mm_load_bool %d", in_mm_load_bool);
        $display("MM alu result %d", in_alu_result);
        $display("MM rd regno %d", in_rd_regno);
        $display("MM update rd bool %d", in_update_rd_bool);
        out_mm_load_bool <= in_mm_load_bool;
        out_alu_result <= in_alu_result;
        out_rd_regno <= in_rd_regno;
        out_update_rd_bool <= in_update_rd_bool;
      end
    end
  end
endmodule
