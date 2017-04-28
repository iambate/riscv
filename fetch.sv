`define FETCHDEBUG
//`define FETCHDEBUGEXT
`include "Cache.sv"
`include "TLB.sv"
module fetch
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  INSTRUCTION_WIDTH = 32
)
(
  input clk,
  input reset,
  input [REGISTER_WIDTH-1:0] ptbr,
  input [REGISTER_WIDTH-1:0] entry,
  input in_branch_taken_bool,
  input [ADDRESS_WIDTH-1:0] in_target,
  input in_enable,
  output [ADDRESS_WIDTH-1:0] out_pcplus1,
  output [INSTRUCTION_WIDTH-1:0] out_instruction_bits,
  output out_ready,
  input in_syscall_flush,
  input [63:0] in_sys_call_addrplus1,
  output out_bus_reqcyc,
  output out_bus_respack,
  output [BUS_DATA_WIDTH-1:0] out_bus_req,
  output [BUS_TAG_WIDTH-1:0] out_bus_reqtag,
  input  in_bus_respcyc,
  input  in_bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] in_bus_resp,
  input  [BUS_TAG_WIDTH-1:0] in_bus_resptag,

  input in_addr_data_abtr_grant,
  output out_addr_data_abtr_reqcyc,
  input in_store_data_abtr_grant,
  output out_store_data_abtr_reqcyc,
  output out_store_data_bus_busy,
  output out_addr_data_bus_busy,
  input in_va_pa_abtr_grant,
  output out_va_pa_abtr_reqcyc,
  output out_va_pa_bus_busy
);
  logic [ADDRESS_WIDTH-1:0] old_pc;
  logic [ADDRESS_WIDTH-1:0] pc;
  logic [INSTRUCTION_WIDTH-1:0] cache_instruction_bits;
  logic [1:0] cache_ready;
  logic [1:0] tlb_ready;
  logic [63:0] p_addr;
  // TODO: Instantiate Instruction Cache module
//
  Trans_Lookaside_Buff Itlb(     .clk(clk),
                                .reset(reset),
                                .v_addr(pc),
                                .p_addr(p_addr),
				.rd_signal(tlb_rd_signal),
                                .addr_available(tlb_ready),//signal which fetch needs to wait on
				.ptbr(ptbr), 
                                .bus_reqcyc(out_bus_reqcyc),
                                .bus_respack(out_bus_respack),
                                .bus_req(out_bus_req),
                                .bus_reqtag(out_bus_reqtag),
                                .bus_respcyc(in_bus_respcyc),
                                .bus_reqack(in_bus_reqack),
                                .bus_resp(in_bus_resp),
                                .bus_resptag(in_bus_resptag),
                                .va_pa_abtr_grant(in_va_pa_abtr_grant),
                                .va_pa_abtr_reqcyc(out_va_pa_abtr_reqcyc),
                                .va_pa_bus_busy(out_va_pa_bus_busy)
                                );

  Set_Associative_Cache ICache(	.clk(clk),
				.reset(reset),
				.addr(p_addr),
				//TODO: IMP: check for circular dependency
				.enable(cache_rd_signal),//TODO: check if this works
				.rd_wr_evict_flag(1),
				.read_data(cache_instruction_bits),
				.data_available(cache_ready),//signal which fetch needs to wait on
        			.bus_reqcyc(out_bus_reqcyc),
        			.bus_respack(out_bus_respack),
        			.bus_req(out_bus_req),
        			.bus_reqtag(out_bus_reqtag),
        			.bus_respcyc(in_bus_respcyc),
        			.bus_reqack(in_bus_reqack),
        			.bus_resp(in_bus_resp),
        			.bus_resptag(in_bus_resptag),
        			.addr_data_abtr_grant(in_addr_data_abtr_grant),
        			.addr_data_abtr_reqcyc(out_addr_data_abtr_reqcyc),
        			.store_data_abtr_grant(in_store_data_abtr_grant),
        			.store_data_abtr_reqcyc(out_store_data_abtr_reqcyc),
        			.store_data_bus_busy(out_store_data_bus_busy),
        			.addr_data_bus_busy(out_addr_data_bus_busy)
				);
  always_comb begin
	if(in_syscall_flush) begin
		assign cache_rd_signal=0;
	end
	else begin
		if(tlb_ready==2) begin
			assign cache_rd_signal=1;
		end
		else begin
			assign cache_rd_signal =0;
		end
	end
  end
  always_comb begin
    // PC MUX
    // when flush signal is high set pc to pc plus 1 of sys call inst
    if(in_syscall_flush) begin
	assign pc = in_sys_call_addrplus1-'d4;
    end
    else begin
    	if(in_branch_taken_bool) begin
      		assign pc = in_target;
    	end else begin
      		assign pc = old_pc + 4;
    	end
    end

    if(in_syscall_flush) begin
	assign tlb_rd_signal=0;
    end
    else begin
	assign tlb_rd_signal=1;
    end
    //TODO: the case for flush_signal
    // Decide to stall or not
    if(in_syscall_flush) begin
	assign out_ready=1;
    end
    else begin
	    if(cache_ready==2) begin
	      assign out_ready = 1;
	    end else begin
	      assign out_ready = 0;
	    end
    end

  end
  always_ff @ (posedge clk) begin
`ifdef FETCHDEBUGEXT
    $display("FETCH ready %d", out_ready);
`endif
    if(reset) begin
`ifdef FETCHDEBUG
	$display("FETCH old_pc resetted to %d", entry-4);
`endif
      old_pc <= entry-4;
      out_instruction_bits <= 0;
      out_pcplus1 <= 0;
    end else if(in_syscall_flush) begin
`ifdef FETCHDEBUG
	$display("FETCH flushed due to syscall flush signal"); 
`endif
	out_pcplus1<=0;
	out_instruction_bits<=0;
	old_pc<=pc;
    end else if(cache_ready==2 & in_enable) begin
`ifdef FETCHDEBUG
	$display("FETCH :instruction bits %x", cache_instruction_bits);
	$display("FETCH :this pc %d", pc);
`endif
	out_instruction_bits <= cache_instruction_bits;
	out_pcplus1 <= pc + 4;
	old_pc <= pc;
    end
  end
endmodule
