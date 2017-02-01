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
  logic [8:0] counter;
  always @ (posedge clk)
    if (reset) begin
      pc <= entry;
      counter <= 'd8;
    end else begin
      if(bus_respcyc) begin
        if(!bus_resp) begin
          $finish;
        end else begin
          $display("Hello World!  @ %x", pc);
          $display("bus_resp %h", bus_resp[31:0]);
          $display("bus_resp %h", bus_resp[63:32]);
          $display("bus_resptag %h", bus_resptag);
          $display("");
          pc <= pc + 8;
          // Keep the value of pc and bus_req same
          bus_req <= pc + 8;
          bus_respack <= bus_respcyc;
          counter <= counter +1;
        end
      end else begin
         bus_respack <= 0;
      end

      if(counter == 'd8) begin
        bus_reqcyc <= 1;
        bus_reqtag <= `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
        counter <= 0;
      end else begin
        bus_reqcyc <= 0;
      end
    end

  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
