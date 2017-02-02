`include "Sysbus.defs"

module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
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
  logic [63:0] prev_pc;
  logic [8:0] counter;
  always @ (posedge clk)//note: all statements run in parallel
    if(reset) begin
	pc <= entry;
	prev_pc<=entry;
	counter <= 'd8;
    end
    else begin
	if(bus_respcyc) begin
	     if(!bus_resp) begin
		$finish;
	     end
	     else if (!bus_resp[63:32]) begin
		$display("%x\t%h",prev_pc+counter*'d8,bus_resp[31:0]);
		$finish;
	     end
	     else begin
		$display("%x\t%h",prev_pc+counter*'d8,bus_resp[31:0]);
		$display("%x\t %h", prev_pc+counter*'d8+'d4,bus_resp[63:32]);
		$display("");
		bus_respack <= 1;
		counter <= counter+'d1;
  	     end
	end
	else begin
	     bus_respack <= 0;
	end

	if(counter == 'd8) begin
	     prev_pc<=pc;
	     pc<=pc+'d64;
             bus_req<=pc;
	     bus_reqcyc<=1;
	     bus_reqtag<=`SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
	     counter<='d0;
	end
	else begin
	     bus_reqcyc<=0;
	end
    end
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
