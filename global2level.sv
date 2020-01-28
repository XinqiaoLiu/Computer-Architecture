module global2level
(
	input clk,
	input [31:0] prev_pc, //br pc
	input [31:0] update_pc, //from mem stage pc
	input true, //from mem stage br en
	input true_valid, //from mem stage
	output logic predicted //from branch prediction table
);

logic predictor [32];
logic [3:0] bhr_arr[8];
logic [4:0] index;
initial
begin
	for(int i = 0; i < $size(predictor); i++)
	begin
		predictor[i] = 1'b0;
	end
	for(int i = 0; i < $size(bhr_arr); i++)
	begin
		bhr_arr[i] = 4'b0;
	end
end
		
always_comb begin
	index = {prev_pc[5:4],bhr_arr[prev_pc[5:3]]};
end

always_ff@(posedge clk)
begin
	predicted = predictor[index];
	if(true_valid) begin
		predictor[index] = true;
	
	//update pht
/*	
		case(predictor[{prev_pc[5:4],bhr_arr[prev_pc[5:3]]}])
			0: begin
				case(true)
					0: ;
					1: predictor[{prev_pc[5:4],bhr_arr[prev_pc[5:3]]}] = 1;
				endcase
			end
			1: begin
				case(true)
					0: predictor[{prev_pc[5:4],bhr_arr[prev_pc[5:3]]}] = 0;
					1: ;
				endcase
			end
			
		endcase
*/
		//update bhr
		bhr_arr[update_pc[5:3]][3:1] = bhr_arr[update_pc[5:3]][2:0];
		bhr_arr[update_pc[5:3]] = {bhr_arr[update_pc[5:3]][3:1],true};
		
	end
end



endmodule: global2level