module rs232_interface_top(CLOCK_50, UART_TXD, UART_RXD, LEDG,LEDR, KEY, SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
	localparam ST_WAITING = 0;
	localparam ST_SEND    = 1;

	localparam PKTST_START = 0;
	localparam PKTST_CMD   = 1;
	localparam PKTST_LEN   = 2;
	localparam PKTST_DATA  = 3;

	localparam[7:0] CMD_KEY = 0;
	localparam[7:0] CMD_SW = 1;
	localparam[7:0] CMD_LEDG = 2;
	localparam[7:0] CMD_LEDR = 3;
	localparam[7:0] CMD_SET_HEX = 4;

	input CLOCK_50;
	output UART_TXD;
	input UART_RXD;
	output[7:0] LEDG;
	output[17:0] LEDR;
	input [4:0] KEY;
	input [17:0] SW;
	output[6:0] HEX0;
	output[6:0] HEX1;
	output[6:0] HEX2;
	output[6:0] HEX3;
	output[6:0] HEX4;
	output[6:0] HEX5;
	output[6:0] HEX6;
	output[6:0] HEX7;

	reg[7:0] tx_out;
	wire tx_busy;
	reg tx_start;
	wire[7:0] rx_in;
	wire rx_recv;

	reg[1:0] state;
	reg[4:0] last_key;
	reg[17:0] last_sw;
	reg[7:0] ledg_vals;
	reg[17:0] ledr_vals;
	reg[55:0] hex_vals;

	reg[1:0] send_st;
	reg[7:0] send_cmd;
	reg[31:0] send_data;
	reg[7:0] send_len;

	reg[127:0] recv_buf;
	reg[5:0] recv_cnt;
	reg[1:0] recv_state;
	reg[7:0] recv_cur_cmd;
	reg[7:0] recv_cur_len;
	reg[7:0] recv_cur_read;
	reg[127:0] recv_cur_data;

	uart_tx tx(.CLK(CLOCK_50), .TX_START(tx_start), .TX_DATA(tx_out), .TX_BUSY(tx_busy), .TX_PIN(UART_TXD));
	uart_rx rx(.CLK(CLOCK_50), .RX_DATA(rx_in), .RX_RECV(rx_recv), .RX_PIN(UART_RXD));

	hex_num h0(HEX0, hex_vals[6:0]);
	hex_num h1(HEX1, hex_vals[13:7]);
	hex_num h2(HEX2, hex_vals[20:14]);
	hex_num h3(HEX3, hex_vals[27:21]);
	hex_num h4(HEX4, hex_vals[34:28]);
	hex_num h5(HEX5, hex_vals[41:35]);
	hex_num h6(HEX6, hex_vals[48:42]);
	hex_num h7(HEX7, hex_vals[55:49]);

	assign LEDG = ledg_vals;
	assign LEDR = ledr_vals;

	// start transmitting a packet - limited to 32bits of data
	task start_send;
	input[7:0] cmd, len;
	input[31:0] data;
	begin
		send_len <= len;
		send_data <= data;
		send_cmd <= cmd;
		state <= ST_SEND;
	end
	endtask

	// Handle incoming packet - limited to 128bits of data
	task handle_pkt;
	input[7:0] cmd, len;
	input[127:0] data;
	begin
		case(cmd)
		CMD_LEDG: ledg_vals <= data[7:0];
		CMD_LEDR: ledr_vals <= data[17:0];
		CMD_SET_HEX:
			case(data[15:8])
				0: hex_vals[6:0]   <= data[7:0];
				1: hex_vals[13:7]  <= data[7:0];
				2: hex_vals[20:14] <= data[7:0];
				3: hex_vals[27:21] <= data[7:0];
				4: hex_vals[34:28] <= data[7:0];
				5: hex_vals[41:35] <= data[7:0];
				6: hex_vals[48:42] <= data[7:0];
				7: hex_vals[55:49] <= data[7:0];
			endcase
		endcase
	end
	endtask

	// Handle incoming byte, construct the packet
	task handle_recv_byte;
	begin
		case(recv_state)
		PKTST_CMD: recv_cur_cmd <= recv_buf[7:0];
		PKTST_LEN: recv_cur_len <= recv_buf[7:0];
		PKTST_DATA: begin
				recv_cur_data = (recv_cur_data << 8) | recv_buf[7:0];
				recv_cur_read <= recv_cur_read + 1;
			end
		endcase

		if(recv_state != PKTST_DATA && (recv_state != PKTST_START || recv_buf[7:0] == 8'hff))
			recv_state <= recv_state + 1;

		if(recv_state == PKTST_DATA && recv_cur_read+1 >= recv_cur_len) begin
			handle_pkt(recv_cur_cmd, recv_cur_len, recv_cur_data);
			recv_state <= PKTST_START;
			recv_cur_read <= 0;
			recv_cur_data <= 0;
		end

		recv_buf <= (recv_buf >> 8);
		recv_cnt <= recv_cnt - 1;
	end
	endtask

	// Main "event loop":
	//   * handle TX start/end
	//   * handle KEY and SW events and sent a packet when they change
	//   * handle incoming byte -> put into a buffer and call handle_recv_byte
	//   * construct & send output packets initiated by start_send task
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
				handle_recv_byte();             // handle incoming bytes
			end else if(last_key != KEY) begin // handle KEY events
				start_send(CMD_KEY, 1, ~KEY);
				last_key <= KEY;
			end else if(last_sw != SW) begin   // handle SW events
				start_send(CMD_SW, 3, SW);
				last_sw <= SW;
			end
		ST_SEND:
			if(!tx_busy && !tx_start) begin
				case(send_st)
				PKTST_START: tx_out <= 8'hff;
				PKTST_CMD: tx_out <= send_cmd;
				PKTST_LEN: tx_out <= send_len;
				PKTST_DATA:
				begin
					tx_out <= send_data[7:0];
					send_data <= send_data >> 8;
					send_len = send_len - 1;
				end
				endcase

				tx_start <= 1;

				if(send_st >= PKTST_LEN && send_len == 0) begin
					send_st <= PKTST_START;
					state <= ST_WAITING;
				end else if(send_st != PKTST_DATA)
					send_st <= send_st + 1;
			end
		default:
			state <= ST_WAITING;
		endcase
	end
endmodule
