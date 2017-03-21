
module va_to_pa
#(
    BUS_DATA_WIDTH = 64,
    TYPE_WIDTH = 3,
    REGISTER_WIDTH = 5,
    REGISTER_NAME_WIDTH = 4,
    IMMEDIATE_WIDTH = 32,
    FLAG_WIDTH = 16,
    INSTRUCTION_NAME_WIDTH = 12
)
(
    input clk,
    input reset,
    input enable,
    input this_bus_grant,
    output this_bus_req,
    output bus_busy,
    input main_bus_response_cyc,
    output ready
);
    logic[3:0] counter;
    logic[2:0] level;
    enum {STATEBEGIN=3'b000, STATEREQ=3'b001, STATEWAIT=3'b010,
          STATERESP=3'b011, STATEREADY=3'b100} state, next_state;
    always_comb begin
        case(state)
            STATEBEGIN: next_state = this_bus_grant? STATEREQ : STATEBEGIN;
            STATEREQ: next_state = STATEWAIT;
            STATEWAIT: next_state = main_bus_response_cyc? STATERESP: STATEWAIT;
            STATERESP:
                if (counter < 8) begin
                    next_state = STATERESP;
                end else begin
                    if (level < 4) begin
                        next_state = STATEREQ;
                    end else begin
                        next_state = STATEREADY;
                    end
                end
            STATEREADY:
                next_state = enable? STATEBEGIN : STATEREADY;
        endcase
    end

    always_ff @ (posedge clk) begin
        if(reset) begin
            state <= STATEBEGIN;
        end else
            state <= next_state;
        end
        case(next_state)
            STATEBEGIN:
                level <= 0;
            STATEREQ:
                level <= nlevel;
            STATEWAIT:
                level <= level;
                counter <= 0;
            STATERESP:
                level <= level;
                counter <= ncounter;
                if(counter == requested_counter) begin
                    requested_addr <= main_bus_resp;
                end
            STATEREADY:
                level <= level;
                counter <= counter;
                //TODO: form requested_counter
        endcase
    end

    always_comb begin
        assign nlevel = level + 1;
        assign ncounter = counter + 1;
        case(state)
            STATEBEGIN:
                assign ready = 0;
            STATEREQ:
                assign bus_busy = 1;
                assign main_bus_req_cyc = 1;
                assign main_bus_resp_ack = 0;
                assign main_bus_req = requested_addr[63:12] << 12;
            STATEWAIT:
                assign main_bus_req_cyc = 0;
                assign main_bus_resp_ack = 0;
            STATERESP:
                assign main_bus_resp_ack = 1;
            STATEREADY:
                assign ready = 1;
                assign bus_busy = 0;
                assign this_bus_req = 0;
        endcase
    end
endmodule
