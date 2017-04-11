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
  logic [63:0] npc;
  logic [8:0] counter;
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
  enum {STATERESET=4'b0000, STATEVAPABEGIN=4'b0001, STATEVAPAWAIT=4'b0010,
        STATEADBEGIN=4'b0100, STATEADWAIT=4'b0101, STATEWDBEGIN=4'b0110, STATEWDWAIT=4'b0111} state, next_state;

  bus_controller bc    (.clk(clk),
            .bus_reqcyc1(va_pa_abtr_reqcyc),
            .bus_grant1(va_pa_abtr_grant),
            .bus_reqcyc2(addr_data_abtr_reqcyc),
            .bus_grant2(addr_data_abtr_grant),
            .bus_reqcyc3(store_data_abtr_reqcyc),
            .bus_grant3(store_data_abtr_grant),
            .bus_busy(va_pa_bus_busy|addr_data_bus_busy|store_data_bus_busy)
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
            .ready(va_pa_ready)
                       );

  addr_to_data addr_data(
            .clk(clk),
            .reset(reset),
            .enable(addr_data_enable),
            .abtr_grant(addr_data_abtr_grant),
            .abtr_reqcyc(addr_data_abtr_reqcyc),
            .main_bus_respcyc(bus_respcyc),
            .main_bus_respack(bus_respack),
            .main_bus_resp(bus_resp),
            .main_bus_req(bus_req),
            .main_bus_reqcyc(bus_reqcyc),
            .main_bus_reqtag(bus_reqtag),
            .addr(phy_addr),
            .data(data),
            .ready(addr_data_ready)
                       );

  store_data store_data_0(
            .clk(clk),
            .reset(reset),
            .enable(store_data_enable),
            .abtr_grant(store_data_abtr_grant),
            .abtr_reqcyc(store_data_abtr_reqcyc),
            .main_bus_respcyc(bus_respcyc),
            .main_bus_respack(bus_respack),
            .main_bus_resp(bus_resp),
            .main_bus_req(bus_req),
            .main_bus_reqcyc(bus_reqcyc),
            .main_bus_reqack(bus_reqack),
            .main_bus_reqtag(bus_reqtag),
            .addr(phy_addr),
            .data(data),
            .ready(store_data_ready)
                       );

    always_comb begin
        assign npc = pc + 64;
        case(state)
        STATERESET:
        begin
            assign next_state = STATEVAPABEGIN;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
        end
        STATEVAPABEGIN:
        begin
            assign next_state = STATEVAPAWAIT;
            assign va_pa_enable = 1;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
        end
        STATEVAPAWAIT:
        begin
            assign next_state = va_pa_ready? STATEADBEGIN : STATEVAPAWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
        end
        STATEADBEGIN:
        begin
            assign next_state = STATEADWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 1;
            assign store_data_enable = 0;
        end
        STATEADWAIT:
        begin
            assign next_state = addr_data_ready? STATEWDBEGIN : STATEADWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
        end
        STATEWDBEGIN:
        begin
            assign next_state = STATEWDWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 1;
        end
        STATEWDWAIT:
        begin
            assign next_state = store_data_ready? STATEVAPABEGIN : STATEWDWAIT;
            assign va_pa_enable = 0;
            assign addr_data_enable = 0;
            assign store_data_enable = 0;
        end
        endcase
    end
    always @ (posedge clk) begin
        if (reset) begin
            state <= STATERESET;
            pc <= entry[63:12]<<12;
        end else begin
            if(addr_data_ready & !data)
                $finish;
            state <= next_state;
            case(state)
            STATEADBEGIN:
            begin
                $display("TOP virtual address: %d physical address: %d", pc, phy_addr);
                pc <= npc;
            end
            STATEWD:
            begin
                $display("TOP data: %x", data[63:0]);
            end
            endcase
        end
    end
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
