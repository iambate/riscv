
module store_data
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
    input main_bus_reqack,
    output [BUS_DATA_WIDTH-1:0] main_bus_req,
    output ready,
    input [BUS_DATA_WIDTH-1:0] addr,
    input [BUS_DATA_WIDTH*8-1:0] data,
    input [BUS_TAG_WIDTH-1:0] main_bus_resptag,
    output [BUS_TAG_WIDTH-1:0] main_bus_reqtag
);
    logic[3:0] counter;
    logic[3:0] ncounter;
    enum {STATERESET=3'b000, STATEBEGIN=3'b001, STATEADDRREQ=3'b010, STATEREQ=3'b011,
          STATEREQEND=3'b100, STATEREADY=3'b101} state, next_state;
    always_comb begin
        case(state)
            STATERESET: next_state = enable? STATEBEGIN : STATERESET;
            STATEBEGIN: next_state = abtr_grant? STATEADDRREQ : STATEBEGIN;
            STATEADDRREQ: next_state = STATEREQ;
            STATEREQ:
                if (counter < 8) begin
                    next_state = STATEREQ;
                end else begin
                    next_state = STATEREADY;
                end
            STATEREQEND:
                next_state = STATEREADY;
            STATEREADY:
                next_state = enable? STATEBEGIN : STATEREADY;
        endcase
        assign ncounter = counter + 1;
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
            STATEADDRREQ:
            begin
                assign bus_busy = 1;
                assign main_bus_reqcyc = 1;
                assign main_bus_respack = 0;
                assign main_bus_req[63:0] = (addr[63:6] << 6);
                assign main_bus_reqtag = `SYSBUS_WRITE<<12|`SYSBUS_MEMORY<<8;
                assign ready = 0;
            end
            STATEREQ:
            begin
                assign bus_busy = 1;
                assign main_bus_reqcyc = 1;
                assign main_bus_respack = 1;
                assign main_bus_reqtag = `SYSBUS_WRITE<<12|`SYSBUS_MEMORY<<8;
                case(counter)
                    0:
                        assign main_bus_req[63:0] = data[63:0];
                    1:
                        assign main_bus_req[63:0] = data[127:64];
                    2:
                        assign main_bus_req[63:0] = data[191:128];
                    3:
                        assign main_bus_req[63:0] = data[255:192];
                    4:
                        assign main_bus_req[63:0] = data[319:256];
                    5:
                        assign main_bus_req[63:0] = data[383:320];
                    6:
                        assign main_bus_req[63:0] = data[447:384]; 
                    7:
                        assign main_bus_req[63:0] = data[511:448]; 
                endcase
            end
            STATEREQEND:
            begin
                assign ready = 0;
                assign bus_busy = 1;
                assign abtr_reqcyc = 1;
                assign main_bus_reqcyc = 0;
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
`ifdef WDDEBUG
            $display("WD State resetted");
`endif
        end else begin
            state <= next_state;
            case(next_state)
                STATEBEGIN:
                begin
                    //$display("State begin, going to req");
                end
                STATEADDRREQ:
                begin
                    //main_bus_req[63:0] <= addr[63:6] << 6;
                    $display("WD State addr req");
                    counter <= 0;
                end
                STATEREQ:
                begin
                    $display("WD State req, going to ready");
                    counter <= ncounter;
                    $display("WD data: %d", main_bus_resp[63:0]);
                    $display("WD reqack: %d", main_bus_reqack);
                end
                STATEREADY:
                begin
                    //$display("WD State ready");
                    counter <= counter;
                end
            endcase
        end
    end
endmodule
