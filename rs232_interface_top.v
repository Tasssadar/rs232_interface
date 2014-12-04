module rs232_interface_top(CLOCK_50, UART_TXD, UART_RXD, LEDG, KEY);
	input CLOCK_50;
	output UART_TXD;
	input UART_RXD;
	output[7:0] LEDG;
	input [4:0] KEY;
	reg[7:0] tx_out;
	wire tx_busy;
	reg tx_start;
	reg[2:0] send;
	reg add;

	uart u(.CLOCK_50(CLOCK_50), .UART_TXD(UART_TXD), .UART_RXD(UART_RXD), .LEDG(LEDG), .TX_DATA(tx_out), .TX_BUSY(tx_busy), .TX_START(tx_start));
	
	always @(posedge CLOCK_50)
	begin
		if(send == 1 && !tx_busy && !tx_start)
		begin
			if(add)
			begin
				tx_start <= 1;
				tx_out <= tx_out + 1;
				if(tx_out == 254)
					add <= 0;
			end
			else
			begin
				tx_start <= 1;
				tx_out <= tx_out - 1;
				if(tx_out == 1)
					add <= 1;
			end
		end
		else
		begin
			tx_start <= 0;	

			if(send == 0 && KEY[0] == 0)
			begin
				tx_out <= 7'h0;
				add <= 1;
				send <= 2;
			end
			else if(send == 2 && KEY[0] == 1)
				send <= 1;
		end
	end
endmodule