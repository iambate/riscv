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
	logic [1:0] cache_ready_READ;
	logic [1:0] cache_ready_WRITE;
	logic [63:0] write_data;
	logic [1:0] store_rd_wr;
	logic [63:0] v_addr;//derive from in_alu_result	
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
				.write_data(write_data)//IMP
                                );
	//for manipulating data to write for sb,sh,sw
	always_comb begin
		case(in_opcode_name)
		"sb":begin
			if(store_rd_wr==2) begin
                                //assign stuff to write_data that are taken from read_data
                                if(in_alu_result[2:0]==0) begin
                                        assign write_data[7:0]=in_rs2_value[7:0];
                                        assign write_data[63:8]=cache_data[63:8];
                                end
                                else if(in_alu_result[2:0]==1) begin
                                        assign write_data[7:0]=cache_data[7:0];
                                        assign write_data[15:8]=in_rs2_value[7:0];
                                        assign write_data[63:16]=cache_data[63:16];
                                end
                                else if(in_alu_result[2:0]==2) begin
                                        assign write_data[15:0]=cache_data[15:0];
                                        assign write_data[23:16]=in_rs2_value[7:0];
                                        assign write_data[63:24]=cache_data[63:24];
                                end
                                else if(in_alu_result[2:0]==3) begin//
                                        assign write_data[23:0]=cache_data[23:0];
                                        assign write_data[31:24]=in_rs2_value[7:0];
                                        assign write_data[63:32]=cache_data[63:32];
                                end
                                else if(in_alu_result[2:0]==4) begin
                                        assign write_data[31:0]=cache_data[31:0];
                                        assign write_data[39:32]=in_rs2_value[7:0];
                                        assign write_data[63:40]=cache_data[63:40];
                                end
                                else if(in_alu_result[2:0]==5) begin
					assign write_data[39:0]=cache_data[39:0];
                                        assign write_data[47:40]=in_rs2_value[7:0];
                                        assign write_data[63:48]=cache_data[63:48];
                                end
                                else if(in_alu_result[2:0]==6) begin
                                        assign write_data[47:0]=cache_data[47:0];
                                        assign write_data[55:48]=in_rs2_value[7:0];
                                        assign write_data[63:56]=cache_data[63:56];
                                end
                                else if(in_alu_result[2:0]==7) begin
                                        assign write_data[55:0]=cache_data[55:0];
                                        assign write_data[63:56]=in_rs2_value[7:0];
                                end
			end
		end
		"sh":begin
			if(store_rd_wr==2) begin
                                if(in_alu_result[2:0]==0) begin
                                        assign write_data[15:0]=in_rs2_value[15:0];
                                        assign write_data[63:16]=cache_data[63:16];
                                end
                                else if(in_alu_result[2:0]==2) begin
                                        assign write_data[15:0]=cache_data[15:0];
                                        assign write_data[31:16]=in_rs2_value[15:0];
                                        assign write_data[63:32]=cache_data[63:32];
                                end
                                else if(in_alu_result[2:0]==4) begin
                                        assign write_data[31:0]=cache_data[31:0];
                                        assign write_data[47:32]=in_rs2_value[15:0];
                                        assign write_data[63:48]=cache_data[63:48];
                                end
                                else if(in_alu_result[2:0]==6) begin//
                                        assign write_data[47:0]=cache_data[47:0];
                                        assign write_data[63:48]=in_rs2_value[15:0];
                                end
                        end
		end
		"sw":begin
			if(store_rd_wr==2) begin
                                if(in_alu_result[2:0]==0) begin
                                        assign write_data[31:0]=in_rs2_value[31:0];
                                        assign write_data[63:32]=cache_data[63:32];
                                end
                                else if(in_alu_result[2:0]==4) begin
                                        assign write_data[31:0]=cache_data[31:0];
                                        assign write_data[63:32]=in_rs2_value[31:0];
                                end
                        end
		end
		endcase
	end
	always_comb begin
		case(in_opcode_name) 
		"sb": begin 
