
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
    input clk,
    input bus_reqcyc1,
    input bus_reqcyc2,
    input bus_reqcyc3,
    input bus_reqcyc4,
    input bus_reqcyc5,
    output bus_grant1,
    output bus_grant2,
    output bus_grant3,
    output bus_grant4,
    output bus_grant5,
    input bus_busy
);
    logic [2:0] n_bus_grant;
    always_comb  begin
        if(!bus_busy & bus_reqcyc1) begin
            n_bus_grant = 1;
        end else if(!bus_busy & bus_reqcyc2) begin
            n_bus_grant = 2;
        end else if(!bus_busy & bus_reqcyc3) begin
            n_bus_grant = 3;
        end else if(!bus_busy & bus_reqcyc4) begin
            n_bus_grant = 4;
        end else if(!bus_busy & bus_reqcyc5) begin
            n_bus_grant = 5;
        end else begin
            n_bus_grant = 0;
        end
    end
    always_ff @(posedge clk) begin
        if(n_bus_grant == 1) begin
            bus_grant1 <= 1;
            bus_grant2 <= 0;
            bus_grant3 <= 0;
            bus_grant4 <= 0;
            bus_grant5 <= 0;
        end else if(n_bus_grant == 2) begin
            bus_grant1 <= 0;
            bus_grant2 <= 1;
            bus_grant3 <= 0;
            bus_grant4 <= 0;
            bus_grant5 <= 0;
        end else if(n_bus_grant == 3) begin
            bus_grant1 <= 0;
            bus_grant2 <= 0;
            bus_grant3 <= 1;
            bus_grant4 <= 0;
            bus_grant5 <= 0;
        end else if(n_bus_grant == 4) begin
            bus_grant1 <= 0;
            bus_grant2 <= 0;
            bus_grant3 <= 0;
            bus_grant4 <= 1;
            bus_grant5 <= 0;
        end else if(n_bus_grant == 5) begin
            bus_grant1 <= 0;
            bus_grant2 <= 0;
            bus_grant3 <= 0;
            bus_grant4 <= 0;
            bus_grant5 <= 1;
        end else begin
            bus_grant1 <= 0;
            bus_grant2 <= 0;
            bus_grant3 <= 0;
            bus_grant4 <= 0;
            bus_grant5 <= 0;
        end
    end
endmodule
