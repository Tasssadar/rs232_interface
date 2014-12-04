module uart_tx(CLK, CLK_BAUD, TX_START, TX_DATA, TX_BUSY, TX_PIN);
	input CLK;
	input CLK_BAUD;
	input TX_START;
	input[7:0] TX_DATA;
	output TX_PIN;
	output TX_BUSY;

	reg[3:0] state;
	reg[7:0] tx_buf;
	wire tx_ready;
	assign tx_ready = (state == 0);
	assign TX_BUSY = ~tx_ready;
	
	always @(posedge CLK) begin
		if(tx_ready && TX_START)
			tx_buf <= TX_DATA; // load byte
		else if(state[3] & CLK_BAUD)
			tx_buf <= (tx_buf >> 1); // shift after each bit is sent
		
		/*if(CLK_BAUD && TX_BUSY) begin
			if(state == 4'b0111) // send start and data bits
				state <= state + 4'b1;
			else if(state > 4'b0111) begin
				state <= state + 4'b1;
				
			end else if(state == 4'b0001) // stop bit & default
				state <= 4'b0000;
		end*/

		case(state)
			4'b0000: if(TX_START) state <= 4'b0010; // begin tx
			4'b0010: if(CLK_BAUD) state <= 4'b0111; // start
			4'b0111: if(CLK_BAUD) state <= 4'b1000; // bit 0
			4'b1000: if(CLK_BAUD) state <= 4'b1001; // bit 0
			4'b1001: if(CLK_BAUD) state <= 4'b1010; // bit 1
			4'b1010: if(CLK_BAUD) state <= 4'b1011; // bit 2
			4'b1011: if(CLK_BAUD) state <= 4'b1100; // bit 3
			4'b1100: if(CLK_BAUD) state <= 4'b1101; // bit 4
			4'b1101: if(CLK_BAUD) state <= 4'b1110; // bit 5
			4'b1110: if(CLK_BAUD) state <= 4'b1111; // bit 6
			//4'b1111: if(CLK_BAUD) state <= 4'b0001; // bit 7
			4'b1111: if(CLK_BAUD) state <= 4'b0000; // stop
			default: if(CLK_BAUD) state <= 4'b0000;
		endcase
	end

	//tx is up if     idle and stop           data
	assign TX_PIN = (state <= 4'b10) | (state[3] & tx_buf[0]);
endmodule