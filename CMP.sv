/*cmp*/
import rv32i_types::*;
module CMP
(
input branch_funct3_t cmpop,
input [31:0] a, b,
output logic br_en
);
always_comb
begin
	case(cmpop)
		beq:begin
			if(a==b)
				br_en=1;
			else
				br_en=0;
		end
		
		bne:begin
			if(a!=b)
				br_en=1;
			else
				br_en=0;
		end
		
		blt:begin
			if($signed(a)< $signed(b))
				br_en=1;
			else
				br_en=0;
		end
		
		bltu:begin
			if(a<b)
				br_en=1;
			else
				br_en=0;
		end
		
		bge:begin
			if($signed(a)>=$signed(b))
				br_en=1;
			else
				br_en=0;
		end
		
		bgeu:begin
			if(a>=b)
				br_en=1;
			else
				br_en=0;
		end
		endcase
end
endmodule : CMP