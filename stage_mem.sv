import rv32i_types::*;

module stage_mem
(
	input rv32i_control_word ctrl, 
	input rv32i_word address_in, wb_to_mem_rs1, wb_to_mem_rs2, d_rdata,
	input logic clk, wb_to_mem_fwd1, wb_to_mem_fwd2,
	output logic d_read, d_write,
	output logic [31:0] dmem_address, dmem_wdata, data_to_wb,
	output logic [3:0] mem_byte_enable
);

always_comb begin
	d_read = ctrl.dmem_read;
	d_write = ctrl.dmem_write;
	data_to_wb = d_rdata;
	
	if(ctrl.opcode == op_load) dmem_address = address_in-4;
	else if(wb_to_mem_fwd2 == 1) dmem_address = wb_to_mem_rs2;
	else dmem_address = address_in;
	
	if(wb_to_mem_fwd2==1) dmem_wdata = wb_to_mem_rs2;
	else dmem_wdata = ctrl.rs2_out;
	
	if(ctrl.opcode == op_store) begin
		case(ctrl.funct3)
			sh: begin
				case(dmem_address[1])
					1'b0: mem_byte_enable = 4'b0011;
					default: mem_byte_enable = 4'b1100;
				endcase
			end
			sb: begin
				case(dmem_address[1:0])
					2'b00: mem_byte_enable = 4'b0001;
					2'b01: mem_byte_enable = 4'b0010;
					2'b10: mem_byte_enable = 4'b0100;
					default: mem_byte_enable = 4'b1000;
				endcase
			end
			default: mem_byte_enable = 4'b1111;
		endcase
	end
	else mem_byte_enable = 4'b1111;
	
	if(ctrl.opcode==op_load)begin
			case(ctrl.funct3)
				lbu: begin
					case(dmem_address[1:0])
					2'b00:	data_to_wb = {24'b0, d_rdata[7:0]};
					2'b01:   data_to_wb = {24'b0, d_rdata[15:8]};
					2'b10: 	data_to_wb = {24'b0, d_rdata[23:16]};
					default: data_to_wb = {24'b0, d_rdata[31:24]};
					endcase
				end
				lb: begin
					case(dmem_address[1:0])
						2'b00:	data_to_wb = {{24{d_rdata[7]}},d_rdata[7:0]};
						2'b01: 	data_to_wb = {{24{d_rdata[15]}},d_rdata[15:8]};
						2'b10: 	data_to_wb = {{24{d_rdata[23]}},d_rdata[23:16]};
						default: data_to_wb = {{24{d_rdata[31]}},d_rdata[31:24]};
					endcase
				end
				lhu: begin
					case(dmem_address[1])
						1'b0: data_to_wb = {16'b0, d_rdata[15:0]};
						default: data_to_wb = {16'b0, d_rdata[31:16]};
					endcase
				end
				lh:  begin 
					case(dmem_address[1])
						1'b0: data_to_wb = {{16{d_rdata[15]}},d_rdata[15:0]};
						default: data_to_wb = {{16{d_rdata[31]}},d_rdata[31:16]};
					endcase
				end
				default:;
			endcase
		end
end


endmodule: stage_mem