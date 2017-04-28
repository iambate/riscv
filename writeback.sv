`define WBDEBUG
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
  input [REGISTER_WIDTH-1:0] in_rs2_value,
  input [REGISTER_WIDTH-1:0] in_phy_addr,
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input in_mm_load_bool,
  input in_update_rd_bool,
  input in_branch_taken_bool,
  input [INSTRUCTION_NAME_WIDTH-1:0] in_opcode_name,
  input [REGISTER_WIDTH-1:0] in_a0,
  input [REGISTER_WIDTH-1:0] in_a1,
  input [REGISTER_WIDTH-1:0] in_a2,
  input [REGISTER_WIDTH-1:0] in_a3,
  input [REGISTER_WIDTH-1:0] in_a4,
  input [REGISTER_WIDTH-1:0] in_a5,
  input [REGISTER_WIDTH-1:0] in_a6,
  input [REGISTER_WIDTH-1:0] in_a7,
  output out_ready,
  output out_display_regs,
  output out_syscall_flush,
  output out_update_rd_bool,
  output [REGISTER_WIDTH-1:0] out_wbdata,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [REGISTER_WIDTH-1:0] out2wb_wbdata,
  output [REGISTERNO_WIDTH-1:0] out2wb_rd_regno
);
  logic state;
  logic [REGISTER_WIDTH-1:0] returna0;
  always_comb begin
    assign out_display_regs = 0;
    if(in_opcode_name == "ret" && in_branch_taken_bool == 0) begin
      assign out_display_regs = 1;
      assign out_ready = 0;
      assign out_syscall_flush = 0;
      assign out2wb_rd_regno = 0;
      assign out2wb_wbdata = 0;
    end else if(state == 1) begin
      assign out2wb_rd_regno = 10;
      assign out2wb_wbdata = returna0;
      assign out_ready = 1;
      assign out_syscall_flush = 0;
    end else if(in_opcode_name == "scall") begin
      assign out_ready = 0;
      assign out_syscall_flush = 1;
      assign out2wb_rd_regno = 0;
      assign out2wb_wbdata = 0;
    end else begin
      if(in_mm_load_bool) begin
        assign out2wb_wbdata = in_mdata;
        assign out_ready = 1;
      end else begin
        assign out2wb_wbdata = in_alu_result;
        assign out_ready = in_update_rd_bool;
      end
      assign out2wb_rd_regno = in_rd_regno;
      assign out_syscall_flush = 0;
    end
  end

  always_ff @(posedge clk) begin
    if(reset) begin
      //TODO: Add reset things here
      state <= 0;
    end else begin
      $display("Opcode %s", in_opcode_name);
      if(in_opcode_name == "sd" && in_enable) begin
`ifdef WBDEBUG
        $display("WB do_pending_write sd phy_addr: %d rs2_value: %d", in_phy_addr, in_rs2_value);
`endif
        do_pending_write(in_phy_addr, in_rs2_value, 64);
      end if(in_opcode_name == "sw" && in_enable) begin
`ifdef WBDEBUG
        $display("WB do_pending_write sw phy_addr: %d rs2_value: %d", in_phy_addr, in_rs2_value);
`endif
        do_pending_write(in_phy_addr, in_rs2_value, 32);
      end if(in_opcode_name == "sh" && in_enable) begin
`ifdef WBDEBUG
        $display("WB do_pending_write sh phy_addr: %d rs2_value: %d", in_phy_addr, in_rs2_value);
`endif
        do_pending_write(in_phy_addr, in_rs2_value, 16);
      end if(in_opcode_name == "sb" && in_enable) begin
`ifdef WBDEBUG
        $display("WB do_pending_write sb phy_addr: %d rs2_value: %d", in_phy_addr, in_rs2_value);
`endif
        do_pending_write(in_phy_addr, in_rs2_value, 8);
      end
      if(in_opcode_name == "scall" && in_enable) begin
`ifdef WBDEBUG
        $display("WB scall, do_ecall called");
`endif
        do_ecall(in_a7, in_a0, in_a1, in_a2, in_a3, in_a4, in_a5, in_a6, returna0);
        state <= 1;
      end else begin
        state <= 0;
      end
      if(in_enable) begin
        if(out_ready) begin
`ifdef WBDEBUG
          $display("WB wbdata: %d", out2wb_wbdata); 
          $display("WB rd regno: %d", out2wb_rd_regno); 
          $display("WB ready: %d", out_ready); 
`endif
          out_wbdata <= out2wb_wbdata;
          out_rd_regno <= out2wb_rd_regno;
          out_update_rd_bool <= out_ready;
        end else begin
`ifdef WBDEBUG
          $display("WB wbdata: %d", 0); 
          $display("WB rd regno: %d", 0); 
          $display("WB ready: %d", out_ready); 
`endif
          out_wbdata <= 0;
          out_rd_regno <= 0;
          out_update_rd_bool <= 0;
        end
      end // close else in_enable
    end // close else reset
  end //close ff
endmodule
