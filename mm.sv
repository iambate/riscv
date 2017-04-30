`include "DCache.sv"
`define MMDEBUG
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
  input in_branch_taken_bool,
  input in_update_rd_bool,
  input [INSTRUCTION_NAME_WIDTH-1:0] in_opcode_name,
  output out_update_rd_bool,
  output out_branch_taken_bool,
  input in_syscall_flush,
  output out_mm_load_bool,
  input [REGISTER_WIDTH-1:0] in_pcplus1plusoffs,
  output [REGISTER_WIDTH-1:0] out_pcplus1plusoffs,
  output [REGISTER_WIDTH-1:0] out_mdata,//DONE:need to set
  output [REGISTER_WIDTH-1:0] out_rs2_value,
  output [REGISTER_WIDTH-1:0] out_phy_addr,//DONE:set to paddr when u get tlb_ready==2 for 
					   //st insts
  output [REGISTER_WIDTH-1:0] out_alu_result,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [INSTRUCTION_NAME_WIDTH-1:0] out_opcode_name,
  output out_ready,//DONE:set when cache_read_READY is set for ld and cache_read_WRITE is set for st
		   //set at once for other insts-always_comb
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
  // Instantiate Cache and set cache_data as output to be filled
  // data_ready=1 is the signal from cache saying data is ready
	logic [63:0] p_addr;
	logic tlb_rd_signal;//DONE:ld st and sys_call flush
	logic [1:0] tlb_ready;
	logic cache_enable;//TODO: dont think we need it-enable only for ld and st inst and tlb is ready:done
	logic [1:0] cache_signal;//give read_signal/write_signal depending on inst
	logic [63:0] cache_data;//DONE:set to out_mdata in case of ld signal
	logic [63:0] ff_cache_data;
	logic [1:0] cache_ready_READ;
	logic [1:0] cache_ready_WRITE;
	logic [63:0] write_data;
	logic [63:0] v_addr;//derive from in_alu_result	
	logic write_data_byte0_bool;
	logic write_data_byte1_bool;
	logic write_data_byte2_bool;
	logic write_data_byte3_bool;
	logic write_data_byte4_bool;
	logic write_data_byte5_bool;
	logic write_data_byte6_bool;
	logic write_data_byte7_bool;
