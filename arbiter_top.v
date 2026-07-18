`timescale 1ns / 1ps

module arbiter_top #(
	parameter SLAVE_TRANSACTION_ID_WIDTH 	= 4,
	parameter MASTER_NUM 					= 4,
	parameter MASTER_ID_WIDTH				= $clog2(MASTER_NUM),
	parameter QOS_WIDTH 					= 4,
	parameter MAX_OUTSTANDING_TRANSACTION	= 8
)(
    input  wire                    	clk,
    input  wire                    	rst_n,
	
	/*=====================DISPATCH SIDE=====================*/
	/* input */
	input [MASTER_NUM-1:0]					AW_fifo_empty_i,
	input [QOS_WIDTH*MASTER_NUM-1:0]		AW_qos_i,
	input [MASTER_NUM-1:0]					W_fifo_empty_i,
	input [MASTER_NUM-1:0]					B_fifo_full_i,
	input [MASTER_NUM-1:0]					AR_fifo_empty_i,
	input [MASTER_NUM-1:0]					R_fifo_full_i,
	input [QOS_WIDTH*MASTER_NUM-1:0] 		AR_qos_i,
	
	
	/* output */
	output [MASTER_NUM-1:0]					AW_fifo_read_o,
	output [MASTER_NUM-1:0] 				W_fifo_read_o,
	output [MASTER_NUM-1:0]					B_fifo_write_o,
	output [MASTER_NUM-1:0]					AR_fifo_read_o,
	output [MASTER_NUM-1:0]					R_fifo_write_o,
	
	output [MASTER_ID_WIDTH-1:0]			AW_master_id_o,
	output [MASTER_ID_WIDTH-1:0] 			W_master_id_o,
	output [MASTER_ID_WIDTH-1:0]			B_master_id_o,
	output [MASTER_ID_WIDTH-1:0]			AR_master_id_o,
	output [MASTER_ID_WIDTH-1:0]			R_master_id_o,
	
	
	/*=====================SLAVE SIDE========================*/
	/* input */
	input 									AW_ready_i,
	input 									AR_ready_i,
	input 									W_ready_i,
	input 									W_last_i,
	input 									B_valid_i,
	input 									R_valid_i,
	input [SLAVE_TRANSACTION_ID_WIDTH-1:0] 	B_ID_i,
	input [SLAVE_TRANSACTION_ID_WIDTH-1:0] 	R_ID_i,
	
	/* output */
	output 									AW_valid_o,
	output 									AR_valid_o,
	output									W_valid_o,
	output									B_ready_o,
	output									R_ready_o
);

	wire aw_handshake;
	wire w_handshake;
	wire b_handshake;
	wire ar_handshake;
	wire r_handshake;
	
	assign aw_handshake = AW_valid_o & AW_ready_i;
	assign w_handshake = W_valid_o & W_ready_i;
	assign b_handshake = B_valid_i & B_ready_o;
	assign ar_handshake = AR_valid_o & AR_ready_i;
	assign r_handshake = R_valid_i & R_ready_o;

	// aw qos mask
	wire [MASTER_NUM-1:0] aw_masked_request;
	qos_request_mask #(
	.REQUESTER_NUM(MASTER_NUM),
	.QOS_WIDTH(QOS_WIDTH)
	) aw_qos_request_mask (
	.request(~AW_fifo_empty_i),
	.qos(AW_qos_i),
	.masked_request(aw_masked_request),
	.highest_qos()
	);
	
	// aw round-robin arbiter
	wire [2**MASTER_ID_WIDTH-1:0] aw_granted_one_hot;
	round_robin_arbiter #(
	.REQUESTER_NUM(MASTER_NUM),
	.MODE(1)
	) aw_round_robin_arbiter( 
	.clk(clk),
	.rst_n(rst_n),
	.request(aw_masked_request),
	.enable(aw_handshake),
	.grant(aw_granted_one_hot),
	.next_grant(),
	.slv_req()
	);
	
	// aw binary encoder
	wire [MASTER_ID_WIDTH-1:0] aw_master_id;
	binary_encoder #(.INPUT_WIDTH(2**MASTER_ID_WIDTH)) 
	aw_binary_encoder(
	.one_hot(aw_granted_one_hot),
	.binary(aw_master_id),
	.valid()
	);
	assign AW_master_id_o = aw_master_id;

	// w master id fifo
	wire 						w_master_id_fifo_rd_en;
	wire 						w_master_id_fifo_wr_en;
	wire [MASTER_ID_WIDTH-1:0] 	w_master_id_fifo_data;
	wire [MASTER_ID_WIDTH-1:0]	w_master_id_fifo_q;
	wire 						w_master_id_fifo_full;
	wire [MASTER_ID_WIDTH-1:0] 	w_master_id;
	sc_fifo_lookahead #(.DATA_WIDTH(MASTER_ID_WIDTH), 
	.ADDR_WIDTH($clog2(MAX_OUTSTANDING_TRANSACTION)))
	w_master_id_fifo(
	.clk(clk),
	.rst_n(rst_n),
	.wr_en(w_master_id_fifo_wr_en),
	.rd_en(w_master_id_fifo_rd_en),
	.data(w_master_id_fifo_data),
	.q(w_master_id_fifo_q),
	.full(w_master_id_fifo_full),
	.empty()
	);
	assign w_master_id_fifo_data = aw_master_id;
	assign w_master_id_fifo_wr_en = aw_handshake;
	assign w_master_id = w_master_id_fifo_q;
	assign W_master_id_o = w_master_id_fifo_q;
	assign AW_valid_o = |aw_masked_request & ~w_master_id_fifo_full;
	
	// aw read demux
	wire 					aw_fifo_read;
	wire [MASTER_NUM-1:0] 	aw_fifo_read_demux_out;
	assign aw_fifo_read = aw_handshake;
	demux #(.SEL_WIDTH(MASTER_ID_WIDTH), .DATA_WIDTH(1))
	aw_fifo_read_demux(
	.data_in(aw_fifo_read),
	.sel(aw_master_id),
	.data_out(aw_fifo_read_demux_out)
	);
	assign AW_fifo_read_o = aw_fifo_read_demux_out; 
	
	// w read demux 
	wire 					w_fifo_read;
	wire [MASTER_NUM-1:0]	w_fifo_read_demux_out;
	assign w_fifo_read = w_handshake;
	demux #(.SEL_WIDTH(MASTER_ID_WIDTH), .DATA_WIDTH(1))
	w_fifo_read_demux(
	.data_in(w_fifo_read),
	.sel(w_master_id),
	.data_out(w_fifo_read_demux_out)
	);
	assign W_fifo_read_o = w_fifo_read_demux_out;
	
	// w empty mux
	wire 					w_empty_mux_out;
	single_port_mux #(.SEL_WIDTH(MASTER_ID_WIDTH), .N(2**MASTER_ID_WIDTH), .DATA_WIDTH(1))
	w_empty_mux (
	.data_in(W_fifo_empty_i),
	.sel(w_master_id),
	.out(w_empty_mux_out)
	);
	assign W_valid_o = ~w_empty_mux_out;
	assign w_master_id_fifo_rd_en = w_handshake & W_last_i;
	
	
	// ar qos mask
	wire [MASTER_NUM-1:0] ar_masked_request;
	qos_request_mask #(
	.REQUESTER_NUM(MASTER_NUM),
	.QOS_WIDTH(QOS_WIDTH)
	) ar_qos_request_mask (
	.request(~AR_fifo_empty_i),
	.qos(AR_qos_i),
	.masked_request(ar_masked_request),
	.highest_qos()
	);
	
	// ar round-robin arbiter
	wire [2**MASTER_ID_WIDTH-1:0] ar_granted_one_hot;
	round_robin_arbiter #(
	.REQUESTER_NUM(MASTER_NUM),
	.MODE(1)
	) ar_round_robin_arbiter( 
	.clk(clk),
	.rst_n(rst_n),
	.request(ar_masked_request),
	.enable(ar_handshake),
	.grant(ar_granted_one_hot),
	.next_grant(),
	.slv_req()
	);
	
	// ar binary encoder
	wire [MASTER_ID_WIDTH-1:0] ar_master_id;
	binary_encoder #(.INPUT_WIDTH(2**MASTER_ID_WIDTH)) 
	ar_binary_encoder(
	.one_hot(ar_granted_one_hot),
	.binary(ar_master_id),
	.valid()
	);
	assign AR_valid_o = |ar_masked_request;
	assign AR_master_id_o = ar_master_id;
	
	// ar read demux
	wire 					ar_fifo_read;
	wire [MASTER_NUM-1:0] 	ar_fifo_read_demux_out;
	assign ar_fifo_read = aw_handshake;
	demux #(.SEL_WIDTH(MASTER_ID_WIDTH), .DATA_WIDTH(1))
	ar_fifo_read_demux(
	.data_in(ar_fifo_read),
	.sel(ar_master_id),
	.data_out(ar_fifo_read_demux_out)
	);
	assign AR_fifo_read_o = ar_fifo_read_demux_out;
	
	// extract master id from BID and RID
	wire [MASTER_ID_WIDTH-1:0] 		b_master_id;
	wire [MASTER_ID_WIDTH-1:0]		r_master_id;
	assign b_master_id = B_ID_i[SLAVE_TRANSACTION_ID_WIDTH-1-:MASTER_ID_WIDTH];
	assign r_master_id = R_ID_i[SLAVE_TRANSACTION_ID_WIDTH-1-:MASTER_ID_WIDTH];
	assign B_master_id_o = b_master_id;
	assign R_master_id_o = r_master_id;
	
	// b fifo full mux 
	wire b_fifo_full_mux_out;
	single_port_mux #(.SEL_WIDTH(MASTER_ID_WIDTH), .N(2**MASTER_ID_WIDTH), .DATA_WIDTH(1))
	b_fifo_full_mux (
	.data_in(B_fifo_full_i),
	.sel(b_master_id),
	.out(b_fifo_full_mux_out)
	);
	assign B_ready_o = ~b_fifo_full_mux_out;
	
	// b fifo write demux
	wire 					b_fifo_write;
	wire [MASTER_NUM-1:0] 	b_fifo_write_demux_out;
	assign b_fifo_write = b_handshake;
	demux #(.SEL_WIDTH(MASTER_ID_WIDTH), .DATA_WIDTH(1))
	b_fifo_write_demux(
	.data_in(b_fifo_write),
	.sel(b_master_id),
	.data_out(b_fifo_write_demux_out)
	);
	assign B_fifo_write_o = b_fifo_write_demux_out;
	
	// r fifo full mux 
	wire r_fifo_full_mux_out;
	single_port_mux #(.SEL_WIDTH(MASTER_ID_WIDTH), .N(2**MASTER_ID_WIDTH), .DATA_WIDTH(1))
	r_fifo_full_mux (
	.data_in(R_fifo_full_i),
	.sel(r_master_id),
	.out(r_fifo_full_mux_out)
	);
	assign R_ready_o = ~r_fifo_full_mux_out;
	
	// r fifo write demux
	wire 					r_fifo_write;
	wire [MASTER_NUM-1:0] 	r_fifo_write_demux_out;
	assign r_fifo_write = r_handshake;
	demux #(.SEL_WIDTH(MASTER_ID_WIDTH), .DATA_WIDTH(1))
	r_fifo_write_demux(
	.data_in(r_fifo_write),
	.sel(r_master_id),
	.data_out(r_fifo_write_demux_out)
	);
	assign R_fifo_write_o = r_fifo_write_demux_out;

endmodule