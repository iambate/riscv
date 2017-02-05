
function void get_output_string(logic [40:0] rd, logic [40:0] rs1, logic [40:0] rs2, logic signed [31:0] imm, logic [7:0] flag, logic [96:0] instruction_name);
  string ans="";
  string ans1="";
  string ans2="";
  logic [7:0] rbrace = ")";
  logic [7:0] lbrace = "(";
  logic [7:0] comma =",";
  integer immediate_value;
  string str;
  begin
/*
      ans = {rd,ans};
      ans = {rs1,ans};
      ans = {rs2,ans};
      ans = {imm,ans};
      ans = {instruction_name,ans};
*/
      //0:rd 1:rs2 2:rs2 3:imm 4:bracket
      if(flag&(1<<4)) begin
	 ans1 = {rbrace,ans1};
	 ans1 = {rs1,ans1};
         ans1 = {lbrace,ans1};
	 immediate_value = imm;
	 if(flag&(1<<7)) begin
		ans2 = {comma,ans2};
                ans2 = {rd,ans2};
                ans2 = {"\t",ans2};
                ans2 = {instruction_name,ans2};
	 end
	 else begin
         	ans2 = {comma,ans2};
   	 	ans2 = {rs2,ans2};
	 	ans2 = {"\t",ans2};
	 	ans2 = {instruction_name,ans2};
	 end
	 $display("%s%d%s",ans2,immediate_value,ans1);
      end
/*
      else if(flag&1)
      	   if(flag&(1<<1))
           if(flag&(1<<2))
           if(flag&(1<<3))
*/
      else begin
	 ans = "hi";
      end
  end
endfunction
