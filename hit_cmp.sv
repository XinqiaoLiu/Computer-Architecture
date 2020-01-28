module hit_cmp 
(
	input a, b,
	output logic f
);

always_comb
begin
	if (a == 1 && b == 1) f = 1;
	else f = 0;
end


endmodule: hit_cmp