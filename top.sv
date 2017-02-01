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
  logic [8:0] no_of_bytes;
  always @ (posedge clk)
    if (reset) begin
      pc <= entry;
      no_of_bytes <= 'd8;
    end else begin
      if(bus_respcyc)
      begin
        if(!bus_resp)
          $finish;
        else begin
          $display("Hello World!  @ %x", pc);
          $display("bus_resp %h", bus_resp);
          $display("bus_resptag %h", bus_resptag);
          $display("");
          pc <= pc + 8;
          bus_req <= pc;
          bus_respack <= bus_respcyc;
          bus_reqcyc <= 0;
          no_of_bytes <= no_of_bytes +1;
        end
      end

      if(no_of_bytes == 'd8)
      begin
        bus_respack <= 0;
        bus_reqcyc <= 1;
        bus_req <= pc;
        bus_reqtag <= `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
        $display("bus_reqtag %b", bus_reqtag);
        no_of_bytes <= 0;
      end else begin
        bus_reqcyc <= 0;
      end
    end

  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
