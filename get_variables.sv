`include "instruction_types.defs"
`include "register_name.sv"

module get_variables
#(
  INSTRUCTION_LENGTH = 32,
  TYPE_WIDTH = 3,
  REGISTER_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4,
  IMMEDIATE_WIDTH = 32,
  FLAG_WIDTH = 16
)
(
  input [INSTRUCTION_LENGTH-1:0] instruction,
  input [TYPE_WIDTH-1:0] instruction_type,
  input [FLAG_WIDTH-1: 0] in_flag,
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
        if(in_flag[`IS_DIFF_INDEX])
          assign flag[3:0] = 'b0111 & in_flag[3:0];
        else
          assign flag[3:0] = 'b0111;
        assign flag[`IS_BRACKET_INDEX] = in_flag[`IS_BRACKET_INDEX];
        assign flag[`IS_LOAD_INDEX] = in_flag[`IS_LOAD_INDEX];
      end
      `I_TYPE: begin
        if(in_flag[`IS_DIFF_INDEX])
          assign flag[3:0] = 'b1011 & in_flag[3:0];
        else
          assign flag[3:0] = 'b1011;
        assign flag[`IS_BRACKET_INDEX] = in_flag[`IS_BRACKET_INDEX];
        assign flag[`IS_LOAD_INDEX] = in_flag[`IS_LOAD_INDEX];
        assign u_13_var[11:0] = instruction[31:20];
      	assign u_13_var[12] = instruction[31];
        if(u_13_var[12] & in_flag[`IS_SIGNED_INDEX])
	        assign imm[IMMEDIATE_WIDTH-1:13] = ~0;
        else
	        assign imm[IMMEDIATE_WIDTH-1:13] = 0;
        assign imm[12:0] = u_13_var[12:0];
        if(in_flag[`IS_SHIFT_INDEX])
          assign imm[10] = 0;
      end
      `S_TYPE: begin
        if(in_flag[`IS_DIFF_INDEX])
          assign flag[3:0] = 'b1110 & in_flag[3:0];
        else
          assign flag[3:0] = 'b1110;
        assign flag[`IS_BRACKET_INDEX] = in_flag[`IS_BRACKET_INDEX];
        assign flag[`IS_LOAD_INDEX] = in_flag[`IS_LOAD_INDEX];
        assign u_13_var[4:0] = instruction[11:7];
        assign u_13_var[11:5] = instruction[31:25];
	      assign u_13_var[12] = instruction[31];
        if(u_13_var[12] & in_flag[`IS_SIGNED_INDEX])
	        assign imm[IMMEDIATE_WIDTH-1:13] = ~0;
        else
	        assign imm[IMMEDIATE_WIDTH-1:13] = 0;
        assign imm[12:0] = u_13_var[12:0];
      end
      `SB_TYPE: begin
        if(in_flag[`IS_DIFF_INDEX])
          assign flag[3:0] = 'b1110 & in_flag[3:0];
        else
          assign flag[3:0] = 'b1110;
        assign flag[`IS_BRACKET_INDEX] = in_flag[`IS_BRACKET_INDEX];
        assign flag[`IS_LOAD_INDEX] = in_flag[`IS_LOAD_INDEX];
        assign u_13_var[0] = 1'b0;
        assign u_13_var[4:1] = instruction[11:8];
        assign u_13_var[10:5] = instruction[30:25];
        assign u_13_var[11] = instruction[`IS_LOAD_INDEX];
	      assign u_13_var[12] = instruction[31];
        if(u_13_var[12] & in_flag[`IS_SIGNED_INDEX])
	        assign imm[IMMEDIATE_WIDTH-1:13] = ~0;
        else
	        assign imm[IMMEDIATE_WIDTH-1:13] = 0;
        assign imm[12:0] = u_13_var[12:0];
      end
      `U_TYPE: begin
        if(in_flag[`IS_DIFF_INDEX])
          assign flag[3:0] = 'b1001 & in_flag[3:0];
        else
          assign flag[3:0] = 'b1001;
        assign flag[`IS_BRACKET_INDEX] = in_flag[`IS_BRACKET_INDEX];
        assign flag[`IS_LOAD_INDEX] = in_flag[`IS_LOAD_INDEX];
        assign u_21_var[19:0] = instruction[31:12];
        assign imm = u_21_var[19:0] << 12;
      end
      `UJ_TYPE: begin
        if(in_flag[`IS_DIFF_INDEX])
          assign flag[3:0] = 'b1001 & in_flag[3:0];
        else
          assign flag[3:0] = 'b1001;
        assign flag[`IS_BRACKET_INDEX] = in_flag[`IS_BRACKET_INDEX];
        assign flag[`IS_LOAD_INDEX] = in_flag[`IS_LOAD_INDEX];
        assign u_21_var[0] = 1'b0;
        assign u_21_var[10:1] = instruction[30:21];
        assign u_21_var[11] = instruction[20];
        assign u_21_var[19:12] = instruction[19:12];
        assign u_21_var[20] = instruction[31];
        if(u_21_var[20] & in_flag[`IS_SIGNED_INDEX])
	        assign imm[IMMEDIATE_WIDTH-1:21] = ~0;
        else
	        assign imm[IMMEDIATE_WIDTH-1:21] = 0;
        assign imm[20:0] = u_21_var[20:0];
      end
    endcase
  end
endmodule
