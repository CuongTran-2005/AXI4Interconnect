`timescale 1ns / 1ps

module ax_decoder #(
    // Data and ID Widths
    parameter ADDR_WIDTH     		= 32,
    parameter SLAVE_ID_WIDTH 		= 2,   // 2 bits supports up to 4 slaves
	parameter TRANSACTION_ID_WIDTH 	= 2,
	parameter QOS_WIDTH				= 4
    
)(
    input  	wire [ADDR_WIDTH-1:0]     			AxADDR_i,
	input 	wire [TRANSACTION_ID_WIDTH-1:0]		AxID_i,
	input 	wire [QOS_WIDTH-1:0] 				AxQOS_i,
    input  	wire                      			Ax_handshake_i, 
    output 	wire  [SLAVE_ID_WIDTH-1:0] 			slave_id_o,
    output 	wire                      			fifo_write_o,
	output 	wire [TRANSACTION_ID_WIDTH-1:0]		transaction_id_o,
	output 	wire [QOS_WIDTH-1:0]				qos_o
	
);

    // -------------------------------------------------------------------------
    // Combinational Address Decoding Logic
    // -------------------------------------------------------------------------
    assign slave_id_o = AxADDR_i[31-:SLAVE_ID_WIDTH];
	assign transaction_id_o = AxID_i;
	assign qos_o = AxQOS_i;

    // -------------------------------------------------------------------------
    // FIFO Write Request Logic
    // -------------------------------------------------------------------------
    // As requested, the FIFO write signal is active when the Ax_handshake is active.
    // In an AXI interconnect, this typically means AWVALID && AWREADY == 1.
    assign fifo_write_o = Ax_handshake_i;

endmodule
