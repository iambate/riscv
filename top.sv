`include "Sysbus.defs"
`include "Opcodes.defs"
`include "get_variables.sv"
`include "register_name.sv"
`include "instruction_types.defs"

//module type will have as input: inst name, type,inst
module Process_Instruction
#(
  BUS_DATA_WIDTH = 64,
  TYPE_WIDTH = 3,
  REGISTER_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4,
  IMMEDIATE_WIDTH = 32,
  FLAG_WIDTH = 8
)
(
  input [BUS_DATA_WIDTH/2-1:0] instruction,
  output [8:0] ans
);

  logic [TYPE_WIDTH-1:0] instruction_type;
  logic [REGISTER_NAME_WIDTH*8:0] rd;
  logic [REGISTER_NAME_WIDTH*8:0] rs1;
  logic [REGISTER_NAME_WIDTH*8:0] rs2;
  logic [IMMEDIATE_WIDTH-1:0] imm;
  logic [FLAG_WIDTH-1: 0] flag;
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
	default: assign ans=3;
    endcase
  end
//process inst to provide output in ans string
endmodule

module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,
  REGISTER_NAME_WIDTH = 4,
  REGISTER_WIDTH = 5
)
(
  input  clk,
         reset,

  // 64-bit address of the program entry point
  input  [63:0] entry,
  
  // interface to connect to the bus
  output bus_reqcyc,//set when sending a request
  output bus_respack,//set after receiving data rom the dram
  output [BUS_DATA_WIDTH-1:0] bus_req,//pc value
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,//READ OR MEMORY
  input  bus_respcyc,//if tx_queue is not empty respcyc is set
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,//bus_resp contains data
  input  [BUS_TAG_WIDTH-1:0] bus_resptag
);

  logic [63:0] pc;
  logic [63:0] npc;
  logic [63:0] prev_pc;
  logic [8:0] counter;
  logic [BUS_TAG_WIDTH-1:0] tag;
  logic [8:0] ncounter;
  logic [8:0] output1;
  logic [8:0] output2;
  logic [REGISTER_WIDTH*8:0] rs1;
  logic [REGISTER_WIDTH*8:0] rs2;
  logic [REGISTER_WIDTH*8:0] rd;
  Process_Instruction inst_1 (bus_resp[31:0],output1);
  Process_Instruction inst_2 (bus_resp[63:32],output2);

  always_comb begin
    assign npc = pc+'d64;
    assign bus_reqtag = `SYSBUS_READ<<12|`SYSBUS_MEMORY<<8;
    assign ncounter = counter+'d1;
  end
  always @ (posedge clk)//note: all statements run in parallel
    if(reset) begin
	pc <= entry;
	counter <= 'd8;
    end
    else begin
	if(bus_respcyc) begin
	     if(!bus_resp) begin
		$finish;
	     end
	     else if (!bus_resp[63:32]) begin
		$display("%h",bus_resp[31:0]);
		$display("%h",output1);
		$finish;
	     end
	     else begin
		$display("%h",bus_resp[31:0]);
		$display("%h",output1);
		$display("");
		$display("%h", bus_resp[63:32]);
		$display("%h",output2);
		$display("");
		bus_respack <= 1;
  	     end
	end
	else begin
	     bus_respack <= 0;
	end

	if(counter == 'd8) begin
	     pc<=npc;
             bus_req<=pc;
	     bus_reqcyc<=1;
	     counter<='d0;
	end
	else if (counter != 'd8 && bus_respcyc)
	    counter <= ncounter;//implement as assign new_counter=counter+'d1 and counter <= new_counter
	else begin
	    bus_reqcyc<=0;
	end
    end
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
