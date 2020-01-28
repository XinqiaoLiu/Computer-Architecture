module L2_tag_cmp #(parameter width = 24)
(
input [width-1:0] a, b, c, d, e,
output logic f,
output logic [1:0] g
);


always_comb
begin
	if (a==e) begin
		f = 1;
		g = 3;
	end
	else if (a==c) begin
		f = 1;
		g = 1;
	end
	else if (a==b) begin
		f = 1;
		g = 0;
	end
	else if (a==d) begin
		f = 1;
		g = 2;
	end
	else begin
		f = 0;
		g = 0;
	end
end

endmodule: L2_tag_cmp