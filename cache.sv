module cache
(
	//cache - CPU
	input logic clk, i_read, d_read, d_write,
	input logic [31:0] i_addr, d_addr, d_wdata,
	input [3:0] mem_byte_enable,
	output logic [31:0] i_rdata, d_rdata, 
	output logic i_resp, d_resp, i_miss_found,
	
	//cache - pmem
	input logic pmem_resp,
	input logic [255:0] pmem_rdata, 
	output logic [31:0] pmem_addr, 
	output logic pmem_read, pmem_write,
	output logic [255:0] pmem_wdata
);

//L1
logic L1_i_resp, L1_d_resp, L1_i_read, L1_d_read, L1_i_write, L1_d_write;
logic [31:0] L1_i_addr, L1_d_addr; 
logic [255:0] data_to_L1, L1_i_wdata, L1_d_wdata;

//L2
logic L2_resp, L2_read, L2_write, d_miss_found;
logic [31:0] L2_addr;
logic [255:0] L2_rdata, data_to_L2;

always_comb begin
	// CP 2
	/*
	L2_resp = pmem_resp; 
	pmem_addr = L2_addr;
	L2_rdata = pmem_rdata;
	pmem_read = L2_read;
	pmem_write = L2_write; 
	pmem_wdata = data_to_L2;
	*/
end

L2_cache L2_cache
(
	.clk,
	.mem_address(L2_addr),
	.mem_read(L2_read),
	.mem_write(L2_write),
	.mem_resp(L2_resp),
	.mem_rdata(L2_rdata),
	.mem_wdata(data_to_L2),
	.mem_byte_enable(8'b11111111),
	
	.pmem_address(pmem_addr),
	.pmem_read,
	.pmem_write,
	.pmem_resp,
	.pmem_rdata,
	.pmem_wdata
);


arbiter arbiter
(
	.clk,
	.L1_i_read, 
	.L1_i_write, 
	.L1_i_addr,
	.L1_i_wdata,
	.L1_i_resp, 
	
	.L1_d_read, 
	.L1_d_write,
	.L1_d_addr, 
	.L1_d_wdata,
	.L1_d_resp, 
	.data_to_L1,
	
	.L2_resp,
	.L2_read, 
	.L2_write,
	.L2_addr, 
	.L2_rdata, 
	.data_to_L2
);

L1_cache L1_i_cache
(
	.clk,
	//IF - L1_i_cache
	.mem_address(i_addr), 
	.mem_read(i_read),
	.mem_write(), //i_cache is read-only
	.mem_wdata(), //CPU will not write instructions 
	.mem_byte_enable(4'b1111), //always read 32-bit instructions 
	.mem_rdata(i_rdata),
	.mem_resp(i_resp),
	.miss_found(i_miss_found),
	
	//L1 - arbiter 
	.pmem_resp(L1_i_resp),
	.pmem_rdata(data_to_L1),
	.pmem_read(L1_i_read), 
	.pmem_write(L1_i_write), //evict replaced instructions 
	.pmem_address(L1_i_addr),
	.pmem_wdata(L1_i_wdata)
);

L1_cache L1_d_cache
(
	.clk,
	//MEM - L1_d_cache
	.mem_address(d_addr), 
	.mem_wdata(d_wdata),
	.mem_read(d_read), 
	.mem_write(d_write), 
	.mem_byte_enable,
	.mem_rdata(d_rdata),
	.mem_resp(d_resp),
	.miss_found(d_miss_found),
	
	//L1 - arbiter
	.pmem_resp(L1_d_resp),
	.pmem_rdata(data_to_L1),
	.pmem_read(L1_d_read), 
	.pmem_write(L1_d_write),
	.pmem_address(L1_d_addr),
	.pmem_wdata(L1_d_wdata)
);

endmodule: cache