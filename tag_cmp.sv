module tag_cmp #(parameter width = 24)
(
input [width-1:0] a, b, c, 
output logic f,
output logic g
);


always_comb
begin
	if(a==b) begin
		f = 1;
		g = 0;
	end
	else if (a==c) begin
		f = 1;
		g = 1;
	end
	else begin
		f = 0;
		g = 0;
	end
end

endmodule: tag_cmp