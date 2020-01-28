
module cache_datapath #(
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
	input [31:0] mem_wdata,
	input [3:0] mem_byte_enable,
	input logic mem_read, mem_write,
	output logic [31:0] mem_rdata,
	
	//cache control - cache datapath
	input logic read_data, data_out_mux_sel, data_in_mux_sel,//data_array
	input logic read_tag, load_tag0, load_tag1, //tag_array
	input logic read_valid, load_valid0, load_valid1, valid_mux_sel, valid_in,//valid bit array
	input logic read_dirty, load_dirty0, load_dirty1, dirty_in, //dirty bit array
	input logic read_LRU, load_LRU, LRU_in, //LRU bit array
	input logic read_set, load_set0, load_set1, pmem_read, hold_write_en, pmem_write, mem_resp, store,
	
	output logic hit_comp_out, which_tag,
	output logic dirty_out0, dirty_out1,
	output logic LRU_out,
	output logic stored_read, stored_write,
	output logic [31:0] stored_addr,
	
	//Memory - Cache
	input [255:0] pmem_rdata,
	output [255:0] pmem_wdata,
	output logic [31:0] pmem_address	
);

logic [31:0] data_enable0, data_enable1, mem_byte_enable256, mem_rdata_bus_out;
logic [255:0] data_out0, data_out1, data_array_mux_out, data_in_mux_out;		//data_array
logic [2:0] set_index, set_out0, set_out1;
logic [23:0] tag_bits, tag_out0, tag_out1;  //tag array
logic [4:0] offset;
logic valid_out0, valid_out1; //valid bit array
//logic dirty_out0, dirty_out1; //dirty bit array
logic tag_comp_out, valid_mux_out;
logic [255:0] mem_write_mux_ou, data_in_write;

//mp3
logic [31:0] stored_wdata, rdata_out;
logic [3:0]  stored_mem_byte_enable;


