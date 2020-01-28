import rv32i_types::*;

module control_rom
(
	input rv32i_opcode opcode,
	input [2:0] funct3,
   input [6:0] funct7,
   input [31:0] imm,
	input [31:0] rs1_out, rs2_out, pc_data, pc_plus4,
   input [4:0] rd, rs1, rs2,
	input logic prev_prediction,
	
	output rv32i_control_word ctrl
);

always_comb
begin
	/* Default assignments */
	//IR
	ctrl.opcode = opcode;
	ctrl.load_regfile = 0;
	ctrl.funct3 = funct3;
	ctrl.funct7 = funct7;
	ctrl.imm = imm;
	if(opcode == op_store || opcode == op_br) ctrl.rd = 0;
	else ctrl.rd = rd;
	//IF
	ctrl.pc_data = pc_data;
	ctrl.pc_plus4 = pc_plus4;
	
	//DE
	ctrl.load_regfile = 0;
	ctrl.rs1 = rs1;
	ctrl.rs2 = rs2;
	ctrl.rs1_out = rs1_out;
	ctrl.rs2_out = rs2_out;
	//ctrl.regfilemux_sel = 0;
	ctrl.prev_prediction = prev_prediction;
	
	//EX
	//ctrl.ex_done = 0;
	ctrl.imm_mux_sel = 0;
	ctrl.cmpop = branch_funct3_t '(funct3);;
	ctrl.cmpmux_sel = 0;
	ctrl.aluop = alu_ops'(funct3);
	ctrl.alumux1_sel = 0;
	ctrl.alumux2_sel = 0;
	
	//MEM
	ctrl.dmem_read = 0;
	ctrl.dmem_write = 0;
	
	//WB
	ctrl.wb_data_mux_sel = 0;
	
	/* Assign control signals based on opcode */
	case(opcode)
		op_auipc: begin
			ctrl.aluop = alu_add;
			ctrl.load_regfile = 1;
			ctrl.imm_mux_sel = 1;
			ctrl.alumux1_sel = 1;
		end
		
	   op_lui: begin
			ctrl.load_regfile = 1;
			ctrl.imm_mux_sel = 2;
		end
		
		op_load: begin
			ctrl.dmem_read = 1;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 1;
			ctrl.load_regfile = 1;
			ctrl.aluop = alu_add;
			ctrl.wb_data_mux_sel = 1;
		end
		
		op_store: begin
			ctrl.dmem_write = 1;
			ctrl.imm_mux_sel = 3;
			ctrl.alumux1_sel = 0;
			ctrl.alumux2_sel = 1;
			ctrl.aluop = alu_add;
		end
		
		op_jal: begin
			ctrl.pcmux_sel = 1;  
			ctrl.imm_mux_sel = 3'b100; //j_imm
			ctrl.aluop = alu_add;
			ctrl.load_regfile = 1;
			//ctrl.regfilemux_sel = 4; //pc+4
		end
		
		op_jalr: begin
			ctrl.pcmux_sel = 2;  //least sig bit to 0
			ctrl.imm_mux_sel = 3'b000; //i-type
			ctrl.aluop = alu_add;
			ctrl.load_regfile = 1;
			//ctrl.regfilemux_sel = 4; //pc+4
		end
		
		op_imm: begin
			ctrl.load_regfile = 1;
			ctrl.aluop = alu_ops'(funct3);
			ctrl.alumux2_sel = 1;
			
			case(funct3)
				slt: begin
					//ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 1;
					ctrl.cmpop = blt;
				end
				sltu: begin
					ctrl.cmpop = bltu;
					//ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 1;
				end
				sr: begin
					if(funct7 == 7'b0100000) ctrl.aluop = alu_sra;
					else ctrl.aluop = alu_srl;
				end
				default: ctrl.aluop = alu_ops'(funct3);
			endcase
		end
		
		op_br: begin
			ctrl.imm_mux_sel = 2;
			ctrl.aluop = alu_add;
		end
		
		op_reg: begin
			ctrl.load_regfile = 1;
			
			case(funct3)
				add: begin 	//add/sub check bit 30
					if(funct7[5]==1) ctrl.aluop = alu_sub;
					//ctrl.regfilemux_sel = 0;
				end
				slt: begin
					//ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 0; //rs2_out
					ctrl.cmpop = blt;
				end
				sltu: begin
					ctrl.cmpop = bltu;
					//ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 0; //rs2_out
				end
				sr: begin
					//ctrl.regfilemux_sel = 0;
					if(funct7 == 7'b0100000) ctrl.aluop = alu_sra;
					else ctrl.aluop = alu_srl;
				end
				default: ctrl.aluop = alu_ops'(funct3);
			endcase
		end
		default: begin
			ctrl = 0; /* Unknown opcode, set control word to zero */
		end
	endcase
end
endmodule : control_rom