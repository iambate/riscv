`include "DCache.sv"
module mm
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  REGISTERNO_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4*8,
  INSTRUCTION_WIDTH = 32,
  INSTRUCTION_NAME_WIDTH = 12*8,
  FLAG_WIDTH = 16,
  READ_SIGNAL=1,
  WRITE_SIGNAL=2
  
)
(
  input clk,
  input reset,
  input [63:0] ptbr,
  input in_enable,
  input [REGISTER_WIDTH-1:0] in_alu_result,//this should have addr in case of load,store
  input [REGISTER_WIDTH-1:0] in_rs2_value,//store.what to write to mem
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input in_mm_load_bool,
  input in_update_rd_bool,
  input [INSTRUCTION_NAME_WIDTH-1:0] in_opcode_name,
  output out_update_rd_bool,
  input in_syscall_flush,
  output out_mm_load_bool,
  input [REGISTER_WIDTH-1:0] in_pcplus1plusoffs,
  output [REGISTER_WIDTH-1:0] out_pcplus1plusoffs,
  output [REGISTER_WIDTH-1:0] out_mdata,
  output [REGISTER_WIDTH-1:0] out_rs2_value,
  output [REGISTER_WIDTH-1:0] out_phy_addr,
  output [REGISTER_WIDTH-1:0] out_alu_result,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [INSTRUCTION_NAME_WIDTH-1:0] out_opcode_name,
  output out_ready,
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
//TODO:
//in_syscall_flush,pc_value passed to 
  // Instantiate Cache and set cache_data as output to be filled
  // data_ready=1 is the signal from cache saying data is ready
	
/*
TODO:
1) store-read first then write
5) if rd_signal given wait on data_available , if wr signal wait on can_Write
when flush signal is high cache wont read or write but it will still invalidate
6) rs2 and pc value for sys call flush time
*/

  Trans_Lookaside_Buff Dtlb(    .clk(clk),
                                .reset(reset),
                                .v_addr(in_alu_result),//IMP
                                .p_addr(p_addr),//IMP
                                .rd_signal(tlb_rd_signal),//IMP
                                .addr_available(tlb_ready),//IMP
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

  D_Set_Associative_Cache DCache( .clk(clk),
                                .reset(reset),
                                .addr(p_addr),//IMP
                                .enable(tlb_ready==2 & cache_enable),//IMP
                                .rd_wr_evict_flag(cache_signal),//IMP
                                .read_data(cache_data),//IMP
                                .data_available(cache_ready_READ),//IMP
				.canWrite(cache_ready_WRITE),//IMP
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
                                .addr_data_bus_busy(out_addr_data_bus_busy),
				.write_data(write_data)//IMP
                                );

	always_comb begin
	end
	always_ff @(posedge clk) begin
		if(reset) begin
		end
		else begin
			out_mm_load_bool <= in_mm_load_bool;
			out_mem_pcplus1plusoffs<=in_pcplus1plusoffs;
			out_alu_result<=in_alu_result;
			out_rd_regno<=in_rd_regno;
			out_opcode_name<=in_opcode_name;
			out_rs2_value<=in_rs2_value;
			out_update_rd_bool <= in_update_rd_bool;
		end
	end

endmodule
