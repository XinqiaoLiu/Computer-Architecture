import rv32i_types::*;
module cpu_datapath
(
	input clk,

    /* Port i_cache */
    output logic i_read,
    output logic [31:0] i_addr,
    input logic i_resp, i_miss_found,
    input logic [31:0] i_rdata,

    /* Port d_cache */
    output d_read,
    output d_write,
    output [3:0] mem_byte_enable,
    output [31:0] d_addr,
    output [31:0] d_wdata,
    input logic d_resp,
    input logic [31:0] d_rdata
);

rv32i_control_word ctrl_de_ex, ctrl_ex_mem, ctrl_mem_wb, ctrl_wb;
logic [31:0] jump_address, jump_address_buffer_out, data_to_wb;
logic [31:0] alu_buffer_out, alu_buffer_out2, rdata_buffer_out;
logic [31:0] wb_data, i_imm, s_imm, b_imm, u_imm, j_imm;
logic br_en, br_buffer_out;
logic load_wb, load_mem, load_ex, load_de, load_if, dmem_action;

//IF stage values
logic [31:0] pc_out, pc_buffer_out, pc_plus4, pc_plus4_buffer_out;

//EX stage values
rv32i_word alu_out, pc_buffer_out_de_ex, pc_plus4_buffer_out_de_ex, wb_to_ex1, wb_to_ex2, mem_to_ex1, mem_to_ex2, wb_to_mem_rs1, wb_to_mem_rs2;
rv32i_word ir_data_buffer_in, ir_data_buffer_out, pc_buffer_in, pc_plus4_buffer_in;
logic mem_to_ex_fwd1, mem_to_ex_fwd2, wb_to_ex_fwd1, wb_to_ex_fwd2, wb_to_mem_fwd1, wb_to_mem_fwd2;
logic stall_all, to_ex_fwd, flush, true_valid, predicted;
rv32i_word target;