/*
TODO:
1) store-read first then write
5) if rd_signal given wait on data_available , if wr signal wait on can_Write
when flush signal is high cache wont read or write but it will still invalidate
6) rs2 and pc value for sys call flush time
*/

  Trans_Lookaside_Buff Dtlb(    .clk(clk),
                                .reset(reset),
                                .v_addr(v_addr),//IMP
                                .p_addr(p_addr),//IMP-output
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
                                .enable(cache_enable),//IMP
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
								.write_data(write_data),//IMP
								.write_data_byte0_bool(write_data_byte0_bool),
								.write_data_byte1_bool(write_data_byte1_bool),
								.write_data_byte2_bool(write_data_byte2_bool),
								.write_data_byte3_bool(write_data_byte3_bool),
								.write_data_byte4_bool(write_data_byte4_bool),
								.write_data_byte5_bool(write_data_byte5_bool),
								.write_data_byte6_bool(write_data_byte6_bool),
								.write_data_byte7_bool(write_data_byte7_bool)
                                );


	always_comb begin
		//defaults
		assign tlb_rd_signal=0;
		assign v_addr=0;
		if(!in_syscall_flush) begin
			if(in_opcode_name == "sd" || 
				in_opcode_name == "sw" ||
				in_opcode_name == "sh" ||
				in_opcode_name == "sb" ||
				in_opcode_name == "lw" ||
				in_opcode_name == "lwu" ||
				in_opcode_name == "lh" ||
				in_opcode_name == "lhu" ||
				in_opcode_name == "lb" ||
				in_opcode_name == "lbu" ||
				in_opcode_name == "ld") begin//store or loads

				assign tlb_rd_signal=1;
				assign v_addr=in_alu_result[63:3]<<3;
			end // end of else of stores or loads
		end //end if syscall_flush 
	end// end of always comb of tlb_rd_signal


	//for manipulating data to write for sb,sh,sw
	always_comb begin
		// default write_data_byte[0-7]_bool to 0
		assign write_data_byte0_bool=0;
		assign write_data_byte1_bool=0;
		assign write_data_byte2_bool=0;
		assign write_data_byte3_bool=0;
		assign write_data_byte4_bool=0;
		assign write_data_byte5_bool=0;
		assign write_data_byte6_bool=0;
		assign write_data_byte7_bool=0;
		assign write_data=0;
		assign cache_enable=0;
		assign cache_signal=0;
		if(tlb_ready==2) begin
			case(in_opcode_name)
			"sb":begin
				assign cache_enable = 1;
				assign cache_signal = WRITE_SIGNAL;
				if(in_alu_result[2:0]==0) begin
					assign write_data_byte0_bool=1;
					assign write_data[7:0]=in_rs2_value[7:0];
				end
				else if(in_alu_result[2:0]==1) begin
					assign write_data_byte1_bool=1;
					assign write_data[15:8]=in_rs2_value[7:0];
				end
				else if(in_alu_result[2:0]==2) begin
					assign write_data_byte2_bool=1;
					assign write_data[23:16]=in_rs2_value[7:0];
				end
				else if(in_alu_result[2:0]==3) begin//
					assign write_data_byte3_bool=1;
					assign write_data[31:24]=in_rs2_value[7:0];
				end
				else if(in_alu_result[2:0]==4) begin
					assign write_data_byte4_bool=1;
					assign write_data[39:32]=in_rs2_value[7:0];
				end
				else if(in_alu_result[2:0]==5) begin
					assign write_data_byte5_bool=1;
					assign write_data[47:40]=in_rs2_value[7:0];
				end
				else if(in_alu_result[2:0]==6) begin
					assign write_data_byte6_bool=1;
					assign write_data[55:48]=in_rs2_value[7:0];
				end
				else if(in_alu_result[2:0]==7) begin
					assign write_data_byte7_bool=1;
					assign write_data[63:56]=in_rs2_value[7:0];
				end
			end //case sw end
			"sh":begin
				assign cache_enable = 1;
				assign cache_signal = WRITE_SIGNAL;
				if(in_alu_result[2:0]==0) begin
					assign write_data_byte0_bool=1;
					assign write_data_byte1_bool=1;
					assign write_data[15:0]=in_rs2_value[15:0];
				end
				else if(in_alu_result[2:0]==2) begin
					assign write_data_byte2_bool=1;
					assign write_data_byte3_bool=1;
					assign write_data[31:16]=in_rs2_value[15:0];
				end
				else if(in_alu_result[2:0]==4) begin
					assign write_data_byte4_bool=1;
					assign write_data_byte5_bool=1;
					assign write_data[47:32]=in_rs2_value[15:0];
				end
				else if(in_alu_result[2:0]==6) begin//
					assign write_data_byte6_bool=1;
					assign write_data_byte7_bool=1;
					assign write_data[63:48]=in_rs2_value[15:0];
				end
			end //case end sh
			"sw":begin
				assign cache_enable = 1;
				assign cache_signal = WRITE_SIGNAL;
				if(in_alu_result[2]==0) begin
					assign write_data_byte0_bool=1;
					assign write_data_byte1_bool=1;
					assign write_data_byte2_bool=1;
					assign write_data_byte3_bool=1;
					assign write_data[31:0]=in_rs2_value[31:0];
				end
				else if(in_alu_result[2]==1) begin
					assign write_data_byte4_bool=1;
					assign write_data_byte5_bool=1;
					assign write_data_byte6_bool=1;
					assign write_data_byte7_bool=1;
					assign write_data[63:32]=in_rs2_value[31:0];
				end
			end //case end sw
			"sd": begin
				assign cache_enable = 1;
				assign cache_signal = WRITE_SIGNAL;
				assign write_data_byte0_bool=1;
				assign write_data_byte1_bool=1;
				assign write_data_byte2_bool=1;
				assign write_data_byte3_bool=1;
				assign write_data_byte4_bool=1;
				assign write_data_byte5_bool=1;
				assign write_data_byte6_bool=1;
				assign write_data_byte7_bool=1;
				assign write_data = in_rs2_value;
			end
			"lw": begin
				assign cache_enable = 1;
				assign cache_signal = READ_SIGNAL;
			end
			"lwu": begin
				assign cache_enable = 1;
				assign cache_signal = READ_SIGNAL;
			end
			"lh": begin
				assign cache_enable = 1;
				assign cache_signal = READ_SIGNAL;
			end
			"lhu": begin
				assign cache_enable = 1;
				assign cache_signal = READ_SIGNAL;
			end
			"lb": begin
				assign cache_enable = 1;
				assign cache_signal = READ_SIGNAL;
			end
			"lbu": begin
				assign cache_enable = 1;
				assign cache_signal = READ_SIGNAL;
			end
			"ld": begin
				assign cache_enable = 1;
				assign cache_signal = READ_SIGNAL;
			end
			endcase
		end
	end


	always_comb begin
		assign out_ready=1;
		if(in_opcode_name == "lw" ||
			in_opcode_name == "lwu" ||
			in_opcode_name == "lh" ||
			in_opcode_name == "lhu" ||
			in_opcode_name == "lb" ||
			in_opcode_name == "lbu" ||
			in_opcode_name == "ld") begin//store or loads

			assign out_ready = 0;
			if(cache_ready_READ==2 || in_syscall_flush==1) begin
				assign out_ready = 1;
			end
		end else if(in_opcode_name == "sd" || 
			in_opcode_name == "sw" ||
			in_opcode_name == "sh" ||
			in_opcode_name == "sb" ) begin//store or loads

			assign out_ready = 0;
			if (cache_ready_WRITE==2 || in_syscall_flush==1) begin
				assign out_ready = 1;
			end
		end
	end


	always_ff @(posedge clk) begin
		if(reset || in_syscall_flush) begin
			$display("MM Flush due to syscall signal");	
			out_mm_load_bool<=0;
			out_pcplus1plusoffs<=0;
			out_alu_result<=0;
			out_rd_regno<=0;
			out_opcode_name<=0;
			out_rs2_value<=0;
			out_update_rd_bool<=0;
		end else if(in_enable && out_ready) begin
