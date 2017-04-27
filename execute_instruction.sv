//`define ALUDEBUGEX
`define ALUDEBUG
//module type will have as input: inst name, type,inst
module execute_instruction
#(
  ADDRESS_WIDTH = 64,
  REGISTERNO_WIDTH = 5,
  REGISTER_NAME_WIDTH = 4,
  REGISTER_WIDTH = 64,
  INSTRUCTION_NAME_WIDTH = 12*8
)
(
  input clk,
  input reset,
  input in_enable,
  input [REGISTER_WIDTH-1:0] in_rs1_value,
  input [REGISTER_WIDTH-1:0] in_rs2_value,
  input [REGISTER_WIDTH-1:0] in_imm_value,
  input [REGISTERNO_WIDTH-1:0] in_rd_regno,
  input [REGISTERNO_WIDTH-1:0] in_rs1_regno,
  input [REGISTERNO_WIDTH-1:0] in_rs2_regno,
  input [INSTRUCTION_NAME_WIDTH-1:0] in_opcode_name,
  input [REGISTERNO_WIDTH-1:0] in_alu_rd_regno,
  input [REGISTERNO_WIDTH-1:0] in_mm_rd_regno,
  input [REGISTERNO_WIDTH-1:0] in_wb_rd_regno,
  input [REGISTER_WIDTH-1:0] in_alu_alu_result,
  input [REGISTER_WIDTH-1:0] in_mm_mdata,
  input [REGISTER_WIDTH-1:0] in_mm_alu_result,
  input [REGISTER_WIDTH-1:0] in_wb_data,
  input [ADDRESS_WIDTH-1:0] in_pcplus1,
  input in_branch_taken_bool,
  input in_alu_mm_load_bool,
  input in_mm_mm_load_bool,
  input in_syscall_flush,
  output [REGISTER_WIDTH-1:0] out_alu_result,
  output [REGISTER_WIDTH-1:0] out_rs2_value,
  output [REGISTERNO_WIDTH-1:0] out_rd_regno,
  output [INSTRUCTION_NAME_WIDTH-1:0] out_opcode_name,
  output [ADDRESS_WIDTH-1:0] out_pcplus1plusoffs,
  output out_update_rd_bool,
  output out_branch_taken_bool,
  output out_mm_load_bool,
  output out_ready
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

  logic [INSTRUCTION_NAME_WIDTH-1:0] instruction_name;
  logic [REGISTER_WIDTH-1:0] tmp;
  logic [REGISTER_WIDTH-1:0] n_value1;
  logic [REGISTER_WIDTH-1:0] n_value2;
  logic [REGISTER_WIDTH-1:0] n_alu_result;
  logic [ADDRESS_WIDTH-1:0] n_pc;
  logic n_branch_taken_bool;
  logic n_update_rd_bool;
  logic n_mm_load_bool;
  logic [REGISTER_WIDTH-1:0] stall_cycs;
  logic [REGISTER_WIDTH-1:0] n_stall_cycs;

  always_comb begin
    assign n_update_rd_bool = 0;
    assign n_branch_taken_bool = 0;
    assign n_mm_load_bool = 0;
    assign n_pc = in_pcplus1;
    // Bydefault out_ready is True, Unset it whenever needed
    assign out_ready = 1;
    assign n_stall_cycs = 0;
    assign n_alu_result = 0;

    // Forwarding path & stall
    // Need the value of ALU first, then Memory and then WB
    // Because the for ith instruction, i-1 will be in ALU
    // i-2 will be in Memory and i-3 will be in WB. So we want
    // Value rd_value of latest instruction
    // For rs1
    if (in_rs1_regno == in_alu_rd_regno && in_alu_mm_load_bool) begin
      if (stall_cycs == 1) begin
        assign n_value1 = in_mm_mdata;
      end else begin
        // Stall for memory and ALU (Pipeline slide 38)
        assign out_ready = 0;
        assign n_stall_cycs = stall_cycs + 1;
      end
    end else if (in_rs1_regno == in_alu_rd_regno) begin
      assign n_value1 = in_alu_alu_result;
    end else if (in_rs1_regno == in_mm_rd_regno) begin
      if(in_mm_mm_load_bool) begin
        assign n_value1 = in_mm_mdata;
      end else begin
        assign n_value1 = in_mm_alu_result;
      end
    end else if (in_rs1_regno == in_wb_rd_regno) begin
      assign n_value1 = in_wb_data;
    end else begin
      assign n_value1 = in_rs1_value;
    end

    // For rs2
    if (in_rs2_regno == in_alu_rd_regno && in_mm_mm_load_bool) begin
      if (stall_cycs == 1) begin
        assign n_value1 = in_mm_mdata;
      end else begin
        // Stall for memory and ALU (Pipeline slide 38)
        assign out_ready = 0;
        assign n_stall_cycs = stall_cycs + 1;
      end
    end else if (in_rs2_regno == in_alu_rd_regno) begin
      assign n_value2 = in_alu_alu_result;
    end else if (in_rs2_regno == in_mm_rd_regno) begin
      if(in_mm_mm_load_bool) begin
        assign n_value2 = in_mm_mdata;
      end else begin
        assign n_value2 = in_mm_alu_result;
      end
    end else if (in_rs2_regno == in_wb_rd_regno) begin
      assign n_value2 = in_wb_data;
    end else begin
      assign n_value2 = in_rs2_value;
    end

    // Case block
    casez (in_opcode_name)
    "sd":
    begin
      assign n_alu_result = n_value1 + in_imm_value;
    end
    "beq":
    begin
      if(n_value1 == n_value2) begin
        assign n_branch_taken_bool = 1;
	assign n_pc = in_pcplus1 + in_imm_value;
      end
    end
    "bne":
    begin
      if(n_value1 != n_value2) begin
        assign n_branch_taken_bool = 1;
	assign n_pc = in_pcplus1 + in_imm_value;
      end
    end
    "blt":
    begin
      if($signed(n_value1) < $signed(n_value2)) begin
        assign n_branch_taken_bool = 1;
	assign n_pc = in_pcplus1 + in_imm_value;
      end
    end
    "bge":
    begin
      if($signed(n_value1) >= $signed(n_value2)) begin
        assign n_branch_taken_bool = 1;
	assign n_pc = in_pcplus1 + in_imm_value;
      end
    end
    "bltu":
    begin
      if($unsigned(n_value1) < $unsigned(n_value2)) begin
        assign n_branch_taken_bool = 1;
	assign n_pc = in_pcplus1 + in_imm_value;
      end
    end
    "bgue":
    begin
      if($unsigned(n_value1) >= $unsigned(n_value2)) begin
        assign n_branch_taken_bool = 1;
	assign n_pc = in_pcplus1 + in_imm_value;
      end
    end
    "sb":
    begin
      assign n_alu_result = n_value1 + in_imm_value;
    end
    "sh":
    begin
      assign n_alu_result = n_value1 + in_imm_value;
    end
    "sw":
    begin
      assign n_alu_result = n_value1 + in_imm_value;
    end
    "slli":
    begin
      assign  n_alu_result = n_value1 << in_imm_value[5:0];
      assign n_update_rd_bool = 1;
    end
    "srli":
    begin
      assign  n_alu_result = n_value1 >> in_imm_value[5:0];
      assign n_update_rd_bool = 1;
    end
    "srai":
    begin
      assign  n_alu_result = $signed(n_value1) >>> in_imm_value[5:0];
      assign n_update_rd_bool = 1;
    end
    "add":
    begin
      assign  n_alu_result = add_sub(n_value1, n_value2, 1, 0);
      assign n_update_rd_bool = 1;
    end
    "sub":
    begin
      assign  n_alu_result = add_sub(n_value1, n_value2, 0, 0);
      assign n_update_rd_bool = 1;
    end
    "sll":
    begin
      assign  n_alu_result = n_value1 << n_value2[5:0];
      assign n_update_rd_bool = 1;
    end
    "slt":
    begin
      assign  n_alu_result = $signed(n_value1) < $signed(n_value2);
      assign n_update_rd_bool = 1;
    end
    "sltu":
    begin
      assign  n_alu_result = $unsigned(n_value1) < $unsigned(n_value2);
      assign n_update_rd_bool = 1;
    end
    "xor":
    begin
      assign  n_alu_result = n_value1 ^ n_value2;
      assign n_update_rd_bool = 1;
    end
    "srl":
    begin
      assign  n_alu_result = n_value1 >> n_value2[5:0];
      assign n_update_rd_bool = 1;
    end
    "sra":
    begin
      assign  n_alu_result = $signed(n_value1) >>> n_value2[5:0];
      assign n_update_rd_bool = 1;
    end
    "or":
    begin
      assign  n_alu_result = n_value1 | n_value2;
      assign n_update_rd_bool = 1;
    end
    "and":
    begin
      assign  n_alu_result = n_value1 & n_value2;
      assign n_update_rd_bool = 1;
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
      assign  n_alu_result = in_imm_value;
      assign n_update_rd_bool = 1;
    end
    "auipc":
    begin
      assign  n_alu_result = in_pcplus1 + in_imm_value - 4;
      assign n_update_rd_bool = 1;
    end
    "jal":
    begin
      assign n_alu_result = in_pcplus1;
      assign n_branch_taken_bool = 1;
      assign n_update_rd_bool = 1;
      assign n_pc = in_pcplus1 - 4 + in_imm_value;
    end
    "ret":
    begin
      if(in_rs1_value) begin
        assign n_branch_taken_bool = 1;
        assign n_pc = in_rs1_value;
      end
    end
    "jalr":
    begin
      assign n_alu_result = in_pcplus1;
      assign n_branch_taken_bool = 1;
      assign n_update_rd_bool = 1;
      assign tmp = n_value1 + in_imm_value;
      assign n_pc = tmp[REGISTER_WIDTH-1:1] << 1;
    end
    "lb":
    begin
        assign n_mm_load_bool = 1;
        assign n_alu_result = n_value1 + in_imm_value;
    end
    "lh":
    begin
        assign n_mm_load_bool = 1;
        assign n_alu_result = n_value1 + in_imm_value;
    end
    "lw":
    begin
        assign n_mm_load_bool = 1;
        assign n_alu_result = n_value1 + in_imm_value;
    end
    "lbu":
    begin
        assign n_mm_load_bool = 1;
        assign n_alu_result = n_value1 + in_imm_value;
    end
    "lhu":
    begin
        assign n_mm_load_bool = 1;
        assign n_alu_result = n_value1 + in_imm_value;
    end
    "mv":
    begin
        assign instruction_name="mv";
    end
    "addi":
    begin
      assign  n_alu_result = add_sub(n_value1, in_imm_value, 1, 0);
      assign n_update_rd_bool = 1;
    end
    "slti":
    begin
      assign  n_alu_result = $signed(n_value1) < $signed(in_imm_value);
      assign n_update_rd_bool = 1;
    end
    "sltiu":
    begin
      assign  n_alu_result = $unsigned(n_value1) < $unsigned(in_imm_value);
      assign n_update_rd_bool = 1;
    end
    "xori":
    begin
      assign  n_alu_result = n_value1 ^ in_imm_value;
      assign n_update_rd_bool = 1;
    end
    "ori":
    begin
      assign  n_alu_result = n_value1 | in_imm_value;
      assign n_update_rd_bool = 1;
    end
    "andi":
    begin
      assign  n_alu_result = n_value1 & in_imm_value;
      assign n_update_rd_bool = 1;
    end
    "lwu":
    begin
        assign n_mm_load_bool = 1;
        assign n_alu_result = n_value1 + in_imm_value;
    end
    "ld":
    begin
        assign n_mm_load_bool = 1;
        assign n_alu_result = n_value1 + in_imm_value;
    end
    "addiw":
    begin
      assign  n_alu_result = add_sub(n_value1, in_imm_value, 1, 1);
      assign n_update_rd_bool = 1;
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
      assign  n_alu_result[31:0] = n_value1[31:0] << in_imm_value[4:0];
      if(n_alu_result[31])
        assign  n_alu_result[REGISTER_WIDTH-1:32] = -1;
      else
        assign  n_alu_result[REGISTER_WIDTH-1:32] = 0;
      assign n_update_rd_bool = 1;
    end
    "srliw":
    begin
      assign  n_alu_result[31:0] = n_value1[31:0] >> in_imm_value[4:0];
      if(n_alu_result[31])
        assign  n_alu_result[REGISTER_WIDTH-1:32] = -1;
      else
        assign  n_alu_result[REGISTER_WIDTH-1:32] = 0;
      assign n_update_rd_bool = 1;
    end
    "sraiw":
    begin
      assign  n_alu_result[31:0] = $signed(n_value1[31:0]) >>> in_imm_value[4:0];
      if(n_alu_result[31])
        assign  n_alu_result[REGISTER_WIDTH-1:32] = -1;
      else
        assign  n_alu_result[REGISTER_WIDTH-1:32] = 0;
      assign n_update_rd_bool = 1;
    end
    "addw":
    begin
      assign  n_alu_result = add_sub(n_value1, n_value2, 1, 1);
      assign n_update_rd_bool = 1;
    end
    "subw":
    begin
      assign  n_alu_result = add_sub(n_value1, n_value2, 0, 1);
      assign n_update_rd_bool = 1;
    end
    "sllw":
    begin
      assign  n_alu_result[31:0] = n_value1[31:0] << n_value2[4:0];
      if(n_alu_result[31])
        assign  n_alu_result[REGISTER_WIDTH-1:32] = -1;
      else
        assign  n_alu_result[REGISTER_WIDTH-1:32] = 0;
      assign n_update_rd_bool = 1;
    end
    "srlw":
    begin
      assign  n_alu_result[31:0] = n_value1[31:0] >> n_value2[4:0];
      if(n_alu_result[31])
        assign  n_alu_result[REGISTER_WIDTH-1:32] = -1;
      else
        assign  n_alu_result[REGISTER_WIDTH-1:32] = 0;
      assign n_update_rd_bool = 1;
    end
    "sraw":
    begin
      assign  n_alu_result[31:0] = $signed(n_value1[31:0]) >>> n_value2[4:0];
      if(n_alu_result[31])
        assign  n_alu_result[REGISTER_WIDTH-1:32] = -1;
      else
        assign  n_alu_result[REGISTER_WIDTH-1:32] = 0;
      assign n_update_rd_bool = 1;
    end
    "mulw":
    begin
      assign  n_alu_result = mul(n_value1, n_value2, 1, 0, 0, 0);
      assign n_update_rd_bool = 1;
    end
    "divw":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 1, 1, 0);
      assign n_update_rd_bool = 1;
    end
    "divuw":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 1, 1, 1);
      assign n_update_rd_bool = 1;
    end
    "remw":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 0, 1, 0);
      assign n_update_rd_bool = 1;
    end
    "remuw":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 0, 1, 1);
      assign n_update_rd_bool = 1;
    end
    "mul":
    begin
      assign  n_alu_result = mul(n_value1, n_value2, 0, 0, 0, 0);
      assign n_update_rd_bool = 1;
    end
    "mulh":
    begin
      assign  n_alu_result = mul(n_value1, n_value2, 0, 0, 0, 1);
      assign n_update_rd_bool = 1;
    end
    "mulhsu":
    begin
      assign  n_alu_result = mul(n_value1, n_value2, 0, 1, 1, 1);
      assign n_update_rd_bool = 1;
    end
    "mulhu":
    begin
      assign  n_alu_result = mul(n_value1, n_value2, 0, 1, 0, 1);
      assign n_update_rd_bool = 1;
    end
    "div":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 1, 0, 0);
      assign n_update_rd_bool = 1;
    end
    "divu":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 1, 0, 1);
      assign n_update_rd_bool = 1;
    end
    "rem":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 0, 0, 0);
      assign n_update_rd_bool = 1;
    end
    "remu":
    begin
      assign  n_alu_result = div_rem(n_value1, n_value2, 0, 0, 1);
      assign n_update_rd_bool = 1;
    end
    default:
    begin
        assign instruction_name="unknown";
    end
    endcase
  end

  always_ff @(posedge clk) begin
`ifdef ALUDEBUGEX
    $display("ALU in_enable %d", in_enable);
    $display("ALU out_ready %d", out_ready);
`endif
    if(reset) begin
      // TODO: add reset things here
      stall_cycs <= 0;
    end else if (in_syscall_flush) begin
`ifdef ALUDEBUG
        $display("ALU flushed due to syscall_flush");
`endif
        stall_cycs <= 0;
        out_alu_result <= 0;
        out_branch_taken_bool <= 0;
        out_pcplus1plusoffs <= 0;
        out_rs2_value <= 0;
        out_opcode_name <= 0;
        out_rd_regno <= 0;
        out_update_rd_bool <= 0;
        out_mm_load_bool <= 0;
    end else if (in_enable & out_ready) begin
      if (in_branch_taken_bool) begin
        // flush all register to zero i.e. nop
`ifdef ALUDEBUG
        $display("ALU flushed due to branch taken");
`endif
        stall_cycs <= 0;
        out_alu_result <= 0;
        out_branch_taken_bool <= 0;
        out_pcplus1plusoffs <= 0;
        out_rs2_value <= 0;
        out_opcode_name <= 0;
        out_rd_regno <= 0;
        out_update_rd_bool <= 0;
        out_mm_load_bool <= 0;
      end else begin
`ifdef ALUDEBUG
        $display("ALU stall_cycs %d", n_stall_cycs);
        $display("ALU alu_result %d", n_alu_result);
        $display("ALU branch bool %d", n_branch_taken_bool);
        $display("ALU pc %d", n_pc);
        $display("ALU given val1 %d", in_rs1_value);
        $display("ALU given val2 %d", in_rs2_value);
        $display("ALU actual val1 %d", n_value1);
        $display("ALU actual val2 %d", n_value2);
        $display("ALU opcode %s", in_opcode_name);
        $display("ALU rd_regno %d", in_rd_regno);
        $display("ALU rd_update_bool %d", n_update_rd_bool);
        $display("ALU mm_load Bool %d", n_mm_load_bool);
`endif
        stall_cycs <= n_stall_cycs;
        out_alu_result <= n_alu_result;
        out_branch_taken_bool <= n_branch_taken_bool;
        out_pcplus1plusoffs <= n_pc;
        out_rs2_value <= n_value2;
        out_opcode_name <= in_opcode_name;
        out_rd_regno <= in_rd_regno;
        out_update_rd_bool <= n_update_rd_bool;
        out_mm_load_bool <= n_mm_load_bool;
      end
    end
  end
endmodule
