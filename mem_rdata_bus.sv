module mem_rdata_bus
(
	input logic [2:0] index,
	input logic [255:0] data_in,
	output logic [31:0] data_out
);

always_comb begin
	data_out = data_in[32*index+:32];
end
endmodule: mem_rdata_bus