`ifdef MMDEBUGEXTRA
			$display("MM out ready %d", out_ready);
			$display("MM cache ready read %d", cache_ready_READ);
			$display("MM cache ready write %d", cache_ready_WRITE);
			$display("MM TLB ready %d", tlb_ready);
			$display("MM TLB rs signal %d", tlb_rd_signal);
`endif
`ifdef MMDEBUG
			$display("MM stage done :%s mm_load_bool %d", in_opcode_name,in_mm_load_bool);
			$display("MM stage done :%s alu result %d",  in_opcode_name,in_alu_result);
			$display("MM stage done :%s rd regno %d",  in_opcode_name,in_rd_regno);
			$display("MM stage done :%s rs2 value %d",  in_opcode_name,in_rs2_value);
			$display("MM stage done :%s update bool %d",  in_opcode_name,in_update_rd_bool);
			$display("MM stage done :%s branch taken %d",  in_opcode_name,in_branch_taken_bool);
`endif
			out_phy_addr <= (p_addr[REGISTER_WIDTH-1:12]<<12) + in_alu_result[11:0];
			out_mm_load_bool <= in_mm_load_bool;
			out_pcplus1plusoffs<=in_pcplus1plusoffs;
			out_alu_result<=in_alu_result;
			out_rd_regno<=in_rd_regno;
			out_opcode_name<=in_opcode_name;
			out_rs2_value<=in_rs2_value;
			out_update_rd_bool <= in_update_rd_bool;
			out_branch_taken_bool <= in_branch_taken_bool;
			case(in_opcode_name)
			"lb":begin
				if(in_alu_result[2:0]==0) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[7:0]));
`endif
					out_mdata<=$signed(cache_data[7:0]);
				end
				else if(in_alu_result[2:0]==1) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[15:8]));
`endif
					out_mdata<=$signed(cache_data[15:8]);
				end
				else if(in_alu_result[2:0]==2) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[23:16]));
