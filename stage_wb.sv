import rv32i_types::*;

module stage_wb
(
	input rv32i_control_word ctrl,
	input [31:0] rdata_buffer_out, alu_buffer_out2,
	output logic [31:0] wb_data
);

always_comb
begin
	case(ctrl.opcode)
		op_load: begin
			case(ctrl.funct3)
				lbu: begin
					case(alu_buffer_out2[1:0])
					2'b00:	wb_data = {24'b0, rdata_buffer_out[7:0]};
					2'b01:   wb_data = {24'b0, rdata_buffer_out[15:8]};
					2'b10: 	wb_data = {24'b0, rdata_buffer_out[23:16]};
					default: wb_data = {24'b0, rdata_buffer_out[31:24]};
					endcase
				end
				lb: begin
					case(alu_buffer_out2[1:0])
						2'b00:	wb_data = {{24{rdata_buffer_out[7]}},rdata_buffer_out[7:0]};
						2'b01: 	wb_data = {{24{rdata_buffer_out[15]}},rdata_buffer_out[15:8]};
						2'b10: 	wb_data = {{24{rdata_buffer_out[23]}},rdata_buffer_out[23:16]};
						default: wb_data = {{24{rdata_buffer_out[31]}},rdata_buffer_out[31:24]};
					endcase
				end
				lhu: begin
					case(alu_buffer_out2[1])
						1'b0: wb_data = {16'b0, rdata_buffer_out[15:0]};
						default: wb_data = {16'b0, rdata_buffer_out[31:16]};
					endcase
				end
				lh:  begin 
					case(alu_buffer_out2[1])
						1'b0: wb_data = {{16{rdata_buffer_out[15]}},rdata_buffer_out[15:0]};
						default: wb_data = {{16{rdata_buffer_out[31]}},rdata_buffer_out[31:16]};
					endcase
				end
				default: wb_data = rdata_buffer_out; //lw
			endcase
		end
		default: wb_data = alu_buffer_out2; //reg reg ops
	endcase
end
/*
mux2 rdata_mux
(
	.sel(ctrl.wb_data_mux_sel),
	.a(alu_buffer_out2),
	.b(rdata_buffer_out),
	.f(wb_data)
);
*/
endmodule: stage_wb