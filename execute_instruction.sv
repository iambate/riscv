
//module type will have as input: inst name, type,inst
module execute_instruction
#(
  BUS_DATA_WIDTH = 64,
  REGISTER_NUMBER_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4,
  REGISTER_WIDTH = 64,
  INSTRUCTION_NAME_WIDTH = 12
)
(
  input [REGISTER_NUMBER_WIDTH:0] stage2_rd,
  input [REGISTER_WIDTH-1:0] stage2_rs1_val,
  input [REGISTER_WIDTH-1:0] stage2_rs2_val,
  input [REGISTER_WIDTH-1:0] stage2_immediate,
  input [INSTRUCTION_NAME_WIDTH*8:0] stage2_opcode_name,
  input [BUS_DATA_WIDTH-1:0] stage2_pc,
  output [REGISTER_WIDTH-1:0] nstage3_alu_result,
  output [REGISTER_WIDTH-1:0] nstage3_rs2_val,
  output [REGISTER_NUMBER_WIDTH:0] nstage3_rd,
  output [INSTRUCTION_NAME_WIDTH*8:0] nstage3_opcode_name,
  output [BUS_DATA_WIDTH-1:0] nstage3_pc
);
function [REGISTER_WIDTH-1:0] add_sub(
input [REGISTER_WIDTH-1:0] num1,
input [REGISTER_WIDTH-1:0] num2,
input isAdd,
input isW
);
	logic [REGISTER_WIDTH-1:0] tmp_result;
	if(isW) begin
		if(isAdd)
			tmp_result[31:0] = num1[31:0] + num2[31:0];
		else
			tmp_result[31:0] = num1[31:0] - num2[31:0];
		if(tmp_result[31])
			tmp_result[REGISTER_WIDTH-1:32] = -1;
		else
			tmp_result[REGISTER_WIDTH-1:32] = 0;
	end else begin
		if(isAdd)
			tmp_result = num1 + num2;
		else
			tmp_result = num1 - num2;
	end
	add_sub = tmp_result;
endfunction

function [REGISTER_WIDTH-1:0] mul(
input [REGISTER_WIDTH-1:0] num1,
input [REGISTER_WIDTH-1:0] num2,
input isW,
input isU,
input isS,
input isH
);
	logic [123:0] tmp_result;
	if(isH) begin
		if(isS && isU) begin
			logic signed [REGISTER_WIDTH-1:0] tmp_num1;
			logic unsigned [REGISTER_WIDTH-1:0] tmp_num2;
			tmp_num1 = num1;
			tmp_num2 = num2;
			tmp_result = tmp_num1 * tmp_num2;
		end else if(isU) begin
			logic unsigned [REGISTER_WIDTH-1:0] tmp_num1;
			logic unsigned [REGISTER_WIDTH-1:0] tmp_num2;
			tmp_num1 = num1;
			tmp_num2 = num2;
			tmp_result = tmp_num1 * tmp_num2;
		end else begin
			logic signed [REGISTER_WIDTH-1:0] tmp_num1;
			logic signed [REGISTER_WIDTH-1:0] tmp_num2;
			tmp_num1 = num1;
			tmp_num2 = num2;
			tmp_result = tmp_num1 * tmp_num2;
		end
		mul = tmp_result[123:64];
	end else begin
		if(isW) begin
			tmp_result[31:0] = num1[31:0] * num2[31:0];
			if(tmp_result[31])
				tmp_result[REGISTER_WIDTH-1:32] = -1;
			else
				tmp_result[REGISTER_WIDTH-1:32] = 0;
		end else begin
			tmp_result = num1 * num2;
		end
		mul = tmp_result[REGISTER_WIDTH-1:0];
	end
endfunction

function [REGISTER_WIDTH-1:0] div_rem(
input [REGISTER_WIDTH-1:0] num1,
input [REGISTER_WIDTH-1:0] num2,
input isDiv,
input isW,
input isU
);
	logic [REGISTER_WIDTH-1:0] tmp_result;
	if(!isU) begin
		logic signed [REGISTER_WIDTH-1:0] tmp_num1;
		logic signed [REGISTER_WIDTH-1:0] tmp_num2;
		tmp_num1 = num1;
		tmp_num2 = num2;
		if(isW) begin
			if(isDiv)
				tmp_result[31:0] = tmp_num1[31:0] / tmp_num2[31:0];
			else
				tmp_result[31:0] = tmp_num1[31:0] % tmp_num2[31:0];
			if(tmp_result[31])
				tmp_result[REGISTER_WIDTH-1:32] = -1;
			else
				tmp_result[REGISTER_WIDTH-1:32] = 0;
		end else begin
			if(isDiv)
				tmp_result = tmp_num1 / tmp_num2;
			else
				tmp_result = tmp_num1 % tmp_num2;
		end
	end else begin
		logic unsigned [REGISTER_WIDTH-1:0] tmp_num1;
		logic unsigned [REGISTER_WIDTH-1:0] tmp_num2;
		tmp_num1 = num1;
		tmp_num2 = num2;
		if(isW) begin
			if(isDiv)
				tmp_result[31:0] = tmp_num1[31:0] / tmp_num2[31:0];
			else
				tmp_result[31:0] = tmp_num1[31:0] % tmp_num2[31:0];
			if(tmp_result[31])
				tmp_result[REGISTER_WIDTH-1:32] = -1;
			else
				tmp_result[REGISTER_WIDTH-1:32] = 0;
		end else begin
			if(isDiv)
				tmp_result = tmp_num1 / tmp_num2;
			else
				tmp_result = tmp_num1 % tmp_num2;
		end
	end
	div_rem = tmp_result;
