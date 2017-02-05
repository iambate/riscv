`include "instruction_types.defs"


module get_variables
#(
  INSTRUCTION_LENGTH = 32,
  TYPE_WIDTH = 3,
  REGISTER_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4,
  IMMEDIATE_WIDTH = 32,
  FLAG_WIDTH = 8
)
(
  input [INSTRUCTION_LENGTH-1:0] instruction,
  input [TYPE_WIDTH-1:0] instruction_type,
  output [REGISTER_NAME_WIDTH*8:0] rd,
  output [REGISTER_NAME_WIDTH*8:0] rs1,
  output [REGISTER_NAME_WIDTH*8:0] rs2,
  output [IMMEDIATE_WIDTH-1:0] imm,
  output [FLAG_WIDTH-1: 0] flag
);
  logic unsigned [12:0] u_13_var;
  logic unsigned [20:0] u_21_var;
  get_reg_name for_rd(.reg_name(rd), .reg_number(instruction[11:7]));
  get_reg_name for_rs1(.reg_name(rs1), .reg_number(instruction[19:15]));
  get_reg_name for_rs2(.reg_name(rs2), .reg_number(instruction[24:20]));
  always_comb begin
    case(instruction_type)
      `R_TYPE: begin
        assign flag = 'd00000111;
       end
       `I_TYPE: begin
        assign flag = 'd00001011;
        assign u_13_var[11:0] = instruction[31:20];
	assign u_13_var[12] = instruction[31];
	assign imm = u_13_var[12:0];
       end
       `S_TYPE: begin
        assign flag = 'd00001110;
        assign u_13_var[4:0] = instruction[11:7];
        assign u_13_var[11:5] = instruction[31:25];
	assign u_13_var[12] = instruction[31];
	assign imm = u_13_var[12:0];
       end
       `SB_TYPE: begin
        assign flag = 'd00001110;
        assign u_13_var[0] = 1'b0;
        assign u_13_var[4:1] = instruction[11:8];
        assign u_13_var[10:5] = instruction[30:25];
        assign u_13_var[11] = instruction[7];
	assign u_13_var[12] = instruction[31];
        assign imm = u_13_var[12:0];
       end
       `U_TYPE: begin
        assign flag = 'd00001001;
        assign u_21_var[19:0] = instruction[31:12];
        assign imm = u_21_var[19:0] << 12;
       end
       `UJ_TYPE: begin
        assign flag = 'd00001001;
        assign u_21_var[0] = 1'b0;
        assign u_21_var[10:1] = instruction[30:21];
        assign u_21_var[11] = instruction[20];
        assign u_21_var[19:12] = instruction[19:12];
        assign u_21_var[20] = instruction[31];
        assign imm = u_21_var[20:0];
       end
    endcase
  end
endmodule
