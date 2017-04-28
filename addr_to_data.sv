//`define ADD2DATA
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
    input [BUS_TAG_WIDTH-1:0] main_bus_resptag,
    output [BUS_TAG_WIDTH-1:0] main_bus_reqtag
);
    logic[3:0] counter;
    logic[3:0] ncounter;
    logic [BUS_DATA_WIDTH-1:0] response;
    enum {STATERESET=4'b0000, STATEBEGIN=4'b0001, STATEREQ=4'b0010, STATEWAIT=4'b0011,
          STATERESP=4'b0100, STATERESPEND=4'b0101, STATEFINAL=4'b0111, STATEREADY=4'b1000} state, next_state;
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
		    next_state = STATERESPEND;
                end
            STATERESPEND:
                next_state= STATEFINAL;
            STATEFINAL:
                next_state= STATEREADY;
            STATEREADY:
                next_state = enable? STATEBEGIN : STATEREADY;
        endcase
        case(next_state)
            STATERESET:
            begin
                assign bus_busy = 0;
                assign abtr_reqcyc = 0;
                assign ready = 0;
            end
            STATEBEGIN:
            begin
                assign bus_busy = 0;
                assign abtr_reqcyc = 1;
                assign ready = 0;
            end
            STATEREQ:
            begin
                assign bus_busy = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_reqcyc = 1;
                assign main_bus_respack = 0;
                assign main_bus_req[63:0] = (addr[63:6] << 6);
                assign main_bus_reqtag = `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
                assign ready = 0;
            end
            STATEWAIT:
            begin
                assign bus_busy = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_reqcyc = 0;
                assign main_bus_respack = 0;
                assign main_bus_reqtag = 0;
                assign main_bus_req = 0; 
                assign ready = 0;
            end
            STATERESP:
            begin
                assign bus_busy = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_reqcyc = 0;
                assign main_bus_reqtag = 0;
                if(main_bus_resptag == (`SYSBUS_READ<<12|`SYSBUS_MEMORY<<8)) begin
	            assign main_bus_respack = 1;
                end else begin
	            assign main_bus_respack = 0;
                end
                assign main_bus_req = 0; 
                assign ready = 0;
            end
            STATERESPEND:
            begin
                assign bus_busy = 1;
                assign main_bus_reqcyc = 0;
                assign main_bus_reqtag = 0;
                assign main_bus_respack = 1;
                assign abtr_reqcyc = 0;
                assign main_bus_req = 0; 
                assign ready = 0;
            end
            STATEFINAL:
            begin
                assign bus_busy = 1;
                assign main_bus_reqcyc = 0;
                assign main_bus_reqtag = 0;
                assign main_bus_respack = 0;
                assign abtr_reqcyc = 0;
                assign main_bus_req = 0; 
                assign ready = 0;
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
                    if(main_bus_resptag == (`SYSBUS_READ<<12|`SYSBUS_MEMORY<<8)) begin
`ifdef ADD2DATA
                      $display("AD State resp, going to ready");
                      $display("AD data: %x", main_bus_resp[63:0]);
`endif
                      counter <= ncounter;
                      case(counter)
                          0:
                              data[63:0] <= main_bus_resp[63:0];
                          1:
                              data[127:64] <= main_bus_resp[63:0];
                          2:
                              data[191:128] <= main_bus_resp[63:0];
                          3:
                              data[255:192] <= main_bus_resp[63:0];
                          4:
                              data[319:256] <= main_bus_resp[63:0];
                          5:
                              data[383:320] <= main_bus_resp[63:0];
                          6:
                              data[447:384] <= main_bus_resp[63:0];
                          7:
                              data[511:448] <= main_bus_resp[63:0];
                      endcase
                    end else begin
`ifdef ADD2DATA
                      $display("AD State resp, going to ready");
                      $display("AD other response tag: %x", main_bus_respack);
`endif
                    end
                end
                STATEREADY:
                begin
`ifdef ADD2DATAEXTRA
                    $display("AD State ready");
`endif
                    counter <= 0;
                end
            endcase
        end
    end

    always_comb begin
    end
endmodule
