module BTB_tag_cmp #(parameter width = 24)
(
input [width-1:0] a, b, c, d, e,
output logic [1:0] f,
output logic g

);


always_comb
begin
	if(a==b) begin
		f = 2'b00;
		g = 1;
	end
	else if (a==c) begin
		f = 2'b01;
		g = 1;
	end
	else if(a==d) begin
		f = 2'b10;
		g = 1;
	end
	else if(a==e) begin
		f = 2'b11;
		g = 1;
	end
	else begin
		f = 2'b00;
		g = 0;
end

endmodule: BTB_tag_cmp