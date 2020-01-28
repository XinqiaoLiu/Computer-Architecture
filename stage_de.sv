import rv32i_types::*;

module stage_de
(
	input [31:0] i_imm, s_imm, b_imm, u_imm, j_imm, ir_data, wb_data, pc_buffer_out, pc_plus4_buffer_out, 
	input logic clk, load_regfile, flush, prev_prediction,
	input [4:0] rd,
	output rv32i_control_word ctrl_de_ex
);

rv32i_word imm_mux_out, rs1_out, rs2_out;
rv32i_control_word ctrl_out;
logic[4:0]rs1, rs2;

assign rs1 = ir_data[19:15];
assign rs2 = ir_data[24:20];



always_comb begin
	if(flush == 1) begin
		ctrl_de_ex = 0;
		
	end
	else begin
		ctrl_de_ex = ctrl_out;
		
	end
end


mux8 imm_mux
(
	.sel(ctrl_de_ex.imm_mux_sel),
	.a(i_imm),
	.b(u_imm),
	.c(b_imm),
	.d(s_imm),
	.e(j_imm),
	.g(),
	.h(),
	.i(),
	.f(imm_mux_out)
);

regfile regfile
(
	.clk,
	.load(load_regfile),
	.in(wb_data),
	.src_a(rs1),
	.src_b(rs2),
	.dest(rd),
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);

control_rom control_rom
(		
	//IF
	.pc_data(pc_buffer_out),
	.pc_plus4(pc_plus4_buffer_out),
	
	//DE
	//IR info
	.opcode(rv32i_opcode'(ir_data[6:0])),
	.funct3(ir_data[14:12]),
   .funct7(ir_data[31:25]),
   .rd(ir_data[11:7]),
	.rs1,
	.rs2,
	.imm(imm_mux_out),  //may have problem here
	.rs1_out,
	.rs2_out,
	.prev_prediction,
	
	//output control word
	.ctrl(ctrl_out)
);
endmodule: stage_de
