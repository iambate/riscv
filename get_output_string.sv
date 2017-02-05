function string get_output_string(logic [40:0] rd, logic [40:0] rs1, logic [40:0] rs2, logic signed [31:0] imm, logic [7:0] flag, logic [96:0] instruction_name);
  string ans="";
  begin
/*
      ans = {rd,ans};
      ans = {rs1,ans};
      ans = {rs2,ans};
      ans = {imm,ans};
      ans = {instruction_name,ans};
*/
      //0:rd 1:rs2 2:rs2 3:imm 4:bracket
      return ans;
  end
endfunction
