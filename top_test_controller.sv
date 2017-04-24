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
  logic [64*8-1:0] phy_addr_array;
  logic va_pa_abtr_grant;
  logic va_pa_abtr_reqcyc;
  logic va_pa_bus_busy;
  logic va_pa_enable;
  logic va_pa_ready;
  logic addr_data_abtr_grant;
  logic addr_data_abtr_reqcyc;
  logic addr_data_bus_busy;
  logic addr_data_enable;
  logic addr_data_ready;
  logic store_data_abtr_grant;
  logic store_data_abtr_reqcyc;
  logic store_data_bus_busy;
  logic store_data_enable;
  logic store_data_ready;
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
  logic [REGISTER_WIDTH-1:0] mm_mdata;
  logic [REGISTER_WIDTH-1:0] mm_alu_result;
  logic [REGISTERNO_WIDTH-1:0] mm_rd_regno;
  logic mm_ready;
  logic wb_ready;
  logic [REGISTER_WIDTH-1:0] wb_wbdata;
  logic [REGISTERNO_WIDTH-1:0] wb_rd_regno;
  logic [REGISTER_WIDTH-1:0] going2wb_wbdata;
  logic [REGISTERNO_WIDTH-1:0] going2wb_rd_regno;
  logic [REGISTER_WIDTH-1:0] vapacounter;
  logic [REGISTER_WIDTH-1:0] vapacountercase;

  enum {STATERESET=4'b0000, STATEVAPABEGIN=4'b0001, STATEVAPAWAIT=4'b0010,
        STATEADBEGIN=4'b0100, STATEADWAIT=4'b0101, STATEWDBEGIN=4'b0110, STATEWDWAIT=4'b0111, STATEEXEC=4'b1000} state, next_state;

  bus_controller bc    (.clk(clk),
            .bus_reqcyc1(va_pa_abtr_reqcyc),
            .bus_grant1(va_pa_abtr_grant),
            .bus_reqcyc2(addr_data_abtr_reqcyc),
            .bus_grant2(addr_data_abtr_grant),
            .bus_reqcyc3(store_data_abtr_reqcyc),
            .bus_grant3(store_data_abtr_grant),
            .bus_busy(va_pa_bus_busy|addr_data_bus_busy|store_data_bus_busy)
               );
  always_comb begin
    if(addr_data_abtr_grant) begin
      assign addr_data_bus_busy = 1;
    end
    if(store_data_abtr_grant) begin
      assign store_data_bus_busy = 1;
    end
    if(counter == 100) begin
      assign va_pa_abtr_reqcyc = 0;
      assign va_pa_bus_busy = 0;
    end else begin
      assign va_pa_abtr_reqcyc = 1;
      if(va_pa_abtr_grant) begin
        assign va_pa_bus_busy = 1;
      end
    end
    assign addr_data_abtr_reqcyc = 1;
    assign store_data_abtr_reqcyc = 1;
  end
  always_ff @(posedge clk) begin
    $display("counter: %d", counter);
    counter<=counter+1;
    if(va_pa_abtr_grant) begin
      $display("vapa is high");
    end
    if(addr_data_abtr_grant) begin
      $display("addrdata is high");
    end
    if(store_data_abtr_grant) begin
      $display("storedata is high");
    end
  end
endmodule
