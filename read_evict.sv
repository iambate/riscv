module read_evict
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
    output over,
    output evict,
    output [BUS_DATA_WIDTH-1:0] evict_addr,
    input [BUS_TAG_WIDTH-1:0] main_bus_resptag,
    output [BUS_TAG_WIDTH-1:0] main_bus_reqtag
);
    enum {STATERESET=3'b000, STATEBEGIN=3'b001, STATEREQ=3'b010, STATEWAIT=3'b011,
          STATERESP=3'b100, STATEOVER=3'b101} state, next_state;
    always_comb begin
        case(state)
            STATERESET: next_state = enable? STATEBEGIN : STATERESET;
            STATEBEGIN: next_state = abtr_grant? STATEREQ : STATEBEGIN;
            STATEREQ: next_state = STATERESP;
            STATERESP: next_state = main_bus_respcyc? STATEREQ: STATEOVER;
            STATEOVER:
                next_state = enable? STATEBEGIN : STATEOVER;
        endcase
        case(next_state)
            STATERESET:
            begin
                assign bus_busy = 0;
                assign abtr_reqcyc = 0;
                assign over = 0;
            end
            STATEBEGIN:
            begin
                assign bus_busy = 0;
                assign abtr_reqcyc = 1;
                assign over = 0;
            end
            STATEREQ:
            begin
                assign bus_busy = 1;
                assign main_bus_reqcyc = 1;
                assign main_bus_respack = 0;
                assign main_bus_reqtag = `SYSBUS_INVAL<<8;
                assign over = 0;
            end
            STATERESP:
            begin
                assign bus_busy = 1;
                assign main_bus_reqcyc = 0;
                if(main_bus_respcyc == 1 && main_bus_resptag == (`SYSBUS_INVAL<<8)) begin
                  assign main_bus_respack = 1;
                end else begin
                  assign main_bus_respack = 0;
                end
                assign over = 0;
            end
            STATEOVER:
            begin
                assign bus_busy = 0;
                assign abtr_reqcyc = 0;
                assign over = 1;
            end
        endcase
    end

    always_ff @ (posedge clk) begin
        if(reset) begin
            state <= STATERESET;
            evict <= 0;
            evict_addr <= 0;
        end else begin
            state <= next_state;
            case(next_state)
                STATEBEGIN:
                begin
                  evict <= 0;
                  evict_addr <= 0;
                end
                STATEREQ:
                begin
                  evict <= 0;
                  evict_addr <= 0;
                end
                STATERESP:
                begin
                    if(main_bus_respcyc == 1 && main_bus_resptag == (`SYSBUS_INVAL<<8)) begin
                      evict <= 1;
                      evict_addr <= main_bus_resp[REGISTER_WIDTH-1:0];
                    end else begin
                      evict <= 0;
                      evict_addr <= 0;
                    end
                end
                STATEOVER:
                begin
                  evict <= 0;
                  evict_addr <= 0;
                end
            endcase
        end
    end
endmodule
