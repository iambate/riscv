//`define VAPADEBUG
//`define VAPADEBUGEXTRA
module va_to_pa
#(
    BUS_DATA_WIDTH = 64,
    TYPE_WIDTH = 3,
    REGISTER_WIDTH = 5,
    REGISTER_NAME_WIDTH = 4,
    IMMEDIATE_WIDTH = 32,
    FLAG_WIDTH = 16,
    BUS_TAG_WIDTH = 13,
    INSTRUCTION_NAME_WIDTH = 12
)
(
    input clk,
    input reset,
    input enable,
    input [BUS_DATA_WIDTH-1:0] ptbr,
    input abtr_grant,
    output abtr_reqcyc,
    output bus_busy,
    input main_bus_respcyc,
    input [BUS_DATA_WIDTH-1:0] main_bus_resp,
    output main_bus_respack,
    output main_bus_reqcyc,
    output [BUS_DATA_WIDTH-1:0] main_bus_req,
    output ready,
    input [BUS_DATA_WIDTH-1:0] virt_addr,
    output [BUS_DATA_WIDTH*8-1:0] phy_addr_array,
    input [BUS_TAG_WIDTH-1:0] main_bus_resptag,
    output [BUS_TAG_WIDTH-1:0] main_bus_reqtag
);
    logic[3:0] counter;
    logic[3:0] ncounter;
    logic[2:0] level;
    logic[2:0] nlevel;
    logic[3:0] request_counter;
    logic[11:0] pt_no;
    logic[BUS_DATA_WIDTH-1:0] request_addr;
    enum {STATERESET=3'b000, STATEBEGIN=3'b001, STATEREQ=3'b010, STATEWAIT=3'b011,
          STATERESP=3'b100, STATERESPEND=3'b101, STATEREADY=3'b111} state, next_state;
    always_comb begin
        case(state)
            STATERESET: next_state = enable? STATEBEGIN : STATERESET ;
            STATEBEGIN: next_state = abtr_grant? STATEREQ : STATEBEGIN;
            STATEREQ: next_state = STATEWAIT;
            STATEWAIT: next_state = main_bus_respcyc? STATERESP: STATEWAIT;
            STATERESP:
                if (counter < 8) begin
                    next_state = STATERESP;
                end else begin
                    if (level < 4) begin
                        next_state = STATERESPEND;
                    end else begin
                        next_state = STATERESPEND;
                    end
                end
            STATERESPEND:
                next_state = (level < 4)? STATERESP : STATEREADY ;
            STATEREADY:
                next_state = enable? STATEBEGIN : STATEREADY;
        endcase
        assign nlevel = level + 1;
        assign ncounter = counter + 1;
        case(level)
            1:
            begin
                assign pt_no = virt_addr[38:30] << 3;
            end
            2:
            begin
                assign pt_no = virt_addr[29:21] << 3;
            end
            3:
            begin
                assign pt_no = virt_addr[20:12] << 3;
            end
        endcase
        case(next_state)
            STATERESET:
            begin
                assign bus_busy = 0;
                assign ready = 0;
                assign abtr_reqcyc = 0;
            end
            STATEBEGIN:
            begin
                assign bus_busy = 0;
                assign ready = 0;
                assign abtr_reqcyc = 1;
            end
            STATEREQ:
            begin
                assign bus_busy = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_reqcyc = 1;
                assign main_bus_reqtag = `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
                assign main_bus_req = request_addr[63:6] << 6;
            end
            STATEWAIT:
            begin
                assign bus_busy = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_reqcyc = 0;
                assign main_bus_reqtag = 0;
                assign main_bus_req = 0;
            end
            STATERESP:
            begin
                assign bus_busy = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_reqcyc = 0;
                if(main_bus_reqtag == `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8) begin
                    assign main_bus_respack = 1;
                end
                assign main_bus_reqtag = 0;
                assign main_bus_req = 0;
            end
            STATERESPEND:
            begin
                assign bus_busy = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_reqcyc = 0;
                assign main_bus_reqtag = 0;
                assign main_bus_req = 0;
                if(main_bus_reqtag == `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8) begin
                    assign main_bus_respack = 1;
                end
            end
            STATEREADY:
            begin
                assign ready = 1;
                assign bus_busy = 0;
                assign abtr_reqcyc = 0;
            end
        endcase
    end

    always_ff @ (posedge clk) begin
        if(reset) begin
            state <= STATERESET;
            level <= 0;
            //request_addr[63:0] <= ptbr[63:0] + virt_addr[47:39];
`ifdef VAPADEBUG
            $display("VP state resetted");
            $display("VP Virt Addr to: %d",virt_addr[47:39]);
`endif
        end else begin
            state <= next_state;
            case(next_state)
                STATEBEGIN:
                begin
`ifdef VAPADEBUG
                    $display("VP State begin, going to req");
		    $display("VP Virt Addr to: %d",virt_addr);
		    $display("VP PTE: %d",virt_addr[47:39]);
		    $display("VP requested addr: %d",ptbr[63:0] + virt_addr[47:39]);
`endif
                    level <= 0;
                    request_addr[63:0] <= ptbr[63:0] + virt_addr[47:39];
                end
                STATEREQ:
                begin
`ifdef VAPADEBUG
                    $display("VP State req, going to wait, level: %d", level);
                    $display("VP Main Bus Req: %d", main_bus_req);
                    $display("VP Main Bus addr: %d", request_addr);
                    $display("VP virt_addr: %d", virt_addr);
`endif
                    level <= nlevel;
	                    request_counter <= request_addr[5:3];
                end
                STATEWAIT:
                begin
`ifdef VAPADEBUGEXTRA
		$display("VP Wait state");
`endif
                    level <= level;
                    counter <= 0;
                end
                STATERESP:
                begin
                    if(main_bus_resptag == (`SYSBUS_READ<<12|`SYSBUS_MEMORY<<8)) begin
`ifdef VAPADEBUG
                      $display("VP State resp, going to ready, request_counter: %d", request_counter);
`endif
                      level <= level;
                      counter <= ncounter;
                      if(level == 4) begin
`ifdef VAPADEBUG
                        $display("VP PTEs: %d", main_bus_resp[63:0]);
                        $display("VP Physical address: %d", main_bus_resp[63:10]<<12);
`endif
                        case(counter)
                        0:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*0+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*0] <= main_bus_resp[63:0];
                        end
                        1:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*1+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*1] <= main_bus_resp[63:0];
                        end
                        2:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*2+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*2] <= main_bus_resp[63:0];
                        end
                        3:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*3+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*3] <= main_bus_resp[63:0];
                        end
                        4:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*4+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*4] <= main_bus_resp[63:0];
                        end
                        5:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*5+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*5] <= main_bus_resp[63:0];
                        end
                        6:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*6+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*6] <= main_bus_resp[63:0];
                        end
                        7:
                        begin
                          phy_addr_array[BUS_DATA_WIDTH*7+BUS_DATA_WIDTH-1:BUS_DATA_WIDTH*7] <= main_bus_resp[63:0];
                        end
                        endcase
                      end else begin
                        if(counter == request_counter) begin
`ifdef VAPADEBUG
                            $display("VP For next, pt_no: %d", pt_no);
                            $display("VP request addr: %d", (main_bus_resp[63:10] << 12) + pt_no[11:0]);
`endif
                            request_addr <= (main_bus_resp[63:10] << 12) + pt_no[11:0];
                        end
                      end
                    end
                end
                STATEREADY:
                begin
`ifdef VAPADEBUGEXTRA
                    $display("VP State ready");
`endif
                    level <= 0;
                    counter <= counter;
                end
            endcase
        end
    end

    always_comb begin
    end
endmodule