//state0:give tlb the signal, 			wait for tlb_ready
//state1:tlb_ready give cache read signal, 	wait for cache_ready_READ
//state2:cache_ready_READ=2 , manipulate data , give write signal, 	wait for cache_ready_WRITE
			if(store_rd_wr == 0) begin
				assign tlb_rd_signal=1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			else if(store_rd_wr == 1) begin
				assign cache_enable=1;
				assign cache_signal=READ_SIGNAL;
			end
			else if(store_rd_wr==2) begin
				assign cache_enable=1;
				//assign stuff to write_data that are taken from read_data
				assign cache_signal = WRITE_SIGNAL;
			end
		end
		"sh": begin
			if(store_rd_wr == 0) begin
                                assign tlb_rd_signal=1;
                                assign v_addr=in_alu_result[63:3]<<3;
                        end
                        else if(store_rd_wr == 1) begin
				assign cache_enable=1;
                                assign cache_signal=READ_SIGNAL;
                        end
                        else if(store_rd_wr==2) begin
				assign cache_enable=1;
				assign cache_signal = WRITE_SIGNAL;
                        end
                end
		"sw": begin
			if(store_rd_wr == 0) begin
                                assign tlb_rd_signal=1;
                                assign v_addr=in_alu_result[63:3]<<3;
                        end
                        else if(store_rd_wr == 1) begin
				assign cache_enable=1;
                                assign cache_signal=READ_SIGNAL;
                        end
                        else if(store_rd_wr==2) begin
				assign cache_enable=1;
				assign cache_signal = WRITE_SIGNAL;
                        end
                end
		endcase
	end
	always_comb begin
		if(in_syscall_flush) begin
                        assign cache_enable=0;
                end
                else begin
                        case(in_opcode_name)
                        "sd":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign write_data=in_rs2_value;
				assign cache_signal=WRITE_SIGNAL;
                        end
                        "lb":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign cache_signal=READ_SIGNAL;
                        end
			"lbu":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign cache_signal=READ_SIGNAL;
                        end
                        "lh":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign cache_signal=READ_SIGNAL;
                        end
                        "lhu":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign cache_signal=READ_SIGNAL;
                        end
                        "lw":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign cache_signal=READ_SIGNAL;
                        end
                        "lwu":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign cache_signal=READ_SIGNAL;
                        end
                        "ld":begin
				if(tlb_ready==2) begin
                                        assign cache_enable =1;
                                end
                                else begin
                                        assign cache_enable=0;
                                end
				assign cache_signal=READ_SIGNAL;
                        end
			default:begin
				assign cache_enable=0;
			end
                        endcase
		end
	end
	always_comb begin
		if(in_syscall_flush) begin
			assign tlb_rd_signal=0;
		end
		else begin
			case(in_opcode_name)
			"sd":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			"lb":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			"lbu":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			"lh":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			"lhu":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			"lw":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			"lwu":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			"ld":begin
				assign tlb_rd_signal =1;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			default:begin
				assign tlb_rd_signal =0;
				assign v_addr=in_alu_result[63:3]<<3;
			end
			endcase
		end
	end
	always_comb begin
		if(in_syscall_flush) begin
			assign out_ready=1;
		end
		else begin
			case(in_opcode_name)
			"sb":begin
				if(cache_ready_WRITE==2) begin
					assign out_ready =1;
				end
				else begin
					assign out_ready = 0;
				end
			end
			"sh":begin
				if(cache_ready_WRITE==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"sw":begin
				if(cache_ready_WRITE==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"sd":begin
				if(cache_ready_WRITE==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"lb":begin
				if(cache_ready_READ==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"lbu":begin
				if(cache_ready_READ==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"lh":begin
				if(cache_ready_READ==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"lhu":begin
				if(cache_ready_READ==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"lw":begin
				if(cache_ready_READ==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"lwu":begin
				if(cache_ready_READ==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			"ld":begin
				if(cache_ready_READ==2) begin
                                        assign out_ready =1;
                                end
                                else begin
                                        assign out_ready = 0;
                                end
			end
			default:begin
				assign out_ready=1;
			end
			endcase
		end
	end
	always_ff @(posedge clk) begin
		if(reset) begin
			out_mm_load_bool<=0;
			out_pcplus1plusoffs<=0;
			out_alu_result<=0;
			out_rd_regno<=0;
			out_opcode_name<=0;
			out_rs2_value<=0;
			out_update_rd_bool<=0;
			store_rd_wr<=0;
		end
		else begin
			if(in_syscall_flush) begin
				out_mm_load_bool<=0;
				out_pcplus1plusoffs<=0;
				out_alu_result<=0;
				out_rd_regno<=0;
				out_opcode_name<=0;
				out_rs2_value<=0;
                        	out_update_rd_bool<=0;
                                out_branch_taken_bool <= 0;
				store_rd_wr<=0;//TODO:should this really be here. Rethink the logic
			end
			else begin
				if(out_ready) begin
					out_mm_load_bool <= in_mm_load_bool;
					out_pcplus1plusoffs<=in_pcplus1plusoffs;
					out_alu_result<=in_alu_result;
					out_rd_regno<=in_rd_regno;
					out_opcode_name<=in_opcode_name;
					out_rs2_value<=in_rs2_value;
					out_update_rd_bool <= in_update_rd_bool;
					out_branch_taken_bool <= in_branch_taken_bool;
				end
//state0:give tlb the signal,                   wait for tlb_ready
//state1:tlb_ready give cache read signal,      wait for cache_ready_READ
//state2:cache_ready_READ=2 , manipulate data , give write signal,      wait for cache_ready_WRITE
				if(in_opcode_name=="sb" || in_opcode_name=="sh" || in_opcode_name=="sw") begin
					if(tlb_ready==2) begin
						store_rd_wr<=1;
					end
					else if(cache_ready_READ==2) begin
						store_rd_wr<=2;
					end
					else if(cache_ready_WRITE==2) begin
						store_rd_wr<=0;
					end
				end
				if(in_opcode_name=="sd"||in_opcode_name=="sb" || in_opcode_name=="sh" || in_opcode_name=="sw")begin
					if(cache_ready_WRITE==2) begin
						out_mdata<=0;
					end
					else begin
						out_mdata<=0;
					end
				end

				if(in_opcode_name=="sb"||in_opcode_name=="sh"||in_opcode_name=="sw"||in_opcode_name=="sd")begin
					if(tlb_ready==2) begin
						out_phy_addr<=p_addr;
					end
					else begin
						out_phy_addr<=0;
					end
				end
				else begin
					out_phy_addr<=0;
				end
				if(in_opcode_name=="lw"||in_opcode_name=="lwu"||in_opcode_name=="lh"||in_opcode_name=="lhu"||in_opcode_name=="ld"||in_opcode_name=="lbu"||in_opcode_name=="lb")begin
                                        if(cache_ready_READ==2) begin
						case(in_opcode_name)
						"lb":begin
							if(in_alu_result[2:0]==0) begin
								out_mdata<=$signed(cache_data[7:0]);
							end
							else if(in_alu_result[2:0]==1) begin
								out_mdata<=$signed(cache_data[15:8]);
                                                        end
							else if(in_alu_result[2:0]==2) begin
								out_mdata<=$signed(cache_data[23:16]);
                                                        end
							else if(in_alu_result[2:0]==3) begin
								out_mdata<=$signed(cache_data[31:24]);
                                                        end
							else if(in_alu_result[2:0]==4) begin
								out_mdata<=$signed(cache_data[39:32]);
                                                        end
							else if(in_alu_result[2:0]==5) begin
								out_mdata<=$signed(cache_data[47:40]);
                                                        end
							else if(in_alu_result[2:0]==6) begin
								out_mdata<=$signed(cache_data[55:48]);
                                                        end
							else if(in_alu_result[2:0]==7) begin
								out_mdata<=$signed(cache_data[63:56]);
                                                        end
						end
						"lbu":begin
							if(in_alu_result[2:0]==0) begin
                                                                out_mdata<=cache_data[7:0];
                                                        end
                                                        else if(in_alu_result[2:0]==1) begin
                                                                out_mdata<=cache_data[15:8];
                                                        end
                                                        else if(in_alu_result[2:0]==2) begin
                                                                out_mdata<=cache_data[23:16];
                                                        end
                                                        else if(in_alu_result[2:0]==3) begin
                                                                out_mdata<=cache_data[31:24];
                                                        end
                                                        else if(in_alu_result[2:0]==4) begin
                                                                out_mdata<=cache_data[39:32];
                                                        end
                                                        else if(in_alu_result[2:0]==5) begin
                                                                out_mdata<=cache_data[47:40];
                                                        end
                                                        else if(in_alu_result[2:0]==6) begin
                                                                out_mdata<=cache_data[55:48];
                                                        end
                                                        else if(in_alu_result[2:0]==7) begin
                                                                out_mdata<=cache_data[63:56];
                                                        end
                                                end
						"lh":begin
							if(in_alu_result[2:0]==0) begin
                                                                out_mdata<=$signed(cache_data[15:0]);
                                                        end
                                                        else if(in_alu_result[2:0]==2) begin
                                                                out_mdata<=$signed(cache_data[31:16]);
                                                        end
                                                        else if(in_alu_result[2:0]==4) begin
                                                                out_mdata<=$signed(cache_data[47:32]);
                                                        end
                                                        else if(in_alu_result[2:0]==6) begin
                                                                out_mdata<=$signed(cache_data[63:48]);
                                                        end
                                                end
						"lhu":begin
							if(in_alu_result[2:0]==0) begin
                                                                out_mdata<=cache_data[15:0];
                                                        end
                                                        else if(in_alu_result[2:0]==2) begin
                                                                out_mdata<=cache_data[31:16];
                                                        end
                                                        else if(in_alu_result[2:0]==4) begin
                                                                out_mdata<=cache_data[47:32];
                                                        end
                                                        else if(in_alu_result[2:0]==6) begin
                                                                out_mdata<=cache_data[63:48];
                                                        end
                                                end
						"lw":begin
							if(in_alu_result[2:0]==0) begin
                                                                out_mdata<=$signed(cache_data[31:0]);
                                                        end
                                                        else if(in_alu_result[2:0]==4) begin
                                                                out_mdata<=$signed(cache_data[63:32]);
                                                        end
                                                end
						"lwu":begin
							if(in_alu_result[2:0]==0) begin
                                                                out_mdata<=cache_data[31:0];
                                                        end
                                                        else if(in_alu_result[2:0]==4) begin
                                                                out_mdata<=cache_data[63:32];
                                                        end
                                                end
						"ld":begin
							out_mdata<=$signed(cache_data);
                                                end
						endcase
                                        end
                                        else begin
                                                out_mdata<=0;
                                        end
                                end
                                else begin
                                        out_mdata<=0;
                                end//end of ld copcode condition
			end//if not syscall what to do
		end//if not reset
	end
endmodule
