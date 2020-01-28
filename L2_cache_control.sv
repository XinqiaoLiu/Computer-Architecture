module L2_cache_control (
	//CPU - Cache
	input clk,
	input logic mem_read, mem_write,
	output logic mem_resp,
	
	//cache control - datapath
	input logic hit_comp_out,
	input logic dirty_out0, dirty_out1, dirty_out2, dirty_out3,
	input logic [2:0] LRU_out,
	input logic [1:0] which_tag,
	
	output logic read_data, data_in_mux_sel,
	output logic [1:0] data_out_mux_sel, 
	output logic read_tag, load_tag0, load_tag1, load_tag2, load_tag3,
	output logic read_valid, load_valid0, load_valid1, load_valid2, load_valid3,  valid_in,
	output logic [1:0] valid_mux_sel,
	output logic read_dirty, load_dirty0, load_dirty1, load_dirty2, load_dirty3, dirty_in,
	output logic read_LRU, load_LRU, 
	output logic read_set, load_set0, load_set1, load_set2, load_set3, hold_write_en,
	output logic [2:0] LRU_in,
	
	//Memory - Cache
	input logic pmem_resp,
	output logic pmem_read, pmem_write
);

enum int unsigned
{
	start,
	determine_hit,
	allocate
} state, next_state;


logic go;
logic stored_read, stored_write;

always_comb
begin: state_actions
	mem_resp = 0;
	read_data = 0;
	read_tag = 1;
	load_tag0 = 0;
	load_tag1 = 0; 
	load_tag2 = 0;
	load_tag3 = 0;
	read_set = 1;
	load_set0 = 0;
	load_set1 = 0;
	load_set2 = 0;
	load_set3 = 0;
	read_dirty = 0;
	load_dirty0 = 0;
	load_dirty1 = 0;
	load_dirty2 = 0;
	load_dirty3 = 0;
	dirty_in = 0; 
	valid_mux_sel = 0;
	read_valid = 0;
	load_valid0 = 0;
	load_valid1 = 0;
	load_valid2 = 0;
	load_valid3 = 0;
	valid_in = 0;
	read_LRU = 0;
	load_LRU = 0;
	LRU_in = 0;
	pmem_read =0;
	pmem_write = 0;
	data_out_mux_sel = 0;
	data_in_mux_sel = 0;
	hold_write_en = 1;
	
	case(state)
		determine_hit: begin
		if(mem_read == 1) begin
			if(which_tag==0) begin
				data_out_mux_sel= 0; 
				case(LRU_out[2])
					0: LRU_in = 3'b000;
					default: LRU_in = 3'b100;
				endcase
			end
			else if (which_tag == 1) begin
				data_out_mux_sel= 1; 
				case(LRU_out[2])
					0: LRU_in = 3'b010;
					default: LRU_in = 3'b110;
				endcase
			end
			else if (which_tag == 2) begin
				data_out_mux_sel= 2; 
				case(LRU_out[1])
					0: LRU_in = 3'b011;
					default: LRU_in = 3'b001;
				endcase
			end
			else begin
				data_out_mux_sel= 3; 
				case(LRU_out[2])
					0: LRU_in = 3'b101;
					default: LRU_in = 3'b111;
				endcase
			end
			
			if(hit_comp_out==1) begin //hit determined
				mem_resp = 1;
				load_LRU = 1;
			end
			else go = 1;
		end
		if(mem_write==1) begin
			dirty_in = 1; //write hit, dirty
			data_in_mux_sel = 1;
			
			if(which_tag==0) begin
				case(LRU_out[2])
					0: LRU_in = 3'b000;
					default: LRU_in = 3'b100;
				endcase
			end
			else if (which_tag == 1) begin
				case(LRU_out[2])
					0: LRU_in = 3'b010;
					default: LRU_in = 3'b110;
				endcase
			end
			else if (which_tag == 2) begin
				case(LRU_out[1])
					0: LRU_in = 3'b011;
					default: LRU_in = 3'b001;
				endcase
			end
			else begin
				case(LRU_out[2])
					0: LRU_in = 3'b101;
					default: LRU_in = 3'b111;
				endcase
			end
			if(hit_comp_out==1) begin //write hit determined
				mem_resp = 1;
				load_LRU = 1;
				hold_write_en = 0;
				if(which_tag==0) load_dirty0 = 1;
				else if(which_tag==1) load_dirty1 = 1;
				else if(which_tag==2) load_dirty2 = 1;
				else load_dirty3 = 1;
			end
			else go = 1;
		end
		end


		allocate: begin
			valid_in = 1;
			dirty_in = 0;
			data_in_mux_sel=0;
			
			
			if(LRU_out[1:0] == 2'b11) begin
				load_dirty0 = 1;
				load_valid0 = 1;
				if(dirty_out0 == 1) pmem_write = 1;
				else begin
					load_tag0 = 1;
					load_set0 = 1;
					pmem_read = 1;
				end
			end
			else if(LRU_out[1:0] == 2'b01) begin
				load_valid1 = 1;
				load_dirty1 = 1;
				if(dirty_out1 == 1) pmem_write = 1;
				else begin
					load_tag1 = 1;
					load_set1 = 1;				
					pmem_read = 1;
				end
			end
			else if(LRU_out == 3'b100 || LRU_out == 3'b110) begin
				load_valid2 = 1;
				load_dirty2 = 1;
				if(dirty_out2 == 1) pmem_write = 1;
				else begin
					load_tag2= 1;
					load_set2 = 1;				
					pmem_read = 1;
				end
			end
			else begin
				load_valid3 = 1;
				load_dirty3 = 1;
				if(dirty_out3 == 1) pmem_write = 1;
				else begin
					load_tag3= 1;
					load_set3 = 1;				
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
	
		default: next_state = start;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end
endmodule : L2_cache_control

