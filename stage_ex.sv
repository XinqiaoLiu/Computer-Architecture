import rv32i_types::*;

module stage_ex
(
	input logic clk, i_miss_found, to_ex_fwd,
	input rv32i_control_word ctrl,
	input rv32i_word pc_buffer_out_de_ex, pc_plus4_buffer_out_de_ex, mem_to_ex1, mem_to_ex2, wb_to_ex1, wb_to_ex2,
	input logic wb_to_ex_fwd1, wb_to_ex_fwd2, mem_to_ex_fwd1, mem_to_ex_fwd2, flush,
	output [31:0] jump_address, alu_out,
	output logic br_en
);

rv32i_word cmpmux_out, alumux1_out, alumux2_out, base_addr, rs1_out, rs2_out;
rv32i_control_word ctrl_ex;

always_comb begin
	if(ctrl.opcode == op_br) base_addr = ctrl.pc_data;
	else base_addr = ctrl.pc_plus4;
	
	if(i_miss_found==1  || flush) ctrl_ex = 0;
	else ctrl_ex = ctrl;
	
	rs1_out = ctrl_ex.rs1_out;
	rs2_out = ctrl_ex.rs2_out;
	
	if(wb_to_ex_fwd1 == 1) rs1_out = wb_to_ex1;
	if(wb_to_ex_fwd2 == 1) rs2_out = wb_to_ex2;
	if(mem_to_ex_fwd1 == 1) rs1_out = mem_to_ex1;
	if(mem_to_ex_fwd2 == 1) rs2_out = mem_to_ex2;
end



alu ALU_pc
(
	.aluop(ctrl_ex.aluop),
	.a(base_addr),
	.b(ctrl_ex.imm),
	.f(jump_address)
);

mux2 alumux1
(
	.sel(ctrl_ex.alumux1_sel),
	.a(rs1_out),
	.b(ctrl_ex.pc_data),
	.f(alumux1_out)
);


mux2 alumux2
(
	.sel(ctrl_ex.alumux2_sel),
	.a(rs2_out),
	.b(ctrl_ex.imm),
	.f(alumux2_out)
);
alu ALU_reg
(
	.aluop(ctrl_ex.aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

//CMP
mux2 cmpmux
(
	.sel(ctrl_ex.cmpmux_sel),
	.a(rs2_out),
	.b(ctrl_ex.imm),
	.f(cmpmux_out)
);
CMP CMP
(
	.cmpop(ctrl_ex.cmpop),
	.a(rs1_out),
	.b(cmpmux_out),
	.br_en
);
endmodule: stage_ex