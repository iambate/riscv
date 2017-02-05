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
  FLAG_WIDTH = 8,
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
  get_variables vars (instruction,instruction_type,rd,rs1,rs2,imm,flag);
  
  always_comb begin
    casex (instruction)
	`SD: 
	begin
	    assign instruction_type=`S_TYPE;
	end
	`BEQ:
	begin
            assign instruction_type=`SB_TYPE;
        end
	`BNE:
	begin
            assign instruction_type=`SB_TYPE;
        end
	`BLT:
	begin
            assign instruction_type=`SB_TYPE;
        end
	`BGE:
	begin
            assign instruction_type=`SB_TYPE;
        end
	`BLTU:
	begin
            assign instruction_type=`SB_TYPE;
        end
	`BGEU:
	begin
            assign instruction_type=`SB_TYPE;
        end
	`SB:
	begin
            assign instruction_type=`S_TYPE;
        end
	`SH:
	begin
            assign instruction_type=`S_TYPE;
        end
	`SW :
	begin
            assign instruction_type=`S_TYPE;
        end
	`SLLI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`SRLI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`SRAI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`ADD:
	begin
            assign instruction_type=`R_TYPE;
        end
	`SUB:
	begin
            assign instruction_type=`R_TYPE;
        end
	`SLL:
	begin
            assign instruction_type=`R_TYPE;
        end
	`SLT:
	begin
            assign instruction_type=`R_TYPE;
        end
	`SLTU:
	begin
            assign instruction_type=`R_TYPE;
        end
	`XOR:
	begin
            assign instruction_type=`R_TYPE;
        end
	`SRL:
	begin
            assign instruction_type=`R_TYPE;
        end
	`SRA:
	begin
            assign instruction_type=`R_TYPE;
        end
	`OR:
	begin
            assign instruction_type=`R_TYPE;
        end
	`AND:
	begin
            assign instruction_type=`R_TYPE;
        end 
	`FENCE:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`FENCEI:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`LUI:
	begin
            assign instruction_type=`U_TYPE;
        end
	`AUIPC:
	begin
            assign instruction_type=`U_TYPE;
        end
	`JAL:
	begin
            assign instruction_type=`UJ_TYPE;
        end
	`JALR:
	begin
            assign instruction_type=`I_TYPE;
        end
	`LB:
	begin
            assign instruction_type=`I_TYPE;
        end
	`LH:
	begin
            assign instruction_type=`I_TYPE;
        end
	`LW :
	begin
            assign instruction_type=`I_TYPE;
        end
	`LBU:
	begin
            assign instruction_type=`I_TYPE;
        end
	`LHU:
	begin
            assign instruction_type=`I_TYPE;
        end
	`ADDI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`SLTI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`SLTIU:
	begin
            assign instruction_type=`I_TYPE;
        end
	`XORI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`ORI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`ANDI:
	begin
            assign instruction_type=`I_TYPE;
        end
	`LWU:
	begin
            assign instruction_type=`I_TYPE;
        end
	`LD:
	begin
            assign instruction_type=`I_TYPE;
        end
	`ADDIW :
	begin
            assign instruction_type=`I_TYPE;
        end
	`SCALL:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`SBREAK:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`RDCYCLE:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`RDCYCLEH:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`RDTIME:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`RDTIMEH:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`RDINSTREET:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end
	`RDINSTRETH:
	begin
            assign instruction_type=`UNKNOWN_TYPE;
        end 
	`SLLIW :
	begin
            assign instruction_type=`I_TYPE;
        end
	`SRLIW :
	begin
            assign instruction_type=`I_TYPE;
        end
	`SRAIW :
	begin
            assign instruction_type=`I_TYPE;
        end
	`ADDW :
	begin
            assign instruction_type=`R_TYPE;
        end
	`SUBW :
	begin
            assign instruction_type=`R_TYPE;
        end
	`SLLW :
	begin
            assign instruction_type=`R_TYPE;
        end
	`SRLW :
	begin
            assign instruction_type=`R_TYPE;
        end  
	`SRAW :
	begin
            assign instruction_type=`R_TYPE;
        end
	`MULW :
	begin
            assign instruction_type=`R_TYPE;
        end     
	`DIVW :
	begin
            assign instruction_type=`R_TYPE;
        end 
	`DIVUW :
	begin
            assign instruction_type=`R_TYPE;
        end    
	`REMW :
	begin
            assign instruction_type=`R_TYPE;
        end       
	`REMUW :
	begin
            assign instruction_type=`R_TYPE;
        end
	`MUL:
	begin
            assign instruction_type=`R_TYPE;
        end
	`MULH:
	begin
            assign instruction_type=`R_TYPE;
        end
	`MULHSU:
	begin
            assign instruction_type=`R_TYPE;
        end
	`MULHU:
	begin
            assign instruction_type=`R_TYPE;
        end
	`DIV:
	begin
            assign instruction_type=`R_TYPE;
        end
	`DIVU:
	begin
            assign instruction_type=`R_TYPE;
        end
	`REM :
	begin
            assign instruction_type=`R_TYPE;
        end
	`REMU:
	begin
            assign instruction_type=`R_TYPE;
        end
	default: assign instruction_type=`UNKNOWN_TYPE;
    endcase
  end
//process inst to provide output in ans string
endmodule
