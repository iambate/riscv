`include "DCache.sv"
module mm
#(
  ADDRESS_WIDTH = 64,
  REGISTER_WIDTH = 64,
  REGISTERNO_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4*8,
  INSTRUCTION_WIDTH = 32,
  INSTRUCTION_NAME_WIDTH = 12*8,
  FLAG_WIDTH = 16,
  READ_SIGNAL=1,
  WRITE_SIGNAL=2,
  
)
(
  input clk,
  input reset,
  input in_enable,
  input [REGISTER_WIDTH-1:0] in_alu_result,//this should have addr in case of store
  input [REGISTER_WIDTH-1:0] in_rs2_value,
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input in_mm_load_bool,
  input in_update_rd_bool,
  input [INSTRUCTION_NAME_WIDTH-1:0] in_opcode_name,
  output out_update_rd_bool,
  input in_syscall_flush,
  output out_mm_load_bool,
  input [63:0] in_pcplus1plusoffs,
  output [63:0] out_mem_pcplus1plusoffs,
  output [REGISTER_WIDTH-1:0] out_mdata,
  output [REGISTER_WIDTH-1:0] out_alu_result,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [INSTRUCTION_NAME_WIDTH-1:0] out_opcode_name,
  output out_ready,
  output out_rs2_val,
  output [63:0] out_phy_addr
);
//TODO:
//in_syscall_flush,pc_value passed to 
  // Instantiate Cache and set cache_data as output to be filled
  // data_ready=1 is the signal from cache saying data is ready
  logic data_ready;
  logic tlb_rd_signal;
  logic cache_enable;
  logic not_mm_req;
  logic [1:0] cache_signal;
  logic [REGISTER_WIDTH-1:0] cache_data;
  logic [REGISTER_WIDTH-1:0] n_mdata;
  logic [1:0] cache_ready_READ;
  logic [1:0] cache_ready_WRITE;
  logic [64:0] write_data;
/*
TODO:
1) store-read first then write
5) if rd_signal given wait on data_available , if wr signal wait on can_Write
when flush signal is high cache wont read or write but it will still invalidate
6) rs2 and pc value for sys call flush time
*/


  Trans_Lookaside_Buff Dtlb(    .clk(clk),
                                .reset(reset),
                                .v_addr(in_alu_result),
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

  D_Set_Associative_Cache DCache( .clk(clk),
                                .reset(reset),
                                .addr(p_addr),
                                .enable(tlb_ready==2 & cache_enable),
                                .rd_wr_evict_flag(cache_signal),
                                .read_data(cache_data),
                                .data_available(cache_ready_READ),//signal which fetch needs to wait on
				.canWrite(cache_ready_WRITE),
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
				.write_data(write_data)
                                );

  always_comb begin
    if(in_syscall_flush) begin
	assign tlb_rd_signal=0;
        assign cache_enable=0;
    end
    else begin
        assign tlb_rd_signal=1;
        assign cache_enable=1;
    end
    // default its not a mm_req, if it is set it below
    assign not_mm_req = 1;
    case(in_opcode_name)
//for all stores,read from cache_data and write to write_data using in_rs2_value
    "sb":begin
	assign cache_signal=WRITE_SIGNAL;
    end
    "sh":begin
	assign cache_signal=WRITE_SIGNAL;
    end
    "sw":begin
	assign cache_signal=WRITE_SIGNAL;
    end
    "sd": begin
	assign cache_signal=WRITE_SIGNAL;
    end
    "lw": begin
      assign cache_signal=READ_SIGNAL;
      assign not_mm_req = 0;
      assign n_mdata[31:0] = cache_data[31:0];
      if(cache_data[31]) begin
        assign n_mdata[REGISTER_WIDTH-1:32] = -1;
      end else begin
        assign n_mdata[REGISTER_WIDTH-1:32] = 0;
      end
    end
    "lwu": begin
      assign cache_signal=READ_SIGNAL;
      assign not_mm_req = 0;
      assign n_mdata[31:0] = cache_data[31:0];
      assign n_mdata[REGISTER_WIDTH-1:32] = 0;
    end
    "lh": begin
      assign cache_signal=READ_SIGNAL;
      assign not_mm_req = 0;
      assign n_mdata[15:0] = cache_data[15:0];
      if(cache_data[15]) begin
        assign n_mdata[REGISTER_WIDTH-1:16] = -1;
      end else begin
        assign n_mdata[REGISTER_WIDTH-1:16] = 0;
      end
    end
    "lhu": begin
      assign cache_signal=READ_SIGNAL;
      assign not_mm_req = 0;
      assign n_mdata[15:0] = cache_data[15:0];
      assign n_mdata[REGISTER_WIDTH-1:16] = 0;
    end
    "lb": begin
      assign cache_signal=READ_SIGNAL;
      assign not_mm_req = 0;
      assign n_mdata[7:0] = cache_data[7:0];
      if(cache_data[7]) begin
        assign n_mdata[REGISTER_WIDTH-1:8] = -1;
      end else begin
        assign n_mdata[REGISTER_WIDTH-1:8] = 0;
      end
    end
    "lbu": begin
      assign cache_signal=READ_SIGNAL;
      assign not_mm_req = 0;
      assign n_mdata[7:0] = cache_data[7:0];
      assign n_mdata[REGISTER_WIDTH-1:8] = 0;
    end
    "ld": begin
      assign cache_signal=READ_SIGNAL;
      assign not_mm_req = 0;
      assign n_mdata[REGISTER_WIDTH-1:0] = cache_data[REGISTER_WIDTH-1:0];
    end
    endcase

    // this stage ready if a. its not a mm req or b. data is ready
    assign out_ready = data_ready | not_mm_req;
  end


  always_ff @(posedge clk) begin
    if(reset) begin
      //TODO: Add reset things here
      out_mm_load_bool <= 0;
      out_alu_result <= 0;
      out_rd_regno <= 0;
      out_update_rd_bool <= 0;
      out_mdata <= 0;
      out_opcode_name <= 0;
    end else begin
      if(in_enable & out_ready) begin
`ifdef MMDEBUG
        $display("MM mm_load_bool %d", in_mm_load_bool);
        $display("MM alu result %d", in_alu_result);
        $display("MM rd regno %d", in_rd_regno);
        $display("MM update rd bool %d", in_update_rd_bool);
        $display("MM mdata %d", n_mdata);
`endif
	case(in_opcode_name)
	"sb":begin
		if(tlb_ready==2) begin
			out_phy_addr<=p_addr;
		end
	end
	"sh":begin
		if(tlb_ready==2) begin
                        out_phy_addr<=p_addr;
                end
	end
	"sw":begin
		if(tlb_ready==2) begin
                        out_phy_addr<=p_addr;
                end
	end
	"sd":begin
		if(tlb_ready==2) begin
                        out_phy_addr<=p_addr;
                end
	end
	default:begin
		out_phy_addr<=0;
	end
	endcase
	out_mem_pcplus1plusoffs<=in_pcplus1plusoffs;
        out_mm_load_bool <= in_mm_load_bool;
        out_alu_result <= in_alu_result;
        out_rd_regno <= in_rd_regno;
        out_update_rd_bool <= in_update_rd_bool;
        out_mdata <= n_mdata;
        out_opcode_name <= in_opcode_name;
      end
    end
  end
endmodule