endfunction

  	logic [INSTRUCTION_NAME_WIDTH*8:0] instruction_name;
  always_comb begin

    assign nstage3_opcode_name = stage2_opcode_name;
    assign nstage3_rd = stage2_rd;
    assign nstage3_rs2_val = stage2_rs2_val;
    assign nstage3_pc = stage2_pc;
    casez (stage2_opcode_name)
	"sd":
	begin
		assign instruction_name="sd";
	end
	"beq":
	begin
	    assign instruction_name="beq";
        end
	"bne":
	begin
	    assign instruction_name="bne";
        end
	"blt":
	begin
	    assign instruction_name="blt";
        end
	"bge":
	begin
	    assign instruction_name="bge";
        end
	"bltu":
	begin
	    assign instruction_name="bltu";
        end
	"bgue":
	begin
	    assign instruction_name="bgeu";
        end
	"sb":
	begin
	    assign instruction_name="sb";
        end
	"sh":
	begin
	    assign instruction_name="sh";
        end
	"sw":
	begin
	    assign instruction_name="sw";
        end
	"slli":
	begin
		assign  nstage3_alu_result = stage2_rs1_val << stage2_immediate[5:0];
        end
	"srli":
	begin
		assign  nstage3_alu_result = stage2_rs1_val >> stage2_immediate[5:0];
        end
	"srai":
	begin
		assign  nstage3_alu_result = $signed(stage2_rs1_val) >>> stage2_immediate[5:0];
        end
	"add":
	begin
		assign  nstage3_alu_result = add_sub(stage2_rs1_val, stage2_rs2_val, 1, 0);
        end
	"sub":
	begin
		assign  nstage3_alu_result = add_sub(stage2_rs1_val, stage2_rs2_val, 0, 0);
        end
	"sll":
	begin
		assign  nstage3_alu_result = stage2_rs1_val << stage2_rs2_val[5:0];
        end
	"slt":
	begin
		assign  nstage3_alu_result = $signed(stage2_rs1_val) < $signed(stage2_rs2_val);
        end
	"sltu":
	begin
		assign  nstage3_alu_result = $unsigned(stage2_rs1_val) < $unsigned(stage2_rs2_val);
        end
	"xor":
	begin
		assign  nstage3_alu_result = stage2_rs1_val ^ stage2_rs2_val;
        end
	"srl":
	begin
		assign  nstage3_alu_result = stage2_rs1_val >> stage2_rs2_val[5:0];
        end
	"sra":
	begin
		assign  nstage3_alu_result = $signed(stage2_rs1_val) >>> stage2_rs2_val[5:0];
        end
	"or":
	begin
		assign  nstage3_alu_result = stage2_rs1_val | stage2_rs2_val;
        end
	"and":
	begin
		assign  nstage3_alu_result = stage2_rs1_val & stage2_rs2_val;
        end 
	"fence":
	begin
	    assign instruction_name="fence";
        end
	"fencei":
	begin
	    assign instruction_name="fencei";
        end
	"lui":
	begin
		assign  nstage3_alu_result = stage2_immediate;
        end
	"auipc":
	begin
		assign  nstage3_pc = stage2_pc + stage2_immediate;
        end
	"jal":
	begin
	    assign instruction_name="jal";
        end
	"ret":
	begin
	    assign instruction_name="ret";
        end
	"jalr":
	begin
	    assign instruction_name="jalr";
        end
	"lb":
	begin
	    assign instruction_name="lb";
        end
	"lh":
	begin
	    assign instruction_name="lh";
        end
	"lw":
	begin
	    assign instruction_name="lw";
        end
	"lbu":
	begin
	    assign instruction_name="lbu";
        end
	"lhu":
	begin
	    assign instruction_name="lhu";
        end
	"mv":
	begin
	    assign instruction_name="mv";
        end
	"addi":
	begin
		assign  nstage3_alu_result = add_sub(stage2_rs1_val, stage2_immediate, 1, 0);
        end
	"slti":
	begin
		assign  nstage3_alu_result = $signed(stage2_rs1_val) < $signed(stage2_immediate);
        end
	"sltiu":
	begin
		assign  nstage3_alu_result = $unsigned(stage2_rs1_val) < $unsigned(stage2_immediate);
        end
	"xori":
	begin
		assign  nstage3_alu_result = stage2_rs1_val ^ stage2_immediate;
        end
	"ori":
	begin
		assign  nstage3_alu_result = stage2_rs1_val | stage2_immediate;
        end
	"andi":
	begin
		assign  nstage3_alu_result = stage2_rs1_val & stage2_immediate;
        end
	"lwu":
	begin
	    assign instruction_name="lwu";
        end
	"ld":
	begin
	    assign instruction_name="ld";
        end
	"addiw":
	begin
		assign  nstage3_alu_result = add_sub(stage2_rs1_val, stage2_immediate, 1, 1);
        end
	"scall":
	begin
	    assign instruction_name="scall";
        end
	"sbreak":
	begin
	    assign instruction_name="sbreak";
        end
	"rdcycle":
	begin
	    assign instruction_name="rdcycle";
        end
	"rdcycleh":
	begin
	    assign instruction_name="rdcycleh";
        end
	"rdtime":
	begin
	    assign instruction_name="rdtime";
        end
	"rdtimeh":
	begin
	    assign instruction_name="rdtimeh";
        end
	"rdinstreet":
	begin
	    assign instruction_name="rdinstreet";
        end
	"rdinstreth":
	begin
	    assign instruction_name="rdinstreth";
        end 
	"slliw":
	begin
		assign  nstage3_alu_result[31:0] = stage2_rs1_val[31:0] << stage2_immediate[4:0];
		if(nstage3_alu_result[31])
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = -1;
		else
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = 0;
        end
	"srliw":
	begin
		assign  nstage3_alu_result[31:0] = stage2_rs1_val[31:0] >> stage2_immediate[4:0];
		if(nstage3_alu_result[31])
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = -1;
		else
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = 0;
        end
	"sraiw":
	begin
		assign  nstage3_alu_result[31:0] = $signed(stage2_rs1_val[31:0]) >>> stage2_immediate[4:0];
		if(nstage3_alu_result[31])
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = -1;
		else
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = 0;
        end
	"addw":
	begin
		assign  nstage3_alu_result = add_sub(stage2_rs1_val, stage2_rs2_val, 1, 1);
        end
	"subw":
	begin
		assign  nstage3_alu_result = add_sub(stage2_rs1_val, stage2_rs2_val, 0, 1);
        end
	"sllw":
	begin
		assign  nstage3_alu_result[31:0] = stage2_rs1_val[31:0] << stage2_rs2_val[4:0];
		if(nstage3_alu_result[31])
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = -1;
		else
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = 0;
        end
	"srlw":
	begin
		assign  nstage3_alu_result[31:0] = stage2_rs1_val[31:0] >> stage2_rs2_val[4:0];
		if(nstage3_alu_result[31])
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = -1;
		else
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = 0;
        end  
	"sraw":
	begin
		assign  nstage3_alu_result[31:0] = $signed(stage2_rs1_val[31:0]) >>> stage2_rs2_val[4:0];
		if(nstage3_alu_result[31])
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = -1;
		else
			assign  nstage3_alu_result[REGISTER_WIDTH-1:32] = 0;
        end
	"mulw":
	begin
		assign  nstage3_alu_result = mul(stage2_rs1_val, stage2_rs2_val, 1, 0, 0, 0);
        end     
	"divw":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 1, 1, 0);
        end 
	"divuw":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 1, 1, 1);
        end    
	"remw":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 0, 1, 0);
        end       
	"remuw":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 0, 1, 1);
        end
	"mul":
	begin
		assign  nstage3_alu_result = mul(stage2_rs1_val, stage2_rs2_val, 0, 0, 0, 0);
        end
	"mulh":
	begin
		assign  nstage3_alu_result = mul(stage2_rs1_val, stage2_rs2_val, 0, 0, 0, 1);
        end
	"mulhsu":
	begin
		assign  nstage3_alu_result = mul(stage2_rs1_val, stage2_rs2_val, 0, 1, 1, 1);
        end
	"mulhu":
	begin
		assign  nstage3_alu_result = mul(stage2_rs1_val, stage2_rs2_val, 0, 1, 0, 1);
        end
	"div":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 1, 0, 0);
        end
	"divu":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 1, 0, 1);
        end
	"rem":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 0, 0, 0);
        end
	"remu":
	begin
		assign  nstage3_alu_result = div_rem(stage2_rs1_val, stage2_rs2_val, 0, 0, 1);
        end
	default:
        begin
	    assign instruction_name="unknown";
        end
    endcase
  end
//process inst to provide output in ans string
endmodule