always_comb
begin
	set_index = mem_address[7:5];
	tag_bits = mem_address[31:8];
	offset = mem_address[4:0];
	data_enable0 = 0;
	data_enable1 = 0;
	pmem_address = 0;

	if(mem_resp == 0) mem_rdata = 0;
	else mem_rdata = rdata_out;
	
	if(pmem_write == 1) begin
		if(LRU_out==0) pmem_address = {tag_out0, set_out0, 5'b0};
		else pmem_address = {tag_out0, set_out0, 5'b0};
	end
	
	if(pmem_read == 1) begin
		pmem_address = mem_address;
		case(LRU_out)
		0: begin
			data_enable0 = {32{1'b1}};
		end
		default: begin
			data_enable1 = {32{1'b1}};	
		end
		endcase
	end
	
	if(mem_write == 1 && hold_write_en == 0)begin
		case(which_tag)
		0: data_enable0 = {28'h0, mem_byte_enable} << (mem_address[4:2]*4);
		default: data_enable1 = {28'h0, mem_byte_enable} << (mem_address[4:2]*4);
		endcase
	end
	
end



register store_addr
(
	.clk,
	.load(store),
	.in(mem_address),
	.out(stored_addr)
);

register #(1) store_read
(
	.clk,
	.load(store),
	.in(mem_read),
	.out(stored_read)
);

register #(1) store_write
(
	.clk,
	.load(store),
	.in(mem_write),
	.out(stored_write)
	
);

register #(4) store_enable
(
	.clk,
	.load(store),
	.in(mem_byte_enable),
	.out(stored_mem_byte_enable)
);

register store_wdata
(
	.clk,
	.load(store),
	.in(mem_wdata),
	.out(stored_wdata)
);


mem_rdata_bus mem_rdata_bus
(
	.index(offset[4:2]),
	.data_in(data_array_mux_out),
	.data_out(rdata_out)
);

mux2 #(256) mem_write_mux
(
	.sel(LRU_out),
	.a(data_out0),
	.b(data_out1),
	.f(pmem_wdata)
);

line_adapter line_adapter
(
	.mem_wdata256(data_in_write),
	.mem_rdata256(),
	.mem_wdata,
	.mem_rdata(),
	.mem_byte_enable,
	.mem_byte_enable256,
	.resp_address(stored_addr),
	.address(mem_address)
);

mux2 #(256) data_in_mux
(
	.sel(data_in_mux_sel),
	.a(pmem_rdata), //read miss
	.b(data_in_write), 
	.f(data_in_mux_out)
);

data_array line [2]
(
	clk,
	read_data,
	{data_enable0,data_enable1},
	set_index,
	set_index,
	data_in_mux_out,
	{data_out0,data_out1}
);
/*
data_array data_a0
(
	.clk,
	.read(read_data),
	.index(set_index),
	.write_en(mem_byte_enable256),
	.datain(data_in_mux_out),
	.dataout(data_out0)
);

data_array data_a1
(
	.clk,
	.read(read_data),
	.write_en(mem_byte_enable256),
	.index(set_index),
	.datain(data_in_mux_out),
	.dataout(data_out1)
);
*/
mux2 #(256) data_out_mux
(
	.sel(data_out_mux_sel),
	.a(data_out0),
	.b(data_out1),
	.f(data_array_mux_out)
);

array #(3, 3) set_index_a0
(
	.clk,
	.read(read_set),
	.load(load_set0),
	.datain(set_index),
	.rindex(set_index),
	.windex(set_index),
	.dataout(set_out0)
);

array #(3, 3) set_index_a1
(
	.clk,
	.read(read_set),
	.load(load_set1),
	.datain(set_index),
	.rindex(set_index),
	.windex(set_index),
	.dataout(set_out1)
);
/*
mux2 set_mux
(
	.sel(set_mux_sel),
	.a(set_out0),
	.b(set_out1),
	.f(set_mux_out)
);
*/
array #(3,24) tag[2]
(
	clk,
	read_tag,
	{load_tag0, load_tag1},
	set_index,
	set_index,
	tag_bits,
	{tag_out0,tag_out1}
);

/*
array #(3, 24, 8) tag_a0
(
	.clk,
	.read(read_tag),
	.load(load_tag0),
	.datain(tag),
	.index(set_index),
	.dataout(tag_out0)
);

array #(3, 24, 8) tag_a1
(
	.clk,
	.read(read_tag),
	.load(load_tag1),
	.datain(tag),
	.index(set_index),
	.dataout(tag_out1)
);
*/

tag_cmp tag_cmp
(
	.a(tag_bits),
	.b(tag_out0),
	.c(tag_out1),
	.f(tag_comp_out),
	.g(which_tag)
);

hit_cmp hit_cmp
(
	.a(tag_comp_out),
	.b(valid_mux_out),
	.f(hit_comp_out)
);

array #(3, 1) valid_a0
(
	.clk,
	.read(read_valid),
	.load(load_valid0),
	.datain(valid_in),
	.rindex(set_index),
	.windex(set_index),
	.dataout(valid_out0)
);

array #(3, 1) valid_a1
(
	.clk,
	.read(read_valid),
	.load(load_valid1),
	.datain(valid_in),
	.rindex(set_index),
	.windex(set_index),
	.dataout(valid_out1)
);

mux2 #(1) valid_mux
(
	.sel(which_tag),
	.a(valid_out0),
	.b(valid_out1),
	.f(valid_mux_out)
);
array #(3, 1) dirty_a0
(
	.clk,
	.read(read_dirty),
	.load(load_dirty0),
	.datain(dirty_in),
	.rindex(set_index),
	.windex(set_index),
	.dataout(dirty_out0)
);

array #(3, 1) dirty_a1
(
	.clk,
	.read(read_dirty),
	.load(load_dirty1),
	.datain(dirty_in),
	.rindex(set_index),
	.windex(set_index),
	.dataout(dirty_out1)
);

array  LRU
(
	.clk,
	.read(read_LRU),
	.load(load_LRU),
	.datain(LRU_in),
	.rindex(set_index),
	.windex(set_index),
	.dataout(LRU_out)
);
endmodule : cache_datapath

