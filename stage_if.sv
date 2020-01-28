import rv32i_types::*;

module stage_if
(
	input clk, br_en , load_if, predicted, update_prediction, flush,
	input logic [31:0] jump_address, predicted_addr, saved_addr,
	input rv32i_opcode opcode,
	output logic [31:0] pc_out, pc_plus4_out
);

rv32i_word pcmux_out, jump_address_0;
logic [1:0] pcmux_sel;

always_comb
begin
	pc_plus4_out = pc_out + 4;
	jump_address_0 = {jump_address[31:1], 1'b0};
	pcmux_sel = 0;
	
	if(opcode == op_jal) pcmux_sel = 2'b01;
	if(opcode == op_jalr) pcmux_sel = 2'b10;
	
	if(predicted==1) begin
		pcmux_sel = 2'b11;
	end
	
	if(flush == 1) begin
		if(br_en == 1 && opcode == op_br) begin
			pcmux_sel = 2'b01;
		end
		else begin
			pc_plus4_out = saved_addr;
			pcmux_sel = 0;
		end
	end
end

/*
 * PC
 */
mux4 pcmux
(
    .sel(pcmux_sel),
    .a(pc_plus4_out),
    .b(jump_address),
	 .c(jump_address_0),
	 .d(predicted_addr),
    .f(pcmux_out)
);

pc_register pc
(
    .clk,
    .load(load_if),
    .in(pcmux_out),
    .out(pc_out)
);


endmodule: stage_if