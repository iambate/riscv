`include "Sysbus.defs"
`include "Opcodes.defs"

module Process_Instruction
#(
  BUS_DATA_WIDTH = 64 
)
(
  input [31:0] inst,
  output [8:0] ans
);
  always_comb begin
    casex (inst)
	`ADDI:assign ans =1;
	`SD:assign ans = 2;
	default:assign ans =3;
    endcase
  end
//process inst to provide output in ans string
endmodule

module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,
  REGISTER_NAME_WIDTH = 4,
  REGISTER_WIDTH = 5
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
  logic [8:0] output1;
  logic [8:0] output2;
  logic [REGISTER_WIDTH*8:0] rs1;
  logic [REGISTER_WIDTH*8:0] rs2;
  logic [REGISTER_WIDTH*8:0] rd;
  Process_Instruction inst_1 (bus_resp[31:0],output1);
  Process_Instruction inst_2 (bus_resp[63:32],output2);

  always_comb begin
    assign npc = pc+'d64;
    assign bus_reqtag = `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
    assign ncounter = counter+'d1;
  end
  always @ (posedge clk)//note: all statements run in parallel
    if(reset) begin
	pc <= entry;
	counter <= 'd8;
    end
    else begin
	if(bus_respcyc) begin
	     if(!bus_resp) begin
		$finish;
	     end
	     else if (!bus_resp[63:32]) begin
		$display("%h",bus_resp[31:0]);
		$display("%h",output1);
		$finish;
	     end
	     else begin
		$display("%h",bus_resp[31:0]);
		$display("%h",output1);
		$display("");
		$display("%h", bus_resp[63:32]);
		$display("%h",output2);
		$display("");
		bus_respack <= 1;
  	     end
	end
	else begin
	     bus_respack <= 0;
	end

	if(counter == 'd8) begin
	     pc<=npc;
             bus_req<=pc;
	     bus_reqcyc<=1;
	     counter<='d0;
	end
	else if (counter != 'd8 && bus_respcyc)
	    counter <= ncounter;//implement as assign new_counter=counter+'d1 and counter <= new_counter
	else begin
	    bus_reqcyc<=0;
	end
    end
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
