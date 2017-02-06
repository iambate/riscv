`include "Sysbus.defs"
`include "Opcodes.defs"
`include "get_variables.sv"
`include "instruction_types.defs"

//module type will have as input: inst name, type,inst
module process_instruction
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
  input [BUS_DATA_WIDTH/2-1:0] instruction,
  output [REGISTER_NAME_WIDTH*8:0] rd,
  output [REGISTER_NAME_WIDTH*8:0] rs1,
  output [REGISTER_NAME_WIDTH*8:0] rs2,
  output [IMMEDIATE_WIDTH-1:0] imm,
  output [FLAG_WIDTH-1: 0] flag,
  output [INSTRUCTION_NAME_WIDTH*8:0] instruction_name
);

  logic [TYPE_WIDTH-1:0] instruction_type;
  logic [FLAG_WIDTH-1:0] tmp_flag;
  get_variables vars (.instruction(instruction),
                      .instruction_type(instruction_type),
                      .in_flag(tmp_flag),
                      .rd(rd),
                      .rs1(rs1),
                      .rs2(rs2),
                      .imm(imm),
                      .flag(flag));
  always_comb begin
    assign tmp_flag[`IS_LOAD_INDEX] = 0;
    assign tmp_flag[`IS_SHIFT_INDEX] = 0;
    assign tmp_flag[`IS_DIFF_INDEX] = 0;
    assign tmp_flag[`IS_BRACKET_INDEX]=0;
    assign tmp_flag[`IS_SIGNED_INDEX]=1;
    casex (instruction)
	`SD: 
	begin
	    assign instruction_type=`S_TYPE;
	    assign instruction_name="sd";
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
	end
	`BEQ:
	begin
            assign instruction_type=`SB_TYPE;
	    assign instruction_name="beq";
        end
	`BNE:
	begin
            assign instruction_type=`SB_TYPE;
	    assign instruction_name="bne";
        end
	`BLT:
	begin
            assign instruction_type=`SB_TYPE;
	    assign instruction_name="blt";
        end
	`BGE:
	begin
            assign instruction_type=`SB_TYPE;
	    assign instruction_name="bge";
        end
	`BLTU:
	begin
            assign instruction_type=`SB_TYPE;
	    assign instruction_name="bltu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`BGEU:
	begin
            assign instruction_type=`SB_TYPE;
	    assign instruction_name="bgeu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`SB:
	begin
            assign instruction_type=`S_TYPE;
	    assign instruction_name="sb";
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
        end
	`SH:
	begin
            assign instruction_type=`S_TYPE;
	    assign instruction_name="sh";
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
        end
	`SW :
	begin
            assign instruction_type=`S_TYPE;
	    assign instruction_name="sw";
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
        end
	`SLLI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="slli";
        end
	`SRLI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="srli";
        end
	`SRAI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="srai";
            assign tmp_flag[`IS_SHIFT_INDEX] = 1;
        end
	`ADD:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="add";
        end
	`SUB:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="sub";
        end
	`SLL:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="sll";
        end
	`SLT:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="slt";
        end
	`SLTU:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="sltu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`XOR:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="xor";
        end
	`SRL:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="srl";
        end
	`SRA:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="sra";
            assign tmp_flag[`IS_SHIFT_INDEX] = 1;
        end
	`OR:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="or";
        end
	`AND:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="and";
        end 
	`FENCE:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="fence";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0000;
        end
	`FENCEI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="fencei";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0000;
        end
	`LUI:
	begin
            assign instruction_type=`U_TYPE;
	    assign instruction_name="lui";
        end
	`AUIPC:
	begin
            assign instruction_type=`U_TYPE;
	    assign instruction_name="auipc";
        end
	`JAL:
	begin
            assign instruction_type=`UJ_TYPE;
	    assign instruction_name="jal";
        end
	`JALR:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="jalr";
        end
	`LB:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="lb";
            assign tmp_flag[`IS_LOAD_INDEX] = 1;
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
        end
	`LH:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="lh";
            assign tmp_flag[`IS_LOAD_INDEX] = 1;
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
        end
	`LW :
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="lw";
            assign tmp_flag[`IS_LOAD_INDEX] = 1;
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
        end
	`LBU:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="lbu";
            assign tmp_flag[`IS_LOAD_INDEX] = 1;
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
	    assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`LHU:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="lhu";
            assign tmp_flag[`IS_LOAD_INDEX] = 1;
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
	    assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`MOV:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="mv";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
	    assign tmp_flag[3:0]='b0011;
        end
	`ADDI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="addi";
        end
	`SLTI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="slti";
        end
	`SLTIU:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="sltiu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`XORI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="xori";
        end
	`ORI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="ori";
        end
	`ANDI:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="andi";
        end
	`LWU:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="lwu";
            assign tmp_flag[`IS_LOAD_INDEX] = 1;
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`LD:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="ld";
            assign tmp_flag[`IS_LOAD_INDEX] = 1;
	    assign tmp_flag[`IS_BRACKET_INDEX]=1;
        end
	`ADDIW :
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="addiw";
        end
	`SCALL:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="scall";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0000;
        end
	`SBREAK:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="sbreak";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0000;
        end
	`RDCYCLE:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="rdcycle";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0001;
        end
	`RDCYCLEH:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="rdcycleh";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0001;
        end
	`RDTIME:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="rdtime";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0001;
        end
	`RDTIMEH:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="rdtimeh";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0001;
        end
	`RDINSTREET:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="rdinstreet";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0001;
        end
	`RDINSTRETH:
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="rdinstreth";
	    assign tmp_flag[`IS_DIFF_INDEX]=1;
            assign tmp_flag[3:0]='b0001;
        end 
	`SLLIW :
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="slliw";
        end
	`SRLIW :
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="srliw";
        end
	`SRAIW :
	begin
            assign instruction_type=`I_TYPE;
	    assign instruction_name="sraiw";
            assign tmp_flag[`IS_SHIFT_INDEX] = 1;
        end
	`ADDW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="addw";
        end
	`SUBW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="subw";
        end
	`SLLW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="sllw";
        end
	`SRLW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="srlw";
        end  
	`SRAW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="sraw";
            assign tmp_flag[`IS_SHIFT_INDEX] = 1;
        end
	`MULW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="mulw";
        end     
	`DIVW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="divw";
        end 
	`DIVUW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="divuw";
        end    
	`REMW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="remw";
        end       
	`REMUW :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="remuw";
        end
	`MUL:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="mul";
        end
	`MULH:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="mulh";
        end
	`MULHSU:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="mulhsu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`MULHU:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="mulhu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`DIV:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="div";
        end
	`DIVU:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="divu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	`REM :
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="rem";
        end
	`REMU:
	begin
            assign instruction_type=`R_TYPE;
	    assign instruction_name="remu";
            assign tmp_flag[`IS_SIGNED_INDEX]=0;
        end
	default:
        begin
            assign instruction_type=`UNKNOWN_TYPE;
	    assign instruction_name="unknown";
        end
    endcase
  end
//process inst to provide output in ans string
endmodule