always_comb
begin
	i_addr = pc_out;
	stall_all = 0;
	dmem_action = ((d_read==1 || d_write==1) && d_resp == 0);
	load_wb = 0;
	load_mem = 0;
	load_ex = 0;
	load_de = 0;
	load_if = 0;
	ir_data_buffer_in = i_rdata;
	pc_buffer_in = pc_out;
	pc_plus4_buffer_in = pc_plus4;
	true_valid= 0;
	
	//stage register load logic
	if(dmem_action == 1 && d_resp == 0) begin
		stall_all = 1; //write back stage needs to be stalled therefore stall all stages
		i_read = 0;
	end
	else begin
		stall_all = 0;
		i_read = 1;
	end
	
	if(stall_all == 0) begin
		load_wb = 1;
		load_mem = 1;
		load_ex = ~i_miss_found;
		load_de = load_ex;
		load_if = ((load_ex & i_resp) || (predicted==1) || (ctrl_mem_wb.opcode == op_jal || ctrl_mem_wb.opcode == op_jalr));
	end
	
	if((br_buffer_out != ctrl_mem_wb.prev_prediction) && (ctrl_mem_wb.opcode == op_br)) begin
		flush = 1;
		load_if = 1;
	end
	else flush = 0;
	
	if(ctrl_mem_wb.opcode == op_br) true_valid = 1;
	
	if(flush == 1) begin
		ir_data_buffer_in = 0;
		pc_buffer_in = 0;
		pc_plus4_buffer_in = 0;
		load_de = 1;
		load_ex = 1;
		load_mem = 1;
		load_wb = 0;
	end
	

	i_imm = {{21{ir_data_buffer_out[31]}}, ir_data_buffer_out[30:20]};
   s_imm = {{21{ir_data_buffer_out[31]}}, ir_data_buffer_out[30:25], ir_data_buffer_out[11:7]};
	b_imm = {{20{ir_data_buffer_out[31]}}, ir_data_buffer_out[7], ir_data_buffer_out[30:25], ir_data_buffer_out[11:8], 1'b0};
	u_imm = {ir_data_buffer_out[31:12], 12'h000};
	j_imm = {{12{ir_data_buffer_out[31]}}, ir_data_buffer_out[19:12], ir_data_buffer_out[20], ir_data_buffer_out[30:21], 1'b0};
end


BHT_local BHT_local
(
	.clk,
	.prev_pc(ctrl_de_ex.pc_data),
	.update_pc(ctrl_mem_wb.pc_data),
	.true(br_buffer_out),
	.true_valid,
	.predicted
);
/*
register predict_buffer
(
	.clk,
	.load(load_ex),
	.in(predicted),
	.out(prev_prediction)
);

global2level global2level
(
	.clk,
	.prev_pc(ctrl_de_ex.pc_data),
	.update_pc(ctrl_mem_wb.pc_data),
	.true(br_buffer_out),
	.true_valid,
	.predicted
);
*/
BTB BTB
(
	.clk,
	.prev_pc(ctrl_de_ex.pc_data),
	.update_pc(ctrl_mem_wb.pc_data),
	.true_valid,
	.jump_addr_by_alu(jump_address_buffer_out),
	.target
);

fwd_unit fwd
(
	.wb_dr(ctrl_wb.rd),
	.ex_sr1(ctrl_ex_mem.rs1),
	.ex_sr2(ctrl_ex_mem.rs2),
	.id_sr1(ctrl_de_ex.rs1),
	.id_sr2(ctrl_de_ex.rs2),
	.mem_dr(ctrl_mem_wb.rd),
	.mem_data(d_rdata),
	.wb_data,
	.alu_buffer_out,
	.write_regreg(ctrl_mem_wb.load_regfile),
	.write_dmem(ctrl_wb.load_regfile),
	.dmem_action,
	.mem_sr1(ctrl_mem_wb.rs1),
	.mem_sr2(ctrl_mem_wb.rs2),
	
	.wb_to_ex1,
	.wb_to_ex2,
	.mem_to_ex1,
	.mem_to_ex2,
	.wb_to_mem_rs1,
	.wb_to_mem_rs2,
	.mem_to_ex_fwd1,
	.mem_to_ex_fwd2,
	.wb_to_ex_fwd1,
	.wb_to_ex_fwd2,
	.wb_to_mem_fwd1,
	.wb_to_mem_fwd2
);


/*****************I F****************/
stage_if stage_if
(
	.clk,
	.br_en(br_buffer_out),
	.predicted(ctrl_de_ex.prev_prediction),
	.update_prediction(ctrl_mem_wb.prev_prediction),
	.jump_address(jump_address_buffer_out),
	.predicted_addr(target),
	.saved_addr(ctrl_mem_wb.pc_plus4),
	.flush,
	.pc_out,
	.pc_plus4_out(pc_plus4),
	.opcode(ctrl_mem_wb.opcode),
	.load_if
);
//IF - DE 
register ir_data_buffer
(
	.clk,
	.load(load_de),
	.in(ir_data_buffer_in),
	.out(ir_data_buffer_out)
);
register pc_buffer
(
	.clk,
	.load(load_de),
	.in(pc_buffer_in),
	.out(pc_buffer_out)
);
register pc_plus4_buffer
(
	.clk,
	.load(load_de),
	.in(pc_plus4_buffer_in),
	.out(pc_plus4_buffer_out)
);

/******************D E***************/
stage_de stage_de
(
	.clk,
	.ir_data(ir_data_buffer_out),
	.i_imm,
	.u_imm,
	.b_imm,
	.s_imm,
	.j_imm,
	.rd(ctrl_wb.rd),
	.load_regfile(ctrl_wb.load_regfile),
	.ctrl_de_ex,
	.pc_buffer_out,
	.pc_plus4_buffer_out,
	.wb_data,
	.flush,
	.prev_prediction(predicted)
);

//DE - EX
register #(214) de_ex
(
	.clk,
	.load(load_ex),
	.in(ctrl_de_ex),
	.out(ctrl_ex_mem)
);
register pc_buffer_de_ex
(
	.clk,
	.load(load_ex),
	.in(pc_buffer_out),
	.out(pc_buffer_out_de_ex)
);
register pc_plus4_buffer_de_ex
(
	.clk,
	.load(load_ex),
	.in(pc_plus4_buffer_out),
	.out(pc_plus4_buffer_out_de_ex)
);


/*****************E X****************/
stage_ex stage_ex
(
	.br_en,
	.clk,
	.i_miss_found,
	.ctrl(ctrl_ex_mem),
	.alu_out,
	.pc_buffer_out_de_ex,
	.pc_plus4_buffer_out_de_ex,
	.jump_address,
	.wb_to_ex1,
	.wb_to_ex2,
	.mem_to_ex1,
	.mem_to_ex2,
	.to_ex_fwd,
	.mem_to_ex_fwd1,
	.mem_to_ex_fwd2,
	.wb_to_ex_fwd1,
	.wb_to_ex_fwd2,
	.flush
);
//EX - MEM
register #(214) ex_mem
(
	.clk,
	.load(load_mem),
	.in(ctrl_ex_mem),
	.out(ctrl_mem_wb)
);
register jump_address_buffer
(
	.clk,
	.load(load_mem),
	.in(jump_address),
	.out(jump_address_buffer_out)
);
register #(1) br_buffer
(
	.clk,
	.load(load_mem),
	.in(br_en),
	.out(br_buffer_out)
);

register alu_buffer
(
	.clk,
	.load(load_mem),
	.in(alu_out),
	.out(alu_buffer_out)
);


/****************M E M****************/
stage_mem stage_mem
(
	.clk,
	.ctrl(ctrl_mem_wb),
	.d_read,
	.data_to_wb,
	.d_rdata,
	.address_in(alu_buffer_out),
	.dmem_address(d_addr),
	.dmem_wdata(d_wdata),
	.mem_byte_enable,
	.d_write,
	.wb_to_mem_fwd1,
	.wb_to_mem_fwd2,
	.wb_to_mem_rs1,
	.wb_to_mem_rs2
);
//MEM -WB
register #(214) mem_wb
(
	.clk,
	.load(load_wb),
	.in(ctrl_mem_wb),
	.out(ctrl_wb)
);
register alu_buffer2
(
	.clk,
	.load(load_wb),
	.in(alu_buffer_out),
	.out(alu_buffer_out2)
);
register rdata_buffer
(
	.clk,
	.load(load_wb),
	.in(data_to_wb),
	.out(rdata_buffer_out)
);

/*****************W B****************/
stage_wb stage_wb
(
	.alu_buffer_out2,
	.rdata_buffer_out,
	.ctrl(ctrl_wb),
	.wb_data
);
endmodule: cpu_datapath