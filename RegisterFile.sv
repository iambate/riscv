module RegisterFile
#(
   BUS_DATA_WIDTH = 64
)
(
   input clk,
   input reset,
   input wr_en,
   input [4:0] stage1_rs1,
   input [4:0] stage1_rs2,
   input [4:0] stage5_rd,
   input display_regs,
   input [BUS_DATA_WIDTH-1:0] stage5_result,
   output [BUS_DATA_WIDTH-1:0] nstage_rs1_content,
   output [BUS_DATA_WIDTH-1:0] nstage_rs2_content
);
   wire [4:0] stage1_rs1;
   wire [4:0] stage1_rs2;
   wire [4:0] stage5_rd;
   wire [BUS_DATA_WIDTH-1:0] stage5_result;
   reg[BUS_DATA_WIDTH -1:0] Registers[32];

   always_comb begin
	if(stage1_rs1 >= 'd0 && stage1_rs1 <= 'd31) begin
	     assign nstage_rs1_content = Registers[stage1_rs1];
	end
	else begin
	     assign nstage_rs1_content = 'd0;
	end
	if(stage1_rs2 >= 'd0 && stage1_rs2 <= 'd31) begin
 	     assign nstage_rs2_content = Registers[stage1_rs2];
	end
	else begin
	     assign nstage_rs2_content = 'd0;
	end
   end

   always_ff @(posedge clk) begin
	if(reset) begin
	    Registers[31:0]='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	end
	else if(wr_en) begin
	    Registers[stage5_rd] <= stage5_result;
	end
	else if(display_regs) begin
	    $display("Register0: %d", Registers[0]);
	    $display("Register1: %d", Registers[1]);
	    $display("Register2: %d", Registers[2]);
	    $display("Register3: %d", Registers[3]);
	    $display("Register4: %d", Registers[4]);
	    $display("Register5: %d", Registers[5]);
	    $display("Register6: %d", Registers[6]);
	    $display("Register7: %d", Registers[7]);
	    $display("Register8: %d", Registers[8]);
	    $display("Register9: %d", Registers[9]);
	    $display("Register10: %d", Registers[10]);
	    $display("Register11: %d", Registers[11]);
	    $display("Register12: %d", Registers[12]);
	    $display("Register13: %d", Registers[13]);
	    $display("Register14: %d", Registers[14]);
	    $display("Register15: %d", Registers[15]);
	    $display("Register16: %d", Registers[16]);
	    $display("Register17: %d", Registers[17]);
	    $display("Register18: %d", Registers[18]);
	    $display("Register19: %d", Registers[19]);
	    $display("Register20: %d", Registers[20]);
	    $display("Register21: %d", Registers[21]);
	    $display("Register22: %d", Registers[22]);
	    $display("Register23: %d", Registers[23]);
	    $display("Register24: %d", Registers[24]);
	    $display("Register25: %d", Registers[25]);
	    $display("Register26: %d", Registers[26]);
	    $display("Register27: %d", Registers[27]);
	    $display("Register28: %d", Registers[28]);
	    $display("Register29: %d", Registers[29]);
	    $display("Register30: %d", Registers[30]);
	    $display("Register31: %d", Registers[31]);
	    $display("");
	    $finish;
	end
   end
/*
   initial begin
	Registers[31:0]='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
   end
*/
endmodule
