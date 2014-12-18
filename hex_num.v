module hex_num(HPIN, VAL);
	/* Segment bits:
		  * H0 *
		 V0    V1
		  * H1 *
		 V2    V3
		  * H2 *
	*/
	localparam[6:0] H0 = 7'b0000001;
	localparam[6:0] H1 = 7'b1000000;
	localparam[6:0] H2 = 7'b0001000;
	localparam[6:0] V0 = 7'b0100000;
	localparam[6:0] V1 = 7'b0000010;
	localparam[6:0] V2 = 7'b0010000;
	localparam[6:0] V3 = 7'b0000100;

	output[6:0] HPIN;
	input[3:0] VAL;
	reg[6:0] disp_val;

	assign HPIN = ~disp_val;

	always @(VAL)
	begin
		case(VAL)
			4'd0: disp_val <= (H0 | H2 | V0 | V1 | V2 | V3);
			4'd1: disp_val <= (V1 | V3);
			4'd2: disp_val <= (H0 | H1 | H2 | V1 | V2);
			4'd3: disp_val <= (H0 | H1 | H2 | V1 | V3);
			4'd4: disp_val <= (H1 | V0 | V1 | V3);
			4'd5: disp_val <= (H0 | H1 | H2 | V0 | V3);
			4'd6: disp_val <= (H1 | H2 | V0 | V2 | V3);
			4'd7: disp_val <= (H0 | V1 | V3);
			4'd8: disp_val <= (H0 | H1 | H2 | V0 | V1 | V2 | V3);
			4'd9: disp_val <= (H0 | H1 | H2 | V0 | V1 | V3);
			4'd10: disp_val <= (H1); // special value - minus
			default: disp_val <= 0;
		endcase
	end
endmodule
