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
  input  [63:0] stackptr,
  
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
  logic [8:0] counter;
  logic ready;
  logic [63:0] phy_addr;
  logic va_pa_abtr_grant;
  logic va_pa_abtr_reqcyc;
  logic va_pa_bus_busy;
  logic va_pa_enable;

  bus_controller bc    (.bus_reqcyc1(va_pa_abtr_reqcyc),
			.bus_grant1(va_pa_abtr_grant),
			.bus_busy(va_pa_bus_busy)
		       );

  va_to_pa va_to_pa1   (.clk(clk),
			.reset(reset),
			.ptbr(4096),
			.enable(va_pa_enable),
			.abtr_grant(va_pa_abtr_grant),
			.abtr_reqcyc(va_pa_abtr_reqcyc),
			.main_bus_respcyc(bus_respcyc),
			.main_bus_respack(bus_respack),
			.main_bus_resp(bus_resp),
			.main_bus_req(bus_req),
			.main_bus_reqcyc(bus_reqcyc),
			.main_bus_reqtag(bus_reqtag),
			.virt_addr(pc),
			.phy_addr(phy_addr),
			.ready(ready)
                       );
  always @ (posedge clk)
    if (reset) begin
      pc <= entry[63:12]<<12;
    end else begin
	if(ready) begin
		va_pa_enable <= 0;
		if(!phy_addr)
			$finish;
		pc <= pc +'d8;
		$display("TOP Virtual Addr: %d Physical Addr: %d", pc, phy_addr);
	end else begin
		va_pa_enable <= 1;
	end
    end

  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
