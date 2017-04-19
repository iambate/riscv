
module writeback
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
  input [REGISTER_WIDTH-1:0] in_mdata,
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input in_mm_load_bool,
  input in_update_rd_bool,
  output out_ready,
  output [REGISTER_WIDTH-1:0] out_wbdata,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [REGISTER_WIDTH-1:0] out2wb_wbdata,
  output [REGISTERNO_WIDTH-1:0] out2wb_rd_regno
);

  always_comb begin
    if(in_mm_load_bool) begin
      assign out2wb_wbdata = in_mdata;  
    end else begin
      assign out2wb_wbdata = in_alu_result;
    end
    assign out2wb_rd_regno = in_rd_regno;
    if(in_enable) begin
      assign out_ready = in_update_rd_bool;
    end else begin
      assign out_ready = 0;
    end
  end

  always_ff @(posedge clk) begin
    if(reset) begin
      //TODO: Add reset things here
    end else begin
      if(in_enable) begin
        out_wbdata <= out2wb_wbdata;
        out_rd_regno <= out2wb_rd_regno;
      end
    end
  end
endmodule
