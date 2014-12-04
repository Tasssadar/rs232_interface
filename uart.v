module uart(CLOCK_50, UART_TXD, UART_RXD, LEDG, TX_DATA, TX_BUSY, TX_START);
	input CLOCK_50;
	output UART_TXD;
	input UART_RXD;
	output TX_BUSY;
	input[7:0] TX_DATA;
	input TX_START;
	output[7:0] LEDG;
	wire uart_clk;
	wire uart_div_rst;
	wire TX_START;
	wire TX_BUSY;
	reg[7:0] val = 0;

	assign LEDG = val;
	
	clkdiv uart_div(.CLK(CLOCK_50), .CLK_DIV(uart_clk));
	defparam uart_div.divider = 32'd434; // 50MHz/434 == 115207,373
	//defparam uart_div.divider = 32'd25_000_000; // debug 1/2 s
	
	uart_tx tx(.CLK(CLOCK_50), .CLK_BAUD(uart_clk), .TX_START(TX_START), .TX_DATA(TX_DATA), .TX_BUSY(TX_BUSY), .TX_PIN(UART_TXD));

	always @(posedge TX_BUSY)
	begin
		val <= val + 1;
	end
	
	
endmodule