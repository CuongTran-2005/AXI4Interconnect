`timescale 1ns / 1ps

module controller # (
	parameter SLAVE_NUM 					= 4,
    parameter SLAVE_ID_WIDTH    			= $clog2(SLAVE_NUM), // default SLAVE_ID_WIDTH = 2,
    parameter ADDR_WIDTH        			= 32,
	parameter TRANSACTION_ID_WIDTH 			= 4,
	parameter QOS_WIDTH 					= 4,
	parameter AXINFO_WIDTH 					= ADDR_WIDTH + TRANSACTION_ID_WIDTH + QOS_WIDTH,
	parameter MAX_OUTSTANDING_TRANSACTION 	= 8
)
(   
    /* global signals */
    input clk,
    input rst_n,
	
	/*======================dispatch side====================*/
	/*--------------------------input------------------------*/
	// AW channel fifo full signals
	input [SLAVE_NUM-1:0]								AW_fifo_full_i,
	
	// W channel fifo full signals
	input [SLAVE_NUM-1:0] 								W_fifo_full_i,
	
	// AR channel fifo full signals 
	input [SLAVE_NUM-1:0] 								AR_fifo_full_i,
	
	// B channel last signal (tied to logic high)
	input wire 											B_last_i,
	
	// B channel transaction IDs
	input wire [(TRANSACTION_ID_WIDTH*SLAVE_NUM)-1:0] 	B_trans_ID_i,
	
	// B channel empty signals
	input wire [SLAVE_NUM-1:0]							B_empty_i,
	
	// R channel last signal 
	input wire 											R_last_i,
	
	// R channel transaction IDs
	input wire [(TRANSACTION_ID_WIDTH*SLAVE_NUM)-1:0]	R_trans_ID_i,
	
	// R channel empty signals 
	input wire [SLAVE_NUM-1:0] 							R_empty_i,
	
	
	

	
	/*--------------------------output-----------------------*/
	// slave id -> AW Channel
	output wire [SLAVE_ID_WIDTH-1:0] 					AW_slave_id_o,
	
	// slave id -> W Channel
	output wire [SLAVE_ID_WIDTH-1:0] 					W_slave_id_o,
	
	// slave id -> AR Channel
	output wire [SLAVE_ID_WIDTH-1:0] 					AR_slave_id_o,
	
	// B Channel fifo one-hot grant signal
	output wire [SLAVE_NUM-1:0]							B_one_hot_grant_o,
	output wire [SLAVE_ID_WIDTH -1 :0]					B_slave_id_o,
	// R Channel fifo one-hot grant signal
	output wire [SLAVE_NUM-1:0] 						R_one_hot_grant_o,
	output wire [SLAVE_ID_WIDTH -1 :0]					R_slave_id_o,
	// fifo_write -> AW Channel
	output wire [SLAVE_NUM-1:0]							AW_fifo_write_o,
	
	// fifo_write -> W Channel
	output wire [SLAVE_NUM-1:0]							W_fifo_write_o,
	
	// fifo_write -> AR Channel
	output wire [SLAVE_NUM-1:0]							AR_fifo_write_o,
	
	/*=======================master side=====================*/
	/*--------------------------input------------------------*/
	// address and control information
	input wire [AXINFO_WIDTH-1:0] 						AW_infor_i, // {AWADDR, AWID, AWQOS}
	input wire [AXINFO_WIDTH-1:0] 						AR_infor_i, // {ARADDR, ARID, ARQOS}
	
	// AW Channel handshake signal 
	input wire 											AW_valid_i,
	
	// W Channel handshake signal
	input wire 											W_valid_i,
	
	// B Channel handshake signal
	input wire 											B_ready_i,
	
	// AR Channel handshake signal
	input wire 											AR_valid_i,
	
	// R Channel handshake signal
	input wire 											R_ready_i,
	
	// W Channel last signal 
	input wire 											W_last_i,
	
	/*--------------------------output-----------------------*/
	// AW Channel handshake signal
	output wire 										AW_ready_o,
	
	// W channel handshake signal 
	output wire 										W_ready_o,
	
	// B Channel handshake signal						
	output wire 										B_valid_o,
	
	// AR Channel handshake signal 						
	output wire 										AR_ready_o,
	
	// R Channel handshake signal				
	output wire 										R_valid_o
	
	
);
	
	wire [ADDR_WIDTH-1:0] 			AWADDR 	= AW_infor_i[(AXINFO_WIDTH-1)-:ADDR_WIDTH];
	wire [TRANSACTION_ID_WIDTH-1:0] AWID	= AW_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-1)-:TRANSACTION_ID_WIDTH];
	wire [QOS_WIDTH-1:0] 			AWQOS 	= AW_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-TRANSACTION_ID_WIDTH-1)-:QOS_WIDTH];
	wire [ADDR_WIDTH-1:0] 			ARADDR 	= AR_infor_i[(AXINFO_WIDTH-1)-:ADDR_WIDTH];
	wire [TRANSACTION_ID_WIDTH-1:0] ARID 	= AR_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-1)-:TRANSACTION_ID_WIDTH];
	wire [QOS_WIDTH-1:0] 			ARQOS 	= AR_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-TRANSACTION_ID_WIDTH-1)-:QOS_WIDTH];
	
	/*===========================WRITE=========================*/
	wire 							aw_decoder_handshake;
	wire [SLAVE_ID_WIDTH-1:0] 		aw_decoder_slave_id;
	wire 							aw_decoder_fifo_write;
	wire [TRANSACTION_ID_WIDTH-1:0] aw_decoder_transaction_id;
	wire [QOS_WIDTH-1:0]			aw_decoder_qos;
	ax_decoder #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH),
	.QOS_WIDTH(QOS_WIDTH)
	) aw_decoder (
	.AxADDR_i(AWADDR),
	.AxID_i(AWID),
	.AxQOS_i(AWQOS),
	.Ax_handshake_i(aw_decoder_handshake),
	.slave_id_o(aw_decoder_slave_id),
	.fifo_write_o(aw_decoder_fifo_write),
	.transaction_id_o(aw_decoder_transaction_id),
	.qos_o(aw_decoder_qos)
	);
	
	wire [(SLAVE_ID_WIDTH+QOS_WIDTH)*2**TRANSACTION_ID_WIDTH-1:0] 	b_control_infor_demux_out;
	demux #(
	.SEL_WIDTH(TRANSACTION_ID_WIDTH),
	.DATA_WIDTH(SLAVE_ID_WIDTH+QOS_WIDTH)
	) b_control_infor_demux (
	.data_in({aw_decoder_slave_id, aw_decoder_qos}),
	.sel(aw_decoder_transaction_id),
	.data_out(b_control_infor_demux_out)
	);
	
	wire [2**TRANSACTION_ID_WIDTH-1:0]		b_fifo_write_demux_out;
	demux #(
	.SEL_WIDTH(TRANSACTION_ID_WIDTH),
	.DATA_WIDTH(1)
	) b_fifo_write_demux (
	.data_in(aw_decoder_fifo_write),
	.sel(aw_decoder_transaction_id),
	.data_out(b_fifo_write_demux_out)
	);

	wire [2**TRANSACTION_ID_WIDTH-1:0] 		b_fifo_full_mux_in;
	wire 									b_fifo_full_mux_out;
	single_port_mux #(
	.SEL_WIDTH(TRANSACTION_ID_WIDTH),
	.N(2**TRANSACTION_ID_WIDTH),
	.DATA_WIDTH(1)
	) b_fifo_full_mux (
	.data_in(b_fifo_full_mux_in),
	.sel(aw_decoder_transaction_id),
	.out(b_fifo_full_mux_out)
	);
	
	axi4_data_channel_controller #(
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH),
	.SLAVE_NUM(SLAVE_NUM),
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
	.MAX_OUTSTANDING_TRANSACTION(MAX_OUTSTANDING_TRANSACTION),
	.QOS_WIDTH(QOS_WIDTH)
	) b_data_channel_controller (
	.clk(clk),
	.rst_n(rst_n),
	.ready(B_ready_i),
	.valid(B_valid_o),
	.last(B_last_i),
	.id_fifo_data(b_control_infor_demux_out),
	.id_fifo_write(b_fifo_write_demux_out),
	.id_fifo_full(b_fifo_full_mux_in),
	.trans_id(B_trans_ID_i),
	.data_fifo_empty(B_empty_i),
	.grant(B_one_hot_grant_o)
	);
	
	wire w_slave_id_fifo_read;
	wire w_slave_id_fifo_full;
	sc_fifo_lookahead #(
	.DATA_WIDTH(SLAVE_ID_WIDTH),
	.ADDR_WIDTH($clog2(MAX_OUTSTANDING_TRANSACTION)*4)
	) w_slave_id_fifo(
	.clk(clk),
	.rst_n(rst_n),
	.wr_en(aw_decoder_fifo_write),
	.rd_en(w_slave_id_fifo_read),
	.data(aw_decoder_slave_id),
	.q(W_slave_id_o),
	.full(w_slave_id_fifo_full),
	.empty()
	);
	
	wire aw_fifo_full_mux_out;
	single_port_mux #(
	.SEL_WIDTH(SLAVE_ID_WIDTH),
	.N(2*SLAVE_ID_WIDTH),
	.DATA_WIDTH(1)
	) aw_fifo_full_mux (
	.data_in(AW_fifo_full_i),
	.sel(AW_slave_id_o),
	.out(aw_fifo_full_mux_out)
	);
	
	wire w_fifo_full_mux_out;
	single_port_mux #(
	.SEL_WIDTH(SLAVE_ID_WIDTH),
	.N(2*SLAVE_ID_WIDTH),
	.DATA_WIDTH(1)
	) w_fifo_full_mux(
	.data_in(W_fifo_full_i),
	.sel(W_slave_id_o),
	.out(w_fifo_full_mux_out)
	);
	
	wire [SLAVE_NUM-1:0] aw_fifo_write_demux_out;
	demux #(.SEL_WIDTH(SLAVE_ID_WIDTH), .DATA_WIDTH(1))
	aw_fifo_write_demux(
	.data_in(aw_decoder_fifo_write),
	.sel(AW_slave_id_o),
	.data_out(aw_fifo_write_demux_out)
	);
	
	wire [SLAVE_NUM-1:0] w_fifo_write_demux_out;
	demux #(.SEL_WIDTH(SLAVE_ID_WIDTH), .DATA_WIDTH(1))
	w_fifo_write_demux(
	.data_in(W_valid_i & W_ready_o),
	.sel(W_slave_id_o),
	.data_out(w_fifo_write_demux_out)
	);
	
	assign AW_ready_o = ~b_fifo_full_mux_out & ~aw_fifo_full_mux_out & ~w_slave_id_fifo_full;
	assign AW_fifo_write_o = aw_fifo_write_demux_out;
	assign AW_slave_id_o = aw_decoder_slave_id;
	assign aw_decoder_handshake = AW_ready_o & AW_valid_i;
	assign W_ready_o = ~w_fifo_full_mux_out;
	assign W_fifo_write_o = w_fifo_write_demux_out;
	assign w_slave_id_fifo_read = W_last_i & W_ready_o & W_valid_i;
	
	/*===========================READ=========================*/
	wire 							ar_decoder_handshake;
	wire [SLAVE_ID_WIDTH-1:0] 		ar_decoder_slave_id;
	wire 							ar_decoder_fifo_write;
	wire [TRANSACTION_ID_WIDTH-1:0] ar_decoder_transaction_id;
	wire [QOS_WIDTH-1:0]			ar_decoder_qos;
	ax_decoder #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH),
	.QOS_WIDTH(QOS_WIDTH)
	) ar_decoder (
	.AxADDR_i(ARADDR),
	.AxID_i(ARID),
	.AxQOS_i(ARQOS),
	.Ax_handshake_i(ar_decoder_handshake),
	.slave_id_o(ar_decoder_slave_id),
	.fifo_write_o(ar_decoder_fifo_write),
	.transaction_id_o(ar_decoder_transaction_id),
	.qos_o(ar_decoder_qos)
	);
	
	wire [(SLAVE_ID_WIDTH+QOS_WIDTH)*2**TRANSACTION_ID_WIDTH-1:0] 	r_control_infor_demux_out;
	demux #(
	.SEL_WIDTH(TRANSACTION_ID_WIDTH),
	.DATA_WIDTH(SLAVE_ID_WIDTH+QOS_WIDTH)
	) r_control_infor_demux (
	.data_in({ar_decoder_slave_id, ar_decoder_qos}),
	.sel(ar_decoder_transaction_id),
	.data_out(r_control_infor_demux_out)
	);
	
	wire [2**TRANSACTION_ID_WIDTH-1:0]		r_fifo_write_demux_out;
	demux #(
	.SEL_WIDTH(TRANSACTION_ID_WIDTH),
	.DATA_WIDTH(1)
	) r_fifo_write_demux (
	.data_in(ar_decoder_fifo_write),
	.sel(ar_decoder_transaction_id),
	.data_out(r_fifo_write_demux_out)
	);

	wire [2**TRANSACTION_ID_WIDTH-1:0] 		r_fifo_full_mux_in;
	wire 									r_fifo_full_mux_out;
	single_port_mux #(
	.SEL_WIDTH(TRANSACTION_ID_WIDTH),
	.N(2**TRANSACTION_ID_WIDTH),
	.DATA_WIDTH(1)
	) r_fifo_full_mux (
	.data_in(r_fifo_full_mux_in),
	.sel(ar_decoder_transaction_id),
	.out(r_fifo_full_mux_out)
	);
	
	axi4_data_channel_controller #(
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH),
	.SLAVE_NUM(SLAVE_NUM),
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
	.MAX_OUTSTANDING_TRANSACTION(MAX_OUTSTANDING_TRANSACTION),
	.QOS_WIDTH(QOS_WIDTH)
	) r_data_channel_controller (
	.clk(clk),
	.rst_n(rst_n),
	.ready(R_ready_i),
	.valid(R_valid_o),
	.last(R_last_i),
	.id_fifo_data(r_control_infor_demux_out),
	.id_fifo_write(r_fifo_write_demux_out),
	.id_fifo_full(r_fifo_full_mux_in),
	.trans_id(R_trans_ID_i),
	.data_fifo_empty(R_empty_i),
	.grant(R_one_hot_grant_o)
	);
	
	wire ar_fifo_full_mux_out;
	single_port_mux #(
	.SEL_WIDTH(SLAVE_ID_WIDTH),
	.N(2*SLAVE_ID_WIDTH),
	.DATA_WIDTH(1)
	) ar_fifo_full_mux (
	.data_in(AR_fifo_full_i),
	.sel(AR_slave_id_o),
	.out(ar_fifo_full_mux_out)
	);
	
	wire [SLAVE_NUM-1:0] ar_fifo_write_demux_out;
	demux #(.SEL_WIDTH(SLAVE_ID_WIDTH), .DATA_WIDTH(1))
	ar_fifo_write_demux(
	.data_in(ar_decoder_fifo_write),
	.sel(AR_slave_id_o),
	.data_out(ar_fifo_write_demux_out)
	);
	
	assign AR_ready_o = ~r_fifo_full_mux_out & ~ar_fifo_full_mux_out;
	assign AR_fifo_write_o = ar_fifo_write_demux_out;
	assign AR_slave_id_o = ar_decoder_slave_id;
	assign ar_decoder_handshake = AR_ready_o & AR_valid_i;
	one_hot_encoder #(
		.N_AMT (SLAVE_NUM),
		.N_ID_W(SLAVE_ID_WIDTH)
	) u_B_one_hot_encoder (
		.one_hot_grant_i(B_one_hot_grant_o),
		.id_o           (B_slave_id_o)
	);
	one_hot_encoder #(
		.N_AMT (SLAVE_NUM),
		.N_ID_W(SLAVE_ID_WIDTH)
	) u_R_one_hot_encoder (
		.one_hot_grant_i(R_one_hot_grant_o),
		.id_o           (R_slave_id_o)
	);
endmodule