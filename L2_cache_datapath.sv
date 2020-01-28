module L2_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	//CPU - Cache
	input [31:0] mem_address,
	input [255:0] mem_wdata,
	input [7:0] mem_byte_enable,
	input logic mem_read, mem_write,
	output logic [255:0] mem_rdata,
	
	//cache control - cache datapath
	input logic read_data,  data_in_mux_sel,//data_array
	input logic [1:0] data_out_mux_sel, valid_mux_sel, 
	input logic read_tag, load_tag0, load_tag1, load_tag2, load_tag3,//tag_array
	input logic read_valid, load_valid0, load_valid1, load_valid2, load_valid3, valid_in,//valid bit array
	input logic read_dirty, load_dirty0, load_dirty1, load_dirty2, load_dirty3, dirty_in, //dirty bit array
	input logic read_LRU, load_LRU, //LRU bit array
	input logic read_set, load_set0, load_set1, load_set2, load_set3, pmem_read, hold_write_en, pmem_write, 
	input logic [2:0] LRU_in,
	
	output logic hit_comp_out, 
	output logic [1:0] which_tag,
	output logic dirty_out0, dirty_out1, dirty_out2, dirty_out3,
	output logic [2:0] LRU_out,
	//output logic stored_read, stored_write,
	
	//Memory - Cache
	input [255:0] pmem_rdata,
	output [255:0] pmem_wdata,
	output logic [31:0] pmem_address	
);

logic [31:0] data_enable0, data_enable1, data_enable2, data_enable3, mem_byte_enable256, mem_rdata_bus_out;
logic [255:0] data_out0, data_out1, data_out2, data_out3, data_array_mux_out, data_in_mux_out;		//data_array
logic [2:0] set_index, set_out0, set_out1, set_out2, set_out3;
logic [23:0] tag_bits, tag_out0, tag_out1, tag_out2, tag_out3;  //tag array
logic [4:0] offset;
logic valid_out0, valid_out1, valid_out2, valid_out3; //valid bit array
//logic dirty_out0, dirty_out1; //dirty bit array
logic tag_comp_out, valid_mux_out;
logic [255:0] mem_write_mux_ou, data_in_write;

//mp3LRU_in
logic [31:0] stored_addr, stored_wdata;
logic [3:0]  stored_mem_byte_enable;
logic [1:0] mem_write_mux_sel;

always_comb
begin
	set_index = mem_address[7:5];
	tag_bits = mem_address[31:8];
	offset = mem_address[4:0];
	data_enable0 = 0;
	data_enable1 = 0;
	data_enable2 = 0;
	data_enable3 = 0;
	pmem_address = 0;

	if(pmem_write == 1) begin
		if(LRU_out==0) pmem_address = {tag_out0, set_out0, 5'b0};
		else pmem_address = {tag_out0, set_out0, 5'b0};
	end
	
	if(pmem_read == 1) begin
		pmem_address = mem_address;
		case(LRU_out)
		3'b011, 3'b111: begin
			data_enable0 = {32{1'b1}};
		end
		3'b001, 3'b101: begin
			data_enable1 = {32{1'b1}};	
		end
		3'b100, 3'b110: begin
			data_enable2 = {32{1'b1}};	
		end
		default: data_enable3 = {32{1'b1}};	
		endcase
	end
	
	if(mem_write == 1 && hold_write_en == 0)begin
		case(which_tag)
		0: data_enable0 = {32{1'b1}};
		1: data_enable1 = {32{1'b1}};	
		2: data_enable2 = {32{1'b1}};	
		default: data_enable3 = {32{1'b1}};	
		endcase
	end
	
	if(LRU_out[1:0] == 2'b11) mem_write_mux_sel = 0;
	else if(LRU_out[1:0] == 2'b01) mem_write_mux_sel = 1;
	else if(LRU_out == 3'b100 || LRU_out == 3'b110) mem_write_mux_sel = 2;
	else mem_write_mux_sel = 3;
	
end


mux4 #(256) mem_write_mux
(
	.sel(mem_write_mux_sel),
	.a(data_out0),
	.b(data_out1),
	.c(data_out2),
	.d(data_out3),
	.f(pmem_wdata)
);
/*
line_adapter line_adapter
(
	.mem_wdata256(data_in_write),
	.mem_rdata256(),
	.mem_wdata(),
	.mem_rdata(),
	.mem_byte_enable,
	.mem_byte_enable256,
	.resp_address(stored_addr),
	.address(mem_address)
);
*/
mux2 #(256) data_in_mux
(
	.sel(data_in_mux_sel),
	.a(pmem_rdata), //read miss
	.b(mem_wdata), 
	.f(data_in_mux_out)
);
mux4 #(256) data_out_mux
(
	.sel(data_out_mux_sel),
	.a(data_out0),
	.b(data_out1),
	.c(data_out2),
	.d(data_out3),
	.f(mem_rdata)
);
data_array line [4]
(
	clk,
	read_data,
	{data_enable0,data_enable1, data_enable2, data_enable3},
	set_index,
	set_index,
	data_in_mux_out,
	{data_out0, data_out1, data_out2, data_out3}
);

array #(3,3) set_arrays [4]
(
	clk,
	read_set,
	{load_set0, load_set1, load_set2, load_set3},
	set_index,
	set_index,
	set_index,
	{set_out0, set_out1, set_out2, set_out3}
);
array #(3,24) tag[4]
(
	clk,
	read_tag,
	{load_tag0, load_tag1, load_tag2, load_tag3},
	set_index,
	set_index,
	tag_bits,
	{tag_out0,tag_out1, tag_out2, tag_out3}
);


L2_tag_cmp tag_cmp
(
	.a(tag_bits),
	.b(tag_out0),
	.c(tag_out1),
	.d(tag_out2),
	.e(tag_out3),
	.f(tag_comp_out),
	.g(which_tag)
);

hit_cmp hit_cmp
(
	.a(tag_comp_out),
	.b(valid_mux_out),
	.f(hit_comp_out)
);

array #(3, 1) valid [4]
(
	clk,
	read_valid,
	{load_valid0, load_valid1, load_valid2, load_valid3},
	set_index,
	set_index,
	valid_in,
	{valid_out0, valid_out1, valid_out2, valid_out3}
);


mux4 #(1) valid_mux
(
	.sel(which_tag),
	.a(valid_out0),
	.b(valid_out1),
	.c(valid_out2),
	.d(valid_out3),
	.f(valid_mux_out)
);

array #(3, 1) dirty[4]
(
	clk,
	read_dirty,
	{load_dirty0,load_dirty1, load_dirty2, load_dirty3},
	set_index,
	set_index,
	dirty_in,
	{dirty_out0, dirty_out1, dirty_out2, dirty_out3}
);


array #(3, 3) LRU
(
	.clk,
	.read(read_LRU),
	.load(load_LRU),
	.datain(LRU_in),
	.rindex(set_index),
	.windex(set_index),
	.dataout(LRU_out)
);
endmodule : L2_cache_datapath

