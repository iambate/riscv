`include "Sysbus.defs"
`include "decode.sv"

module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  REGISTERNO_WIDTH = 5,
  INSTRUCTION_WIDTH = 32,
  INSTRUCTION_NAME_WIDTH = 12*8,
  SIZE = 32
)
(
  input  clk,
  input  reset,

  // 64-bit address of the program entry point
  input  [63:0] entry,
  input  [63:0] stackptr,
  input  [63:0] satp,  
  // interface to connect to the bus
  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag
);

  logic [63:0] pc;
  logic [63:0] old_pc;
  logic [63:0] npc;
  logic [8:0] counter;
  logic [8:0] ncounter;
  logic [63:0] phy_addr;
  logic fetch_va_pa_abtr_grant;
  logic fetch_va_pa_abtr_reqcyc;
  logic fetch_va_pa_bus_busy;
  logic fetch_addr_data_abtr_grant;
  logic fetch_addr_data_abtr_reqcyc;
  logic fetch_addr_data_bus_busy;
  logic fetch_store_data_abtr_grant;
  logic fetch_store_data_abtr_reqcyc;
  logic fetch_store_data_bus_busy;
  logic mm_va_pa_abtr_grant;
  logic mm_va_pa_abtr_reqcyc;
  logic mm_va_pa_bus_busy;
  logic mm_addr_data_abtr_grant;
  logic mm_addr_data_abtr_reqcyc;
  logic mm_addr_data_bus_busy;
  logic mm_store_data_abtr_grant;
  logic mm_store_data_abtr_reqcyc;
  logic mm_store_data_bus_busy;
  logic [BUS_DATA_WIDTH*8-1:0] data;
  logic [INSTRUCTION_WIDTH-1:0] fetch_instruction_bits;
  logic [ADDRESS_WIDTH-1:0] fetch_pc;
  logic fetch_ready;
  logic [ADDRESS_WIDTH-1:0] decode_pcplus1;
  logic [REGISTER_WIDTH-1:0] decode_rs1_value;
  logic [REGISTER_WIDTH-1:0] decode_rs2_value;
  logic [REGISTER_WIDTH-1:0] decode_imm_value;
  logic [REGISTERNO_WIDTH-1:0] decode_rs1_regno;
  logic [REGISTERNO_WIDTH-1:0] decode_rs2_regno;
  logic [REGISTERNO_WIDTH-1:0] decode_rd_regno;
  logic [INSTRUCTION_NAME_WIDTH-1:0] decode_opcode_name;
  logic decode_ready;
  logic [REGISTER_WIDTH-1:0] decode_a0;
  logic [REGISTER_WIDTH-1:0] decode_a1;
  logic [REGISTER_WIDTH-1:0] decode_a2;
  logic [REGISTER_WIDTH-1:0] decode_a3;
  logic [REGISTER_WIDTH-1:0] decode_a4;
  logic [REGISTER_WIDTH-1:0] decode_a5;
  logic [REGISTER_WIDTH-1:0] decode_a6;
  logic [REGISTER_WIDTH-1:0] decode_a7;
  logic [REGISTER_WIDTH-1:0] alu_alu_result;
  logic [REGISTER_WIDTH-1:0] alu_rs2_value;
  logic [REGISTERNO_WIDTH-1:0] alu_rd_regno;
  logic [INSTRUCTION_NAME_WIDTH-1:0] alu_opcode_name;
  logic [ADDRESS_WIDTH-1:0] alu_pcplus1plusoffs;
  logic alu_update_rd_bool;
  logic alu_branch_taken_bool;
  logic alu_mm_load_bool;
  logic alu_ready;
  logic display_regs;
  logic mm_update_rd_bool;
  logic mm_mm_load_bool;
  logic mm_branch_taken_bool;
  logic [REGISTER_WIDTH-1:0] mm_mdata;
  logic [REGISTER_WIDTH-1:0] mm_alu_result;
  logic [REGISTER_WIDTH-1:0] mm_rs2_value;
  logic [REGISTER_WIDTH-1:0] mm_phy_addr;
  logic [REGISTERNO_WIDTH-1:0] mm_rd_regno;
  logic mm_ready;
  logic [INSTRUCTION_NAME_WIDTH-1:0] mm_opcode_name;
  logic wb_ready;
  logic wb_syscall_flush;
  logic [63:0] mm_pcplus1plusoffset;
  logic [REGISTER_WIDTH-1:0] wb_wbdata;
  logic [REGISTERNO_WIDTH-1:0] wb_rd_regno;
  logic [REGISTER_WIDTH-1:0] going2wb_wbdata;
  logic [REGISTERNO_WIDTH-1:0] going2wb_rd_regno;

  bus_controller bc    (.clk(clk),
                        .bus_reqcyc1(fetch_va_pa_abtr_reqcyc),
                        .bus_grant1(fetch_va_pa_abtr_grant),
                        .bus_reqcyc2(fetch_addr_data_abtr_reqcyc),
                        .bus_grant2(fetch_addr_data_abtr_grant),
                        .bus_reqcyc3(fetch_store_data_abtr_reqcyc),
                        .bus_grant3(fetch_store_data_abtr_grant),
                        .bus_reqcyc4(mm_va_pa_abtr_reqcyc),
                        .bus_grant4(mm_va_pa_abtr_grant),
                        .bus_reqcyc5(mm_addr_data_abtr_reqcyc),
                        .bus_grant5(mm_addr_data_abtr_grant),
                        .bus_reqcyc6(mm_store_data_abtr_reqcyc),
                        .bus_grant6(mm_store_data_abtr_grant),
                        .bus_busy(fetch_va_pa_bus_busy|fetch_addr_data_bus_busy|fetch_store_data_bus_busy |
                                  mm_va_pa_bus_busy|mm_addr_data_bus_busy|mm_store_data_bus_busy
                                 )
                       );
  fetch fetch_stage(    .clk(clk),
                        .reset(reset),
                        .entry(entry),
                        .in_branch_taken_bool(alu_branch_taken_bool),
                        .ptbr(satp),
                        .in_target(alu_pcplus1plusoffs),
                        .in_enable(mm_ready & alu_ready),
                        .out_pcplus1(fetch_pc),
                        .out_instruction_bits(fetch_instruction_bits),
                        .out_ready(fetch_ready),
                        .out_bus_reqcyc(bus_reqcyc),
                        .out_bus_respack(bus_respack),
                        .out_bus_req(bus_req),
                        .out_bus_reqtag(bus_reqtag),
                        .in_bus_respcyc(bus_respcyc),
                        .in_bus_reqack(bus_reqack),
                        .in_bus_resp(bus_resp),
                        .in_bus_resptag(bus_resptag),
                        .in_addr_data_abtr_grant(fetch_addr_data_abtr_grant),
                        .out_addr_data_abtr_reqcyc(fetch_addr_data_abtr_reqcyc),
                        .in_store_data_abtr_grant(fetch_store_data_abtr_grant),
                        .out_store_data_abtr_reqcyc(fetch_store_data_abtr_reqcyc),
                        .out_store_data_bus_busy(fetch_store_data_bus_busy),
                        .out_addr_data_bus_busy(fetch_addr_data_bus_busy),
                        .in_va_pa_abtr_grant(fetch_va_pa_abtr_grant),
                        .out_va_pa_abtr_reqcyc(fetch_va_pa_abtr_reqcyc),
                        .out_va_pa_bus_busy(fetch_va_pa_bus_busy),
			.in_syscall_flush(wb_syscall_flush),
			.in_sys_call_addrplus1(mm_pcplus1plusoffset));


  decode decode0 (.clk(clk),
                  .reset(reset),
                  // alu_ready is for stall against alu->mm data hazard
                  .in_decode_enable(fetch_ready & mm_ready & alu_ready),
                  .in_stackptr(stackptr),
                  .in_pcplus1(fetch_pc),
                  .in_instruction_bits(fetch_instruction_bits),
                  .in_wb_rd_value(going2wb_wbdata),
                  .in_wb_rd_regno(going2wb_rd_regno),
                  .in_wb_enable(wb_ready & fetch_ready & mm_ready),
                  .in_branch_taken_bool(alu_branch_taken_bool),
                  .in_display_regs(display_regs),
                  .in_syscall_flush(wb_syscall_flush),
                  .out_pcplus1(decode_pcplus1),
                  .out_rs1_value(decode_rs1_value),
                  .out_rs2_value(decode_rs2_value),
                  .out_imm_value(decode_imm_value),
                  .out_rs1_regno(decode_rs1_regno),
                  .out_rs2_regno(decode_rs2_regno),
                  .out_rd_regno(decode_rd_regno),
                  .out_opcode_name(decode_opcode_name),
                  .out_a0(decode_a0),
                  .out_a1(decode_a1),
                  .out_a2(decode_a2),
                  .out_a3(decode_a3),
                  .out_a4(decode_a4),
                  .out_a5(decode_a5),
                  .out_a6(decode_a6),
                  .out_a7(decode_a7),
                  .out_ready(decode_ready)
                  );

  execute_instruction ei0(.clk(clk),
                          .in_enable(fetch_ready & mm_ready),
                          .in_rs1_value(decode_rs1_value),
                          .in_rs2_value(decode_rs2_value),
                          .in_imm_value(decode_imm_value),
                          .in_rd_regno(decode_rd_regno),
                          .in_rs1_regno(decode_rs1_regno),
                          .in_rs2_regno(decode_rs2_regno),
                          .in_opcode_name(decode_opcode_name),
                          .in_alu_rd_regno(alu_rd_regno),
                          .in_mm_rd_regno(mm_rd_regno),
                          .in_wb_rd_regno(wb_rd_regno),
                          .in_alu_alu_result(alu_alu_result),
                          .in_mm_mdata(mm_mdata),
                          .in_mm_alu_result(mm_alu_result),
                          .in_wb_data(wb_wbdata),
                          .in_pcplus1(decode_pcplus1),
                          .in_branch_taken_bool(alu_branch_taken_bool),
                          .in_mm_mm_load_bool(mm_mm_load_bool),
                          .in_alu_mm_load_bool(alu_mm_load_bool),
                          .in_syscall_flush(wb_syscall_flush),
                          .out_alu_result(alu_alu_result),
                          .out_rs2_value(alu_rs2_value),
                          .out_rd_regno(alu_rd_regno),
                          .out_opcode_name(alu_opcode_name),
                          .out_pcplus1plusoffs(alu_pcplus1plusoffs),
                          .out_update_rd_bool(alu_update_rd_bool),
                          .out_branch_taken_bool(alu_branch_taken_bool),
                          .out_mm_load_bool(alu_mm_load_bool),
                          .out_ready(alu_ready)
                          );

  mm mm0 (.clk(clk),
          .in_enable(fetch_ready),
          .ptbr(satp),
          .in_alu_result(alu_alu_result),
          .in_rs2_value(alu_rs2_value),
          .in_rd_regno(alu_rd_regno),
          .in_mm_load_bool(alu_mm_load_bool),
          .in_branch_taken_bool(alu_branch_taken_bool),
          .in_update_rd_bool(alu_update_rd_bool),
          .in_opcode_name(alu_opcode_name),
          .out_update_rd_bool(mm_update_rd_bool),
          .in_syscall_flush(wb_syscall_flush),
          .out_mm_load_bool(mm_mm_load_bool),
          .out_branch_taken_bool(mm_branch_taken_bool),
          .in_pcplus1plusoffs(alu_pcplus1plusoffs),
          .out_pcplus1plusoffs(mm_pcplus1plusoffset),
          .out_mdata(mm_mdata),
          .out_rs2_value(mm_rs2_value),
          .out_phy_addr(mm_phy_addr),
          .out_alu_result(mm_alu_result),
          .out_rd_regno(mm_rd_regno),
          .out_opcode_name(mm_opcode_name),
          .out_ready(mm_ready),
          .out_bus_reqcyc(bus_reqcyc),
          .out_bus_respack(bus_respack),
          .out_bus_req(bus_req),
          .out_bus_reqtag(bus_reqtag),
          .in_bus_respcyc(bus_respcyc),
          .in_bus_reqack(bus_reqack),
          .in_bus_resp(bus_resp),
          .in_bus_resptag(bus_resptag),
          .in_addr_data_abtr_grant(mm_addr_data_abtr_grant),
          .out_addr_data_abtr_reqcyc(mm_addr_data_abtr_reqcyc),
          .in_store_data_abtr_grant(mm_store_data_abtr_grant),
          .out_store_data_abtr_reqcyc(mm_store_data_abtr_reqcyc),
          .out_store_data_bus_busy(mm_store_data_bus_busy),
          .out_addr_data_bus_busy(mm_addr_data_bus_busy),
          .in_va_pa_abtr_grant(mm_va_pa_abtr_grant),
          .out_va_pa_abtr_reqcyc(mm_va_pa_abtr_reqcyc),
          .out_va_pa_bus_busy(mm_va_pa_bus_busy)
          );

  writeback wb0(.clk(clk),
                .reset(reset),
                .in_enable(fetch_ready & mm_ready),
                .in_alu_result(mm_alu_result),
                .in_mdata(mm_mdata),
                .in_rs2_value(mm_rs2_value),
                .in_phy_addr(mm_phy_addr),
                .in_rd_regno(mm_rd_regno),
                .in_mm_load_bool(mm_mm_load_bool),
                .in_update_rd_bool(mm_update_rd_bool),
                .in_branch_taken_bool(mm_branch_taken_bool),
                .in_opcode_name(mm_opcode_name),
                .out_ready(wb_ready),
                .out_wbdata(wb_wbdata),
                .out_rd_regno(wb_rd_regno),
                .out2wb_wbdata(going2wb_wbdata),
                .out2wb_rd_regno(going2wb_rd_regno),
                .in_a0(decode_a0),
                .in_a1(decode_a1),
                .in_a2(decode_a2),
                .in_a3(decode_a3),
                .in_a4(decode_a4),
                .in_a5(decode_a5),
                .in_a6(decode_a6),
                .in_a7(decode_a7),
                .out_syscall_flush(wb_syscall_flush),
                .out_display_regs(display_regs)
                );
endmodule
