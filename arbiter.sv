module arbiter
(
	input logic clk, L1_i_read, L1_d_read, L2_resp, L1_i_write, L1_d_write,
	input logic [31:0] L1_i_addr, L1_d_addr, 
	input logic [255:0] L2_rdata, L1_i_wdata, L1_d_wdata,
	output logic L1_i_resp, L1_d_resp, L2_read, L2_write,
	output logic [31:0] L2_addr,
	output logic [255:0] data_to_L1, data_to_L2
);
logic stall_i_read, stall_d_read, stall_i_write, stall_d_write;

always_comb begin
	L1_i_resp = 0;
	L1_d_resp = 0;
	L2_read = 0;
	L2_write = 0;
	L2_addr = 0;
	data_to_L1 = 0;
	data_to_L2 = 0;
	//stall_i_read = 0;
	//stall_d_read = 0;
	//stall_i_write = 0;
	//stall_d_write = 0;
	
	if(L1_i_read == 1 || L1_d_read == 1) begin
		L2_read = 1;
		if(L1_d_read == 1 ) begin
			L2_addr = L1_d_addr;
		end
		else begin
			L2_addr = L1_i_addr;
		end
		
		if(L2_resp == 1) begin
			data_to_L1 = L2_rdata;
			if(L1_d_read == 1) begin
				L1_d_resp = 1;
				
			end
			if(L1_i_read == 1) begin
				L1_i_resp = 1;
				
			end
		end
	end
	
	if(L1_i_write == 1 || L1_d_write == 1) begin
		L2_write = 1;
		if(L1_d_write == 1 && L2_resp == 0) begin
			L2_addr = L1_d_addr;
			data_to_L2 = L1_d_wdata;
		end
		else begin
			L2_addr = L1_i_addr;
			data_to_L2 = L1_i_wdata;
		end
	end
end



endmodule: arbiter