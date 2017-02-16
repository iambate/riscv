`include "Sysbus.defs"
`include "Opcodes.defs"
`include "process_instruction.sv"
`include "instruction_types.defs"
`include "get_output_string.sv"
module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,
  REGISTER_NAME_WIDTH = 4,
  REGISTER_WIDTH = 5,
  IMMEDIATE_WIDTH = 32,
  FLAG_WIDTH = 16,
  INSTRUCTION_NAME_WIDTH = 12
)
(
  input  clk,
         reset,

  // 64-bit address of the program entry point
  input  [63:0] entry,
  
  // interface to connect to the bus
  output bus_reqcyc,//set when sending a request
  output bus_respack,//set after receiving data rom the dram
  output [BUS_DATA_WIDTH-1:0] bus_req,//pc value
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,//READ OR MEMORY
  input  bus_respcyc,//if tx_queue is not empty respcyc is set
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,//bus_resp contains data
  input  [BUS_TAG_WIDTH-1:0] bus_resptag
);

  logic [63:0] pc;
  logic [63:0] npc;
  logic [63:0] prev_pc;
  logic [8:0] counter;
  logic [BUS_TAG_WIDTH-1:0] tag;
  logic [8:0] ncounter;
  logic [REGISTER_NAME_WIDTH*8:0] rs1;
  logic [REGISTER_NAME_WIDTH*8:0] rs2;
  logic [REGISTER_NAME_WIDTH*8:0] rd;
  logic signed [IMMEDIATE_WIDTH-1:0] imm;
  logic unsigned [FLAG_WIDTH-1: 0] flag;
  logic [INSTRUCTION_NAME_WIDTH*8:0] instruction_name;
  logic [BUS_DATA_WIDTH/2 -1:0] nstage1_instruction_bits;
  logic alternator;
  logic nalternator;
  logic nbus_respack;
  logic [63:0] nstage1_pc;
  logic [63:0] stage1_pc;

  process_instruction inst_1 (nstage1_instruction_bits, rd, rs1, rs2, imm, flag, instruction_name);

  always_comb begin
    assign npc = pc+'d64;
    assign nstage1_pc = stage1_pc + 'd4;
    assign bus_reqtag = `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
    assign ncounter = counter + 'd1;
    assign nalternator = alternator + 'd1;
    if (alternator == 'b1) begin
      assign nstage1_instruction_bits = bus_resp[31:0];
      assign nbus_respack = 0;
    end else begin
      assign nstage1_instruction_bits = bus_resp[63:32];
      assign nbus_respack = 1;
    end
  end
  always @ (posedge clk)//note: all statements run in parallel
    if(reset) begin
	pc <= entry;
	stage1_pc <= entry;
	counter <= 'd16;
	alternator <= 'b1;
    end
    else begin
	if(bus_respcyc) begin
	     if(!nstage1_instruction_bits) begin
		$finish;
	     end
	     else begin
		alternator <= alternator + 'b1;
		stage1_pc <= nstage1_pc;
		$write("%0x:\t%x\t",stage1_pc, nstage1_instruction_bits);
		get_output_string(stage1_pc, rd, rs1, rs2, imm, flag, instruction_name);
		bus_respack <= nbus_respack;
  	     end
	end
	else begin
	     bus_respack <= 0;
	end

	if(counter == 'd16) begin
	     pc<=npc;
             bus_req<=pc;
	     bus_reqcyc<=1;
	     counter<='d0;
	end
	else if (counter != 'd16 && bus_respcyc)
	    counter <= ncounter;//implement as assign new_counter=counter+'d1 and counter <= new_counter
	else begin
	    bus_reqcyc<=0;
	end
    end
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
