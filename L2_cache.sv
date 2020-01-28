module L2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	//arbiter to L2 cache
	input [31:0] mem_address, 
	input logic mem_read, mem_write, 
	input [7:0] mem_byte_enable,
	output [255:0] mem_rdata, 
	output logic mem_resp,
	
	//memory - cache
	input logic pmem_resp,
	input [255:0] pmem_rdata, mem_wdata,
	output pmem_read, pmem_write,
	output logic [31:0] pmem_address,
	output [255:0] pmem_wdata
);

logic read_data,  data_in_mux_sel;
logic [1:0] data_out_mux_sel,valid_mux_sel;
logic read_tag, load_tag0, load_tag1, load_tag2, load_tag3;
logic read_valid, load_valid0, load_valid1, load_valid2, load_valid3;
logic valid_in;
logic read_dirty, load_dirty0, load_dirty1, load_dirty2, load_dirty3;
logic dirty_in;
logic read_LRU, load_LRU;
logic [2:0] LRU_out, LRU_in;

logic [31:0] mem_address_to_control;
logic hit_comp_out;
logic [1:0] which_tag;
logic dirty_out0, dirty_out1, dirty_out2, dirty_out3;
logic read_set, load_set0, load_set1, load_set2, load_set3;
logic hold_write_en;

L2_cache_datapath datapath
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
	.hold_write_en,
	.pmem_read,
	.pmem_write,
	.read_data,
	.data_out_mux_sel,
	.data_in_mux_sel,
	.read_tag, 
	.load_tag0, 
	.load_tag1,
	.load_tag2,
	.load_tag3,
	.read_set,
	.load_set0,
	.load_set1,
	.load_set2,
	.load_set3,
	.read_valid, 
	.load_valid0, 
	.load_valid1,
	.load_valid2,
	.load_valid3,
	.valid_mux_sel,
	.valid_in,
	.read_dirty, 
	.load_dirty0, 
	.load_dirty1,
	.load_dirty2,
	.load_dirty3,
	.dirty_in,
	.read_LRU, 
	.load_LRU,
	.LRU_in,
	.hit_comp_out, 
	.which_tag,
	.dirty_out0,
	.dirty_out1,
	.dirty_out2,
	.dirty_out3,
	.LRU_out
);

L2_cache_control control
(
	.clk,
	.mem_read,
	.mem_write,
	.mem_resp,
	.pmem_resp,
	.pmem_read,
	.pmem_write,
	
	//control - datapath
	.hold_write_en,
	.read_data,
	.data_out_mux_sel,
	.data_in_mux_sel,
	.read_tag, 
	.load_tag0, 
	.load_tag1,
	.load_tag2,
	.load_tag3,
	.read_set,
	.load_set0,
	.load_set1,
	.load_set2,
	.load_set3,
	.read_valid, 
	.load_valid0, 
	.load_valid1,
	.load_valid2,
	.load_valid3,
	.valid_mux_sel,
	.valid_in,
	.read_dirty, 
	.load_dirty0, 
	.load_dirty1,
	.load_dirty2,
	.load_dirty3,
	.dirty_in,
	.read_LRU, 
	.load_LRU,
	.LRU_in,
	.hit_comp_out, 
	.which_tag,
	.dirty_out0,
	.dirty_out1, 
	.dirty_out2,
	.dirty_out3,
	.LRU_out
);


endmodule : L2_cache
