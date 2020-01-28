module mux4 #(parameter width = 32)
(
input [1:0]sel,
input [width-1:0] a, b, c, d,
output logic [width-1:0] f
);

always_comb
begin
if (sel[1] == 0)
	if (sel[0] == 0)
		f = a;
	else f = b;
else
	if (sel[0] == 0)
		f = c;
	else f = d;
end

endmodule: mux4