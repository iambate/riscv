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
  logic out_ready;
  logic [REGISTER_WIDTH-1:0] wb_wbdata;
  logic [REGISTERNO_WIDTH-1:0] wb_rd_regno;
  logic [REGISTER_WIDTH-1:0] going2wb_wbdata;
  logic [REGISTERNO_WIDTH-1:0] going2wb_rd_regno;

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

  fetch fetch_stage(	.clk(clk),
			.reset(reset),
			.in_branch_taken_bool(0),
		//	.in_target(in_target),
			.in_enable(1),
//			.out_pcplus1(),
			.out_instruction_bits(fetch_instruction_bits),
			.out_ready(out_ready),
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
			.store_data_abtr_grant(store_data_abtr_reqcyc),
			.store_data_abtr_reqcyc(store_data_abtr_reqcyc),
			.store_data_bus_busy(addr_data_abtr_reqcyc),
			.addr_data_bus_busy(addr_data_bus_busy));
    always_comb begin
    //    assign npc = pc + 64;
/*
        case(state)
        STATERESET:
        begin
            assign next_state = STATEVAPABEGIN;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
            assign fetch_ready = 0;
        end
        STATEVAPABEGIN:
        begin
            assign next_state = STATEVAPAWAIT;
            assign va_pa_enable = 1;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
            assign fetch_ready = 0;
        end
        STATEVAPAWAIT:
        begin
            assign next_state = va_pa_ready? STATEADBEGIN : STATEVAPAWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
            assign fetch_ready = 0;
        end
        STATEADBEGIN:
        begin
            assign next_state = STATEADWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 1;
            assign store_data_enable = 0;
            assign fetch_ready = 0;
        end
        STATEADWAIT:
        begin
            assign next_state = addr_data_ready? STATEEXEC : STATEADWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
            assign fetch_ready = 0;
        end
        STATEWDBEGIN:
        begin
            assign next_state = STATEWDWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 1;
            assign fetch_ready = 0;
        end
        STATEWDWAIT:
        begin
            assign next_state = store_data_ready? STATEEXEC : STATEWDWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
            assign fetch_ready = 0;
        end
        STATEEXEC:
        begin
            assign next_state = (counter==15)? STATEVAPABEGIN : STATEEXEC;
            assign ncounter = counter + 1;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
            assign fetch_ready = 1;
        end
        endcase*/
    end
    always @ (posedge clk) begin
        if (reset) begin
   //         state <= STATERESET;
            pc <= 0;
        end else begin
/*
            if(addr_data_ready & !data && state == STATEEXEC) begin
                display_regs <= 1;
            end else if (addr_data_ready & !data && state == STATEVAPABEGIN) begin
                $finish;
            end
            state <= next_state;
            case(state)
            STATEADBEGIN:
            begin
                $display("TOP virtual address: %d physical address: %d", pc, phy_addr);
                old_pc <= pc;
                pc <= npc;
                counter <= 0;
            end
            STATEVAPABEGIN:
            begin
                //$display("TOP data: %x", data);
            end
            STATEEXEC:
            begin
                if(alu_ready) begin
                  counter <= ncounter;
                  $display();
                  case(counter)
                  0:
                  begin
                    fetch_pc <= old_pc + 4;
                    fetch_instruction_bits <= data[SIZE*0+SIZE-1:SIZE*0];
                    $display("TOP 0 data: %x", data[SIZE*0+SIZE-1:SIZE*0]);
                  end
                  1:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*1+SIZE-1:SIZE*1];
                    $display("TOP 1 data: %x", data[SIZE*1+SIZE-1:SIZE*1]);
                  end
                  2:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*2+SIZE-1:SIZE*2];
                    $display("TOP 2 data: %x", data[SIZE*2+SIZE-1:SIZE*2]);
                  end
                  3:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*3+SIZE-1:SIZE*3];
                    $display("TOP 3 data: %x", data[SIZE*3+SIZE-1:SIZE*3]);
                  end
                  4:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*4+SIZE-1:SIZE*4];
                    $display("TOP 4 data: %x", data[SIZE*4+SIZE-1:SIZE*4]);
                  end
                  5:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*5+SIZE-1:SIZE*5];
                    $display("TOP 5 data: %x", data[SIZE*5+SIZE-1:SIZE*5]);
                  end
                  6:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*6+SIZE-1:SIZE*6];
                    $display("TOP 6 data: %x", data[SIZE*6+SIZE-1:SIZE*6]);
                  end
                  7:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*7+SIZE-1:SIZE*7];
                    $display("TOP 7 data: %x", data[SIZE*7+SIZE-1:SIZE*7]);
                  end
                  8:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*8+SIZE-1:SIZE*8];
                    $display("TOP 8 data: %x", data[SIZE*8+SIZE-1:SIZE*8]);
                  end
                  9:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*9+SIZE-1:SIZE*9];
                    $display("TOP 9 data: %x", data[SIZE*9+SIZE-1:SIZE*9]);
                  end
                  10:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*10+SIZE-1:SIZE*10];
                    $display("TOP 10 data: %x", data[SIZE*10+SIZE-1:SIZE*10]);
                  end
                  11:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*11+SIZE-1:SIZE*11];
                    $display("TOP 11 data: %x", data[SIZE*11+SIZE-1:SIZE*11]);
                  end
                  12:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*12+SIZE-1:SIZE*12];
                    $display("TOP 12 data: %x", data[SIZE*12+SIZE-1:SIZE*12]);
                  end
                  13:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*13+SIZE-1:SIZE*13];
                    $display("TOP 13 data: %x", data[SIZE*13+SIZE-1:SIZE*13]);
                  end
                  14:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*14+SIZE-1:SIZE*14];
                    $display("TOP 14 data: %x", data[SIZE*14+SIZE-1:SIZE*14]);
                  end
                  15:
                  begin
                    fetch_pc <= fetch_pc + 4;
                    fetch_instruction_bits <= data[SIZE*15+SIZE-1:SIZE*15];
                    $display("TOP 15 data: %x", data[SIZE*15+SIZE-1:SIZE*15]);
                  end
                  endcase
                end
            end
            endcase
*/
        end
    end
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule