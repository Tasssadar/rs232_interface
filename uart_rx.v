// This module is oversampling the RX pin at 16*line speed,
// when it detects change, it tries to filter it over 4 
// oversample ticks 
module uart_rx(CLK, CLK_BAUD, RX_DATA, RX_RECV, RX_PIN);
	localparam OVERSAMPLING = 16;
	localparam OVERSAMPLING_LOG = 4; //log2(OVERSAMPLING)

	localparam ST_WAITING = 0;

	input CLK;
	input CLK_BAUD;
	input RX_PIN;
	output reg[7:0] RX_DATA;
	output reg RX_RECV;
	wire clk_oversample;
	reg[4:0] state;
	reg[2:0] filter;
	reg rx_filtered;
	reg[OVERSAMPLING_LOG-1:0] oversample_cnt = 0;
	wire sample = clk_oversample && (oversample_cnt == OVERSAMPLING-1);
	
	clkdiv oversample_div(.CLK(CLK), .CLK_DIV(clk_oversample));
	defparam oversample_div.divider = 32'd27; // 50MHz/27 = 16*115740
	
	always @(posedge CLK)
	begin
		if(clk_oversample) begin
			// filter out short changes
			if(RX_PIN && filter != 3'b111)
				filter <= filter + 3'b1;
			else if(!RX_PIN && filter != 3'b00)
				filter <= filter - 3'b1;
			
			if(filter == 3'b111)
				rx_filtered <= 1;
			else if(filter == 3'b000)
				rx_filtered <= 0;
				
			// oversample divider
			oversample_cnt <= state == 0 ? 0 : oversample_cnt + 1;
		end
	end
	
	/*
	5'b01000 - data 0
	5'b01001 - data 1
	5'b01010 - data 2
	5'b01011 - data 3
	5'b01100 - data 4
	5'b01101 - data 5
	5'b01110 - data 6
	5'b01111 - data 7
	5'b10000 - stop bit
	*/
	always @(posedge CLK)
	begin
		if(state == 5'b00000 && rx_filtered == 0)
			state <= 5'b01000;
		else if(sample) begin
			if(state < 5'b10000)
				state <= state + 1;
			else
				state <= 5'b00000;
				
			if(state[3])
				RX_DATA <= { rx_filtered, RX_DATA[7:1]};
		end
		RX_RECV <= (sample && state == 5'b10000 && rx_filtered);
	end
endmodule
