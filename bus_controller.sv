
module bus_controller
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
    input bus_reqcyc1,
    input bus_reqcyc2,
    input bus_reqcyc3,
    input bus_reqcyc4,
    output bus_grant1,
    output bus_grant2,
    output bus_grant3,
    output bus_grant4,
    input bus_busy
);
    always_comb begin
        if(!bus_busy & bus_reqcyc1) begin
            assign bus_grant1 = 1;
            assign bus_grant2 = 0;
            assign bus_grant3 = 0;
            assign bus_grant4 = 0;
        end else if(!bus_busy & bus_reqcyc2) begin
            assign bus_grant1 = 0;
            assign bus_grant2 = 1;
            assign bus_grant3 = 0;
            assign bus_grant4 = 0;
        end else if(!bus_busy & bus_reqcyc3) begin
            assign bus_grant1 = 0;
            assign bus_grant2 = 0;
            assign bus_grant3 = 1;
            assign bus_grant4 = 0;
        end else if(!bus_busy & bus_reqcyc4) begin
            assign bus_grant1 = 0;
            assign bus_grant2 = 0;
            assign bus_grant3 = 0;
            assign bus_grant4 = 1;
        end else begin
            assign bus_grant1 = 0;
            assign bus_grant2 = 0;
            assign bus_grant3 = 0;
            assign bus_grant4 = 0;
        end
    end
endmodule