`endif
					out_mdata<=$signed(cache_data[23:16]);
				end
				else if(in_alu_result[2:0]==3) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[31:24]));
`endif
					out_mdata<=$signed(cache_data[31:24]);
				end
				else if(in_alu_result[2:0]==4) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[39:32]));
`endif
					out_mdata<=$signed(cache_data[39:32]);
				end
				else if(in_alu_result[2:0]==5) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[47:40]));
`endif
					out_mdata<=$signed(cache_data[47:40]);
				end
				else if(in_alu_result[2:0]==6) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[55:48]));
`endif
					out_mdata<=$signed(cache_data[55:48]);
				end
				else if(in_alu_result[2:0]==7) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[63:56]));
`endif
					out_mdata<=$signed(cache_data[63:56]);
				end
			end // end of case lb
			"lbu":begin
				if(in_alu_result[2:0]==0) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[7:0]);
`endif
						out_mdata<=cache_data[7:0];
				end
				else if(in_alu_result[2:0]==1) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[15:8]);
`endif
						out_mdata<=cache_data[15:8];
				end
				else if(in_alu_result[2:0]==2) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[23:16]);
`endif
						out_mdata<=cache_data[23:16];
				end
				else if(in_alu_result[2:0]==3) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[31:24]);
`endif
						out_mdata<=cache_data[31:24];
				end
				else if(in_alu_result[2:0]==4) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[39:32]);
`endif
						out_mdata<=cache_data[39:32];
				end
				else if(in_alu_result[2:0]==5) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[47:40]);
`endif
						out_mdata<=cache_data[47:40];
				end
				else if(in_alu_result[2:0]==6) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[55:48]);
`endif
						out_mdata<=cache_data[55:48];
				end
				else if(in_alu_result[2:0]==7) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[63:56]);
`endif
						out_mdata<=cache_data[63:56];
				end
			end // end of case lbu
			"lh":begin
				if(in_alu_result[2:0]==0) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[15:0]));
`endif
						out_mdata<=$signed(cache_data[15:0]);
				end
				else if(in_alu_result[2:0]==2) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[31:16]));
`endif
						out_mdata<=$signed(cache_data[31:16]);
				end
				else if(in_alu_result[2:0]==4) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[47:32]));
`endif
						out_mdata<=$signed(cache_data[47:32]);
				end
				else if(in_alu_result[2:0]==6) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[63:48]));
`endif
						out_mdata<=$signed(cache_data[63:48]);
				end
			end //end of case lh
			"lhu":begin
				if(in_alu_result[2:0]==0) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[15:0]);
`endif
						out_mdata<=cache_data[15:0];
				end
				else if(in_alu_result[2:0]==2) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[31:16]);
`endif
						out_mdata<=cache_data[31:16];
				end
				else if(in_alu_result[2:0]==4) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[47:32]);
`endif
						out_mdata<=cache_data[47:32];
				end
				else if(in_alu_result[2:0]==6) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[63:48]);
`endif
						out_mdata<=cache_data[63:48];
				end
			end //end of case lhu
			"lw":begin
				if(in_alu_result[2:0]==0) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[31:0]));
`endif
					out_mdata<=$signed(cache_data[31:0]);
				end
				else if(in_alu_result[2:0]==4) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,$signed(cache_data[63:32]));
`endif
					out_mdata<=$signed(cache_data[63:32]);
				end
			end
			"lwu":begin
				if(in_alu_result[2:0]==0) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[31:0]);
`endif
					 out_mdata<=cache_data[31:0];
				end
				else if(in_alu_result[2:0]==4) begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data[63:32]);
`endif
						out_mdata<=cache_data[63:32];
				end
			end
			"ld":begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,cache_data);
`endif
				out_mdata<=$signed(cache_data);
            end
			default:begin
`ifdef MMDEBUG
					$display("MM stage done :%s mdata %d", in_opcode_name,0);
`endif
				out_mdata<=0;
			end
			endcase
		end //end of if(in_enable and out_ready)
	end// end always ff
endmodule
