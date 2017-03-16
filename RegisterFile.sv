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
	    int i;
	    for(i=0;i<32;i++)
	        $display("Register %0d:\t%0d",i, Registers[i]);
	    $display("");
	    $finish;
	end
   end
endmodule
