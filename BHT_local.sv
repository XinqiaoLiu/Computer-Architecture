module BHT_local
(
	input clk,
	input [31:0] prev_pc, //br pc
	input [31:0] update_pc, //from mem stage pc
	input true, //from mem stage br en
	input true_valid, //from mem stage
	output logic predicted //from branch prediction table
);

logic [1:0] predictor [16];

initial
begin
	for(int i = 0; i < $size(predictor); i++)
	begin
		predictor[i] = 0;
	end
end		

always_ff@(posedge clk)
begin
	predicted = predictor[prev_pc[5:2]][1];
	
	if(true_valid) begin
		case(predictor[update_pc[5:2]])
			00: begin
				case(true)
					0: ;
					1: predictor[update_pc[5:2]] = 2'b01;
				endcase
			end
			01: begin
				case(true)
					0: predictor[update_pc[5:2]] = 0;
					1: predictor[update_pc[5:2]] = 2'b10;
				endcase
			end
			10: begin
				case(true)
					0: predictor[update_pc[5:2]] = 2'b01;
					1: predictor[update_pc[5:2]] = 2'b11;
				endcase
			end
			11: begin
				case(true)
					0: predictor[update_pc[5:2]]  = 2'b10;
					1:;
				endcase
			end
		endcase
	end
end



endmodule: BHT_local