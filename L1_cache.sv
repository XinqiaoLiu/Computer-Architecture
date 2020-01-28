module L1_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	//cpu - cache
	input [31:0] mem_address, mem_wdata,
	input logic mem_read, mem_write, 
	input [3:0] mem_byte_enable,
	output [31:0] mem_rdata,
	output logic mem_resp, miss_found,
	
	//memory - cache
	input logic pmem_resp,
	input [255:0] pmem_rdata,
	output pmem_read, pmem_write,
	output logic [31:0] pmem_address,
	output [255:0] pmem_wdata
);

logic read_data, data_out_mux_sel, data_in_mux_sel;
logic read_tag, load_tag0, load_tag1;
logic read_valid, load_valid0, load_valid1;
logic valid_in, valid_mux_sel;
logic read_dirty, load_dirty0, load_dirty1;
logic dirty_in;
logic read_LRU, load_LRU;
logic LRU_in;
logic [31:0] stored_addr;
logic hit_comp_out, which_tag;
logic dirty_out0, dirty_out1;
logic LRU_out;
logic read_set, load_set0, load_set1;
logic hold_write_en;
logic store, stored_read, stored_write;

cache_datapath datapath
(
	.clk,
	.mem_address,
	.mem_wdata,
	.mem_rdata,
	.pmem_rdata,
	.pmem_wdata,
	.pmem_address,
	.mem_byte_enable,
	.mem_read,
	.mem_write,
	//control - datapath
	.stored_addr,
	.stored_read,
	.stored_write,
	.store,
	.mem_resp,
	.hold_write_en,
	.pmem_read,
	.pmem_write,
	.read_data,
	.data_out_mux_sel,
	.data_in_mux_sel,
	.read_tag, 
	.load_tag0, 
	.load_tag1,
	.read_set,
	.load_set0,
	.load_set1,
	.read_valid, 
	.load_valid0, 
	.load_valid1,
	.valid_mux_sel,
	.valid_in,
	.read_dirty, 
	.load_dirty0, 
	.load_dirty1,
	.dirty_in,
	.read_LRU, 
	.load_LRU,
	.LRU_in,
	.hit_comp_out, 
	.which_tag,
	.dirty_out0,
	.dirty_out1,
	.LRU_out
);

cache_control control
(
	.clk,
	.mem_read,
	.mem_write,
	.mem_resp,
	.pmem_resp,
	.pmem_read,
	.pmem_write,
	.miss_found,
	.mem_address,
	
	//control - datapath
	.stored_addr,
	.stored_read,
	.stored_write,
	.store,
	.hold_write_en,
	.read_data,
	.data_out_mux_sel,
	.data_in_mux_sel,
	.read_tag, 
	.load_tag0, 
	.load_tag1,
	.read_set,
	.load_set0,
	.load_set1,
	.read_valid, 
	.load_valid0, 
	.load_valid1,
	.valid_mux_sel,
	.valid_in,
	.read_dirty, 
	.load_dirty0, 
	.load_dirty1,
	.dirty_in,
	.read_LRU, 
	.load_LRU,
	.LRU_in,
	.hit_comp_out, 
	.which_tag,
	.dirty_out0,
	.dirty_out1, 
	.LRU_out
);


endmodule : L1_cache
