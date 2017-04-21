/*
 * TODO:
 * Add instruction cache module and respective buslines
 */
module fetch
#(
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  INSTRUCTION_WIDTH = 32
)
(
  input clk,
  input reset,
  input in_branch_taken_bool,
  input [ADDRESS_WIDTH-1:0] in_target,
  input in_enable,
  output [ADDRESS_WIDTH-1:0] out_pcplus1,
  output [INSTRUCTION_WIDTH-1:0] out_instruction_bits,
  output out_ready,

  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag,

  input addr_data_abtr_grant,
  output addr_data_abtr_reqcyc,
  input store_data_abtr_grant,
  output store_data_abtr_reqcyc,
  output store_data_bus_busy,
  output addr_data_bus_busy
);
  logic [ADDRESS_WIDTH-1:0] old_pc;
  logic [ADDRESS_WIDTH-1:0] pc;
  logic [INSTRUCTION_WIDTH-1:0] cache_instruction_bits;
  logic cache_ready;

  // TODO: Instantiate Instruction Cache module
  Set_Associative_Cache ICache(	.clk(clk),
				.reset(reset),
				.addr(pc),
				.rd_wr_evict_flag(1),
				.read_data(cache_instruction_bits),
				.data_available(out_ready),//signal which fetch needs to wait on
        			.bus_reqcyc(bus_reqcyc),
        			.bus_respack(bus_respack),
        			.bus_req(bus_req),
        			.bus_reqtag(bus_reqtag),
        			.bus_respcyc(bus_respcyc),
        			.bus_reqack(bus_reqack),
        			.bus_resp(bus_resp),
        			.bus_resptag(bus_resptag),
        			.addr_data_abtr_grant(addr_data_abtr_grant),
        			.addr_data_abtr_reqcyc(addr_data_abtr_reqcyc),
        			.store_data_abtr_grant(store_data_abtr_grant),
        			.store_data_abtr_reqcyc(store_data_abtr_reqcyc),
        			.store_data_bus_busy(store_data_bus_busy),
        			.addr_data_bus_busy(addr_data_bus_busy)
				);
  always_comb begin
    // PC MUX
    if(in_branch_taken_bool) begin
      assign pc = in_target;
    end else begin
      assign pc = old_pc + 4;
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
      out_pcplus1 <= pc + 4;
      old_pc <= pc;
    end
  end
endmodule
