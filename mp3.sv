module mp3
(
	input clk,

	input logic pmem_resp,
	input logic [255:0] pmem_rdata, 
	output logic [31:0] pmem_addr, 
	output logic pmem_read, pmem_write,
	output logic [255:0] pmem_wdata
);

logic i_read, d_read, d_write, i_resp, d_resp, i_miss_found;
logic [31:0] i_addr, d_addr, i_rdata, d_rdata, d_wdata;
logic [3:0] mem_byte_enable;

cpu_datapath cpu_datapath
(
	.*
);
cache cache
(
	//cache - CPU
	.clk, 
	.i_read, 
	.d_read, 
	.d_write,
	.i_addr, 
	.d_addr, 
	.d_wdata,
	.mem_byte_enable,
	.i_rdata, 
	.d_rdata, 
	.i_resp, 
	.d_resp,
	.i_miss_found,
	
	//cache - pmem
	.pmem_resp,
	.pmem_rdata, 
	.pmem_addr, 
	.pmem_read, 
	.pmem_write,
	.pmem_wdata
);

endmodule: mp3