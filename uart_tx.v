module uart_tx(CLK, TX_START, TX_DATA, TX_BUSY, TX_PIN);
	input CLK;
	input TX_START;
	input[7:0] TX_DATA;
	output TX_PIN;
	output TX_BUSY;

	reg[3:0] state;
	reg[7:0] tx_buf;
	wire tx_ready;
	assign tx_ready = (state == 0);
	assign TX_BUSY = ~tx_ready;
	wire uart_clk;

	clkdiv uart_div(.CLK(CLK), .CLK_DIV(uart_clk));
	defparam uart_div.divider = 32'd434; // 50MHz/434 == 115207,373

	always @(posedge CLK) begin
		if(tx_ready && TX_START) begin
			tx_buf <= TX_DATA; // load byte
			state <= 4'b0110;
		end else if(uart_clk && state >= 4'b0110) begin
			if(state[3] & uart_clk)
				tx_buf <= (tx_buf >> 1); // shift after each bit is sent
			state <= state + 1;
		end

		/*case(state)
			4'b0000: if(TX_START) state <= 4'b0010; // begin tx
			4'b0010: if(CLK_BAUD) state <= 4'b0111; // start
			4'b0111: if(CLK_BAUD) state <= 4'b1000; // bit 0
			4'b1000: if(CLK_BAUD) state <= 4'b1001; // bit 1
			4'b1001: if(CLK_BAUD) state <= 4'b1010; // bit 2
			4'b1010: if(CLK_BAUD) state <= 4'b1011; // bit 3
			4'b1011: if(CLK_BAUD) state <= 4'b1100; // bit 4
			4'b1100: if(CLK_BAUD) state <= 4'b1101; // bit 5
			4'b1101: if(CLK_BAUD) state <= 4'b1110; // bit 6
			4'b1110: if(CLK_BAUD) state <= 4'b1111; // bit 7
			4'b1111: if(CLK_BAUD) state <= 4'b0000; // stop
			default: if(CLK_BAUD) state <= 4'b0000;
		endcase */
	end

	//tx is up if     idle         or        stop       or        data
	assign TX_PIN = (state <= 4'b10 | state == 4'b0110) | (state[3] & tx_buf[0]);
endmodule
