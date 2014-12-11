module clkdiv(CLK, CLK_DIV);
	input CLK;
	output CLK_DIV;
	reg [31:0]counter;
	wire CLK_DIV;

	parameter divider = 32'd1;

	always @(posedge CLK)
	begin
		if(counter == 0)
			counter <= divider;
		else
			counter <= counter - 1;
	end

	assign CLK_DIV = (counter == 1);
endmodule
