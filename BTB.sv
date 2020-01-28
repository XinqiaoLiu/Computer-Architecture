module BTB
(
	input logic clk,
	input logic[31:0] prev_pc, update_pc, jump_addr_by_alu,
	input logic true_valid,
	
	output logic[31:0] target
);

logic [31:0] BTB_data[16];
logic valid[16];
logic [3:0] index;

initial
begin
	for(int i = 0; i < $size(BTB_data); i++)
	begin
		BTB_data[i] = 32'b0;
		valid[i] = 0;
	end
	target = 0;
end		

always_comb begin
	index = prev_pc[5:2];
end

always_ff@(posedge clk)
begin
	if(valid[index]==1) begin
		target = BTB_data[index];
	end
	
	if(true_valid) begin
		BTB_data[update_pc[5:2]] = jump_addr_by_alu;
		valid[update_pc[5:2]] = 1;
	end
	
end


endmodule: BTB