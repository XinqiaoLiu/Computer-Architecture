
module cache_control (
	//CPU - Cache
	input clk,
	input logic mem_read, mem_write,
	output logic mem_resp, miss_found,
	
	//cache control - datapath
	input logic hit_comp_out, which_tag,
	input logic dirty_out0, dirty_out1,
	input logic LRU_out, stored_read, stored_write,
	input logic [31:0] stored_addr, mem_address,
	

	
	output logic read_data, data_out_mux_sel, data_in_mux_sel,
	output logic read_tag, load_tag0, load_tag1,
	output logic read_valid, load_valid0, load_valid1, valid_mux_sel, valid_in,
	output logic read_dirty, load_dirty0, load_dirty1, dirty_in,
	output logic read_LRU, load_LRU, LRU_in, store,
	output logic read_set, load_set0, load_set1, hold_write_en,
	
	//Memory - Cache
	input logic pmem_resp,
	output logic pmem_read, pmem_write
);

enum int unsigned
{
	start,
	determine_hit,
	allocate,
	start_2,
	determine_hit_2,
	allocate_2
} state, next_state;


always_comb
begin: state_actions
	mem_resp = 0;
	read_data = 0;
	read_tag = 1;
	load_tag0 = 0;
	load_tag1 = 0; 
	read_set = 1;
	load_set0 = 0;
	load_set1 = 0;
	read_dirty = 0;
	load_dirty0 = 0;
	load_dirty1 = 0;
	dirty_in = 0; 
	valid_mux_sel = 0;
	read_valid = 0;
	load_valid0 = 0;
	load_valid1 = 0;
	valid_in = 0;
	read_LRU = 0;
	load_LRU = 0;
	LRU_in = 0;
	pmem_read =0;
	pmem_write = 0;
	data_out_mux_sel = 0;
	data_in_mux_sel = 0;
	hold_write_en = 1;
	store = 0;
	//miss_found = 0;
	
	case(state)
		determine_hit: begin
		store = 1;
		if(mem_read == 1) begin
			if(which_tag==0) begin
				data_out_mux_sel= 0; 
				LRU_in = 1;
			end
			else begin
				data_out_mux_sel= 1; 
				LRU_in = 0;
			end
			if(hit_comp_out==1 && mem_address == stored_addr) begin //hit determined
				mem_resp = 1;
				load_LRU = 1;
				miss_found = 0;
			end
			else miss_found = 1;
		end
		if(mem_write==1) begin
			dirty_in = 1; //write hit, dirty
			case (which_tag) 
				0: begin
					data_in_mux_sel = 1;
					LRU_in = 1;
				end
				default: begin
					data_in_mux_sel = 1;
					LRU_in = 0;
				end
			endcase
			if(hit_comp_out==1) begin //write hit determined
				mem_resp = 1;
				load_LRU = 1;
				hold_write_en = 0;
				miss_found = 0;
				if(which_tag==0) load_dirty0 = 1;
				else load_dirty1 = 1;
			end
			else miss_found = 1;
		end
		end
		
		determine_hit_2: begin
		if(stored_read == 1) begin
			if(which_tag==0) begin
				data_out_mux_sel= 0; 
				LRU_in = 1;
			end
			else begin
				data_out_mux_sel= 1; 
				LRU_in = 0;
			end
			if(hit_comp_out==1) begin //hit determined
				mem_resp = 1;
				load_LRU = 1;
			end
		end
		if(stored_write==1) begin
			dirty_in = 1; //write hit, dirty
			case (which_tag) 
				0: begin
					data_in_mux_sel = 1;
					LRU_in = 1;
				end
				default: begin
					data_in_mux_sel = 1;
					LRU_in = 0;
				end
			endcase
			if(hit_comp_out==1) begin //write hit determined
				mem_resp = 1;
				load_LRU = 1;
				hold_write_en = 0;
				if(which_tag==0) load_dirty0 = 1;
				else load_dirty1 = 1;
			end
		end
		end


		allocate: begin
			valid_in = 1;
			dirty_in = 0;
			data_in_mux_sel=0;
			
			
			if(LRU_out==0) begin
				load_dirty0 = 1;
				load_valid0 = 1;
				if(dirty_out0 == 1) pmem_write = 1;
				else begin
					load_tag0 = 1;
					load_set0 = 1;
					pmem_read = 1;
				end
			end
			else begin
				load_valid1 = 1;
				load_dirty1 = 1;
				if(dirty_out1 == 1) pmem_write = 1;
				else begin
					load_tag1 = 1;
					load_set1 = 1;				
					pmem_read = 1;
				end
			end
		end
		
		
		allocate_2: begin
			valid_in = 1;
			dirty_in = 0;
			data_in_mux_sel=0;
			
			if(LRU_out==0) begin
				load_dirty0 = 1;
				load_valid0 = 1;
				if(dirty_out0 == 1) pmem_write = 1;
				else begin
					load_tag0 = 1;
					load_set0 = 1;
					pmem_read = 1;
				end
			end
			else begin
				load_valid1 = 1;
				load_dirty1 = 1;
				if(dirty_out1 == 1) pmem_write = 1;
				else begin
					load_tag1 = 1;
					load_set1 = 1;				
					pmem_read = 1;
				end
			end
		end
		
		default: begin  //start state
			read_tag = 1;
			read_data = 1;
			read_valid = 1;
			read_dirty = 1;
			read_LRU = 1;
			read_set = 1;
		end
	endcase
end

always_comb
begin: next_state_logic
	case(state)
		start: begin
			if(mem_read == 1 || mem_write ==1) next_state = determine_hit;
			else next_state = start;
		end
		
		determine_hit: begin
			if(hit_comp_out==1) next_state = start;
			else if(pmem_read==0 && pmem_write==0)next_state = allocate;
			else next_state = determine_hit;
		end
		
		allocate: begin
			if(pmem_resp==1) next_state = start;
			else next_state = allocate;
		end
	
		start_2: begin
			if(stored_read == 1 || stored_write ==1) next_state = determine_hit_2;
			else next_state = start_2;
		end
		
		determine_hit_2: begin
			if(hit_comp_out==1) next_state = start;
			else next_state = allocate_2;
		end
		
		allocate_2: begin
			if(pmem_resp == 1) next_state = start_2;
			else next_state = allocate_2;
		end
	
		default: next_state = start;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end
endmodule : cache_control

