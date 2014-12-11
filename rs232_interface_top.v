module rs232_interface_top(CLOCK_50, UART_TXD, UART_RXD, LEDG, KEY, SW);
	localparam ST_WAITING = 0;
	localparam ST_SEND    = 1;

	localparam STSEND_START = 0;
	localparam STSEND_CMD   = 1;
	localparam STSEND_LEN   = 2;
	localparam STSEND_DATA  = 3;

	localparam[7:0] CMD_KEY = 0;
	localparam[7:0] CMD_SW = 1;

	input CLOCK_50;
	output UART_TXD;
	input UART_RXD;
	output[7:0] LEDG;
	input [4:0] KEY;
	input [17:0] SW;
	reg[7:0] tx_out;
	wire tx_busy;
	reg tx_start;
	wire[7:0] rx_in;
	wire rx_recv;

	reg[7:0] state;
	reg[4:0] last_key;
	reg[17:0] last_sw;

	reg[1:0] send_st;
	reg[7:0] send_cmd;
	reg[32:0] send_data;
	reg[7:0] send_len;
	
	reg[128:0] recv_buf;
	reg[5:0] recv_cnt;

	uart u(.CLOCK_50(CLOCK_50), .UART_TXD(UART_TXD), .UART_RXD(UART_RXD), .TX_DATA(tx_out), .TX_BUSY(tx_busy), .TX_START(tx_start), .RX_DATA(rx_in), .RX_RECV(rx_recv));
	
	assign LEDG = state;

	always @(posedge CLOCK_50)
	begin
		if(!tx_busy && tx_start)
			tx_start <= 0;
			
		if(rx_recv) begin
			recv_buf <= (recv_buf << 8) | rx_in;
			recv_cnt <= recv_cnt + 1;
		end

		case(state)
		ST_WAITING:
			if(recv_cnt > 0) begin
				send_len <= 1;
				send_data <= recv_buf[7:0];
				send_cmd <= 4;
				state <= ST_SEND;
				recv_buf <= (recv_buf >> 8);
				recv_cnt <= recv_cnt - 1;
			end else if(last_key != KEY) begin
			   send_len <= 1;
				send_data <= ~KEY;
				send_cmd <= CMD_KEY;
				last_key <= KEY;
				state <= ST_SEND;
			end else if(last_sw != SW) begin
				send_len <= 3;
				send_data <= SW;
				send_cmd <= CMD_SW;
				last_sw <= SW;
				state <= ST_SEND;
			end
		ST_SEND:
			if(!tx_busy && !tx_start) begin
				case(send_st)
				STSEND_START: tx_out <= 8'hff;
				STSEND_CMD: tx_out <= send_cmd;
				STSEND_LEN: tx_out <= send_len;
				STSEND_DATA:
				begin
					tx_out <= send_data[7:0];
					send_data <= send_data >> 8;
					send_len = send_len - 1;
				end
				endcase

				tx_start <= 1;

				if(send_st >= STSEND_LEN && send_len == 0) begin
					send_st <= 0;
					state <= ST_WAITING;
				end else if(send_st != STSEND_DATA)
					send_st <= send_st + 1;
			end
		default:
			state <= ST_WAITING;
		endcase
	end
endmodule
