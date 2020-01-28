module fwd_unit
(
	input logic [4:0] wb_dr, ex_sr1, ex_sr2, id_sr1, id_sr2, mem_dr, mem_sr1, mem_sr2,
	input logic [31:0] wb_data, mem_data, alu_buffer_out,
	input logic write_regreg, write_dmem, dmem_action,
	
	
	output logic [31:0] wb_to_ex1, wb_to_ex2, mem_to_ex1, mem_to_ex2, wb_to_mem_rs1, wb_to_mem_rs2,
	output logic wb_to_ex_fwd1, wb_to_ex_fwd2, mem_to_ex_fwd1, mem_to_ex_fwd2, wb_to_mem_fwd1, wb_to_mem_fwd2

);

always_comb begin
	wb_to_ex1 = 0;
	wb_to_ex2 = 0;
	mem_to_ex1 = 0;
	mem_to_ex2 = 0;
	wb_to_mem_fwd1 = 0;
	wb_to_mem_fwd2 = 0;
	
	wb_to_ex_fwd1 = 0;
	wb_to_ex_fwd2 = 0;
	mem_to_ex_fwd1 = 0;
	mem_to_ex_fwd2 = 0;
	wb_to_mem_rs1 = 0;
	wb_to_mem_rs2 = 0;

	if((write_regreg==1 || write_dmem==1)) begin
	//MEM forwarding
		if(write_dmem==1 && wb_dr != 0 && wb_dr == ex_sr1) begin
			wb_to_ex_fwd1 = 1;
			wb_to_ex1 = wb_data;
		end
		if(write_dmem==1 && wb_dr != 0  && wb_dr == ex_sr2) begin
			wb_to_ex_fwd2 = 1;
			wb_to_ex2 = wb_data;
		end
		
	//regreg forwarding	
		if(write_regreg==1 && mem_dr != 0  && mem_dr==ex_sr1) begin
			mem_to_ex_fwd1 = 1;
			if(dmem_action==1) mem_to_ex1 = mem_data;
			else mem_to_ex1 = alu_buffer_out;
		end
		if(write_regreg==1 && mem_dr != 0  && mem_dr==ex_sr2) begin
			mem_to_ex_fwd2 = 1;
			if(dmem_action== 1) mem_to_ex2 = mem_data;
			else mem_to_ex2 = alu_buffer_out;
		end
	//wb to mem forwarding
		if(write_regreg==1 && mem_dr != 0  && wb_dr == mem_sr1) begin
			wb_to_mem_fwd1 = 1;
			wb_to_mem_rs1 = wb_data;
		end
		if(write_regreg==1 && mem_dr != 0  && wb_dr == mem_sr2) begin
			wb_to_mem_fwd2 = 1;
			wb_to_mem_rs2 = wb_data;
		end
	end
	
end



endmodule: fwd_unit