`define ADD2DATA
module addr_to_data
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
    input abtr_grant,
    output abtr_reqcyc,
    output bus_busy,
    input main_bus_respcyc,
    input [BUS_DATA_WIDTH-1:0] main_bus_resp,
    output main_bus_respack,
    output main_bus_reqcyc,
    output [BUS_DATA_WIDTH-1:0] main_bus_req,
    output ready,
    input [BUS_DATA_WIDTH-1:0] addr,
    output [BUS_DATA_WIDTH*8-1:0] data,
    output [BUS_TAG_WIDTH-1:0] main_bus_reqtag
);
    logic[3:0] counter;
    logic[3:0] ncounter;
    logic [BUS_DATA_WIDTH-1:0] response;
    enum {STATERESET=3'b000, STATEBEGIN=3'b001, STATEREQ=3'b010, STATEWAIT=3'b011,
          STATERESP=3'b100, STATEREADY=3'b101} state, next_state;
    always_comb begin
        assign ncounter = counter + 1;
        case(state)
            STATERESET: next_state = enable? STATEBEGIN : STATERESET;
            STATEBEGIN: next_state = abtr_grant? STATEREQ : STATEBEGIN;
            STATEREQ: next_state = STATEWAIT;
            STATEWAIT: next_state = main_bus_respcyc? STATERESP: STATEWAIT;
            STATERESP:
                if (counter < 8) begin
                    next_state = STATERESP;
                end else begin
		    next_state = STATEREADY;
                end
            STATEREADY:
                next_state = enable? STATEBEGIN : STATEREADY;
        endcase
        case(next_state)
            STATERESET:
            begin
                assign abtr_reqcyc = 0;
                assign ready = 0;
            end
            STATEBEGIN:
            begin
                assign abtr_reqcyc = 1;
                assign ready = 0;
            end
            STATEREQ:
            begin
                assign bus_busy = 1;
                assign main_bus_reqcyc = 1;
                assign main_bus_respack = 0;
                assign main_bus_req[63:0] = (addr[63:6] << 6);
                assign main_bus_reqtag = `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
                assign ready = 0;
            end
            STATEWAIT:
            begin
                assign main_bus_reqcyc = 0;
                assign main_bus_respack = 0;
                assign ready = 0;
            end
            STATERESP:
            begin
                assign main_bus_respack = 1;
                assign ready = 0;
                case(counter)
                    1:
                        assign data[63:0] = response[63:0];
                    2:
                        assign data[127:64] = response[63:0];
                    3:
                        assign data[191:128] = response[63:0];
                    4:
                        assign data[255:192] = response[63:0];
                    5:
                        assign data[319:256] = response[63:0];
                    6:
                        assign data[383:320] = response[63:0];
                    7:
                        assign data[447:384] = response[63:0];
                    8:
                        assign data[511:448] = response[63:0];
                endcase
            end
            STATEREADY:
            begin
                assign bus_busy = 0;
                assign abtr_reqcyc = 0;
                assign ready = 1;
            end
        endcase
    end

    always_ff @ (posedge clk) begin
        if(reset) begin
            state <= STATERESET;
`ifdef ADD2DATA
            $display("AD State resetted");
`endif
        end else begin
            state <= next_state;
            case(next_state)
                STATEBEGIN:
                begin
`ifdef ADD2DATA
                    $display("AD State begin, going to req");
`endif
                end
                STATEREQ:
                begin
                    //main_bus_req[63:0] <= addr[63:6] << 6;
`ifdef ADD2DATA
                    $display("AD State req, going to wait");
                    $display("AD State req, req: %d", main_bus_req);
`endif
                end
                STATEWAIT:
                begin
                    //$display("State wait, going to resp");
                    counter <= 0;
                end
                STATERESP:
                begin
`ifdef ADD2DATA
                    $display("AD State resp, going to ready");
                    $display("AD data: %x", main_bus_resp[63:0]);
`endif
                    counter <= ncounter;
                    response <= main_bus_resp;
                end
                STATEREADY:
                begin
`ifdef ADD2DATA
                    $display("AD State ready");
`endif
                    counter <= counter;
                end
            endcase
        end
    end

    always_comb begin
    end
endmodule
