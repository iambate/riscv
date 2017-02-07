
function void get_output_string(integer index, logic [40:0] rd, logic [40:0] rs1, logic [40:0] rs2, logic signed [31:0] imm, logic [7:0] flag, logic [96:0] instruction_name);
  string ans="";
  string ans1="";
  string ans2="";
  logic [7:0] rbrace = ")";
  logic [7:0] lbrace = "(";
  logic [7:0] comma =",";
  integer immediate_value;
  int unsigned pc_val;
  int unsigned var_unsigned;
  string str;
  int comma_flag;
  begin
      //0:rd 1:rs1 2:rs2 3:imm 4:bracket
      if(flag&(1<<`IS_BRACKET_INDEX)) begin
	 if(flag&(1<<`IS_LOAD_INDEX)) begin
		$display("%0s\t%0s%0s%0d%0s%0s%0s",instruction_name,rd,comma,imm,lbrace,rs1,rbrace);
	 end
	 else begin
		$display("%0s\t%0s%0s%0d%0s%0s%0s",instruction_name,rs2,comma,imm,lbrace,rs1,rbrace);
	 end
      end

      else begin
	 ans={instruction_name,ans};
	 $write("%0s\t",ans);
	 comma_flag = 0;
	 if(flag&(1<<`IS_RD)) begin
	     if(comma_flag == 1)
		$write("%0s",comma);
	     $write("%0s",rd);
	     comma_flag = 1;
	 end
	 if(flag&(1<<`IS_RS1)) begin
             if(comma_flag == 1)
                $write("%0s",comma);
             $write("%0s",rs1);
             comma_flag = 1;
         end
	 if(flag&(1<<`IS_RS2)) begin
             if(comma_flag == 1)
                $write("%0s",comma);
             $write("%0s",rs2);
             comma_flag = 1;
         end
	 if(flag&(1<<`IS_IMM)) begin
             if(comma_flag == 1)
                $write("%0s",comma);
	     if(instruction_name == "lui" || instruction_name == "auipc") begin
		$write("0x%0x",imm>>12);
	     end else if( instruction_name == "auipc" ) begin
		$write("0x%0x",imm);
	     end
	     else if(instruction_name == "beq" || instruction_name == "bne" || instruction_name ==  "blt" || instruction_name ==  "bge" || instruction_name ==  "bltu" || instruction_name ==  "bgeu") begin
		var_unsigned = imm;
		pc_val = index;
		$write("0x%0x",pc_val+var_unsigned);
	     end
	     else begin
		if (flag&(1<<`IS_SIGNED_INDEX)) begin
		    var_unsigned = imm;
             	    $write("%0d",var_unsigned);
		end
		else begin
		    $write("%0d",imm);
		end
	     end
             comma_flag = 1;
         end
	 $display();	 
      end
  end
endfunction
