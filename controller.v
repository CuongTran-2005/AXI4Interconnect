`timescale 1ns / 1ps

module controller # (
	parameter SLAVE_NUM 			= 4,
    parameter SLAVE_ID_WIDTH    	= $clog2(SLAVE_NUM), // default SLAVE_ID_WIDTH = 2,
    parameter ADDR_WIDTH        	= 32,
	parameter TRANSACTION_ID_WIDTH 	= 2,
	parameter QOS_WIDTH 			= 4,
	parameter AXINFO_WIDTH 			= ADDR_WIDTH + TRANSACTION_ID_WIDTH + QOS_WIDTH,
	parameter MAX_OUTSTANDING_TRANSACTION = 8
)
(   
    /* global signals */
    input clk,
    input rst_n,
	
	/* input */
	input wire [AXINFO_WIDTH-1:0] 						AW_infor_i, // {AWADDR, AWID, AWQOS}
	input wire 											AW_valid_i,
	input wire [AXINFO_WIDTH-1:0] 						AR_infor_i, // {ARADDR, ARID, ARQOS}
	input wire 											AR_valid_i,
	input wire 											W_valid_i,
	input wire 											W_last_i,
	input wire 											W_ready_i,
	input wire 											B_ready_i,
	input wire 											B_last_i,
	input wire [TRANSACTION_ID_WIDTH*SLAVE_NUM-1:0]		B_trans_ID_i,
	input wire [SLAVE_NUM-1:0]							B_empty_i,
	input wire 											R_ready_i,
	input wire 											R_last_i,
	input wire [TRANSACTION_ID_WIDTH*SLAVE_NUM-1:0] 	R_trans_ID_i,
	input wire [SLAVE_NUM-1:0]							R_empty_i,
	
	/* output */		
	output 												AW_ready_o,
	output 												AR_ready_o,
	output 												B_valid_o,
	output 		[SLAVE_NUM-1:0] 						B_one_hot_grant_o,
	output 												R_valid_o,
	output		[SLAVE_NUM-1:0]							R_one_hot_grant_o,
	output 		[SLAVE_ID_WIDTH-1:0]					W_slave_id_o
);
	
	wire [ADDR_WIDTH-1:0] AWADDR = AW_infor_i[(AXINFO_WIDTH-1)-:ADDR_WIDTH];
	wire [TRANSACTION_ID_WIDTH-1:0] AWID = AW_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-1)-:TRANSACTION_ID_WIDTH];
	wire [QOS_WIDTH-1:0] AWQOS = AW_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-TRANSACTION_ID_WIDTH-1)-:QOS_WIDTH];
	wire [ADDR_WIDTH-1:0] ARADDR = AR_infor_i[(AXINFO_WIDTH-1)-:ADDR_WIDTH];
	wire [TRANSACTION_ID_WIDTH-1:0] ARID = AR_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-1)-:TRANSACTION_ID_WIDTH];
	wire [QOS_WIDTH-1:0] ARQOS = AR_infor_i[(AXINFO_WIDTH-ADDR_WIDTH-TRANSACTION_ID_WIDTH-1)-:QOS_WIDTH];
	
	/*---------write----------*/
	wire [SLAVE_ID_WIDTH-1:0] 			aw_slave_id;
	wire [QOS_WIDTH-1:0] 				aw_qos;
	wire [TRANSACTION_ID_WIDTH-1:0] 	aw_transaction_id;
	wire 								aw_fifo_write;
	wire 								aw_ready;
	/* AW address decoder */
	ax_decoder #(
	.ADDR_WIDTH(ADDR_WIDTH), 
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH), 
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH), 
	.QOS_WIDTH(QOS_WIDTH))
	u_aw_decoder (
	.AxADDR_i(AWADDR),
	.AxID_i(AWID),
	.AxQOS_i(AWQOS),
	.Ax_handshake_i(AW_valid_i & AW_ready_o),
	.slave_id_o(aw_slave_id),
	.fifo_write_o(aw_fifo_write),
	.transaction_id_o(aw_transaction_id),
	.qos_o(aw_qos),
	);
	/* W slave id fifo */
	wire 								w_fifo_full;
	wire [SLAVE_ID_WIDTH-1:0] 			w_slave_id;
	wire 								w_fifo_read;
	assign w_fifo_read = W_ready_i & W_last_i & W_valid_i;
	assign W_slave_id_o = w_slave_id;
	sc_fifo_lookahead #(.DATA_WIDTH(SLAVE_ID_WIDTH), .ADDR_WIDTH($clog2(MAX_OUTSTANDING_TRANSACTION)))
	u_w_slave_id_fifo(
	.clk(clk),
	.rst_n(rst_n),
	.wr_en(aw_fifo_write),
	.rd_en(w_fifo_read),
	.data(aw_slave_id),
	.q(w_slave_id),
	.full(w_fifo_full),
	.empty()
	);
	
	/* demux */
	wire [(SLAVE_ID_WIDTH+QOS_WIDTH)*(2**TRANSACTION_ID_WIDTH)-1:0] aw_id_fifo_data_demux_out;
	demux #(.SEL_WIDTH(TRANSACTION_ID_WIDTH), .DATA_WIDTH(SLAVE_ID_WIDTH + QOS_WIDTH))
	u_aw_id_fifo_data_demux(
	.data_in({aw_slave_id, aw_qos}),
	.sel(aw_transaction_id),
	.data_out(aw_id_fifo_data_demux_out)
	);
	wire [(2**TRANSACTION_ID_WIDTH)-1:0] aw_id_fifo_write_demux_out;
	demux #(.SEL_WIDTH(TRANSACTION_ID_WIDTH), .DATA_WIDTH(1))
	u_aw_id_fifo_write_demux(
	.data_in(aw_fifo_write),
	.sel(aw_transaction_id),
	.data_out(aw_id_fifo_write_demux_out)
	);
	/* mux */
	wire [(2**TRANSACTION_ID_WIDTH)-1:0] 	aw_id_fifo_full_mux_in;
	wire 									aw_id_fifo_full;
	single_port_mux #(.SEL_WIDTH(TRANSACTION_ID_WIDTH), .N(2**TRANSACTION_ID_WIDTH), .DATA_WIDTH(1))
	u_aw_id_fifo_full_mux(
	.data_in(aw_id_fifo_full_mux_in),
	.sel(aw_transaction_id),
	.out(aw_id_fifo_full)
	);
	assign aw_ready = ~w_fifo_full & ~aw_id_fifo_full;
	assign AW_ready_o = aw_ready;
	
	/* data channel controller (B) */
	axi4_data_channel_controller #(
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH),
	.SLAVE_NUM(SLAVE_NUM),
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
	.MAX_OUTSTANDING_TRANSACTION(MAX_OUTSTANDING_TRANSACTION),
	.QOS_WIDTH(QOS_WIDTH)
	) u_data_channel_controller_B (
	.clk(clk),
	.rst_n(rst_n),
	.ready(B_ready_i),
	.last(B_last_i),
	.valid(B_valid_o),
	.id_fifo_data(aw_id_fifo_data_demux_out),
	.id_fifo_write(aw_id_fifo_write_demux_out),
	.id_fifo_full(aw_id_fifo_full_mux_in),
	.trans_id(B_trans_ID_i),
	.data_fifo_empty(B_empty_i),
	.grant(B_one_hot_grant_o)
	);
	
	/*---------read----------*/
	wire [SLAVE_ID_WIDTH-1:0] 			ar_slave_id;
	wire [QOS_WIDTH-1:0] 				ar_qos;
	wire [TRANSACTION_ID_WIDTH-1:0] 	ar_transaction_id;
	wire 								ar_fifo_write;
	wire 								ar_ready;
	ax_decoder #(
	.ADDR_WIDTH(ADDR_WIDTH), 
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH), 
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH), 
	.QOS_WIDTH(QOS_WIDTH))
	u_ar_decoder (
	.AxADDR_i(ARADDR),
	.AxID_i(ARID),
	.AxQOS_i(ARQOS),
	.Ax_handshake_i(AR_valid_i & AR_ready_o),
	.slave_id_o(ar_slave_id),
	.fifo_write_o(ar_fifo_write),
	.transaction_id_o(ar_transaction_id),
	.qos_o(ar_qos),
	);
	
	/* demux */
	wire [(SLAVE_ID_WIDTH+QOS_WIDTH)*(2**TRANSACTION_ID_WIDTH)-1:0] ar_id_fifo_data_demux_out;
	demux #(.SEL_WIDTH(TRANSACTION_ID_WIDTH), .DATA_WIDTH(SLAVE_ID_WIDTH + QOS_WIDTH))
	u_ar_id_fifo_data_demux(
	.data_in({ar_slave_id, ar_qos}),
	.sel(ar_transaction_id),
	.data_out(ar_id_fifo_data_demux_out)
	);
	wire [(2**TRANSACTION_ID_WIDTH)-1:0] ar_id_fifo_write_demux_out;
	demux #(.SEL_WIDTH(TRANSACTION_ID_WIDTH), .DATA_WIDTH(1))
	u_ar_id_fifo_write_demux(
	.data_in(ar_fifo_write),
	.sel(ar_transaction_id),
	.data_out(ar_id_fifo_write_demux_out)
	);
	/* mux */
	wire [(2**TRANSACTION_ID_WIDTH)-1:0] 	ar_id_fifo_full_mux_in;
	wire 									ar_id_fifo_full;
	single_port_mux #(.SEL_WIDTH(TRANSACTION_ID_WIDTH), .N(2**TRANSACTION_ID_WIDTH), .DATA_WIDTH(1))
	u_ar_id_fifo_full_mux(
	.data_in(ar_id_fifo_full_mux_in),
	.sel(ar_transaction_id),
	.out(ar_id_fifo_full)
	);
	assign ar_ready = ~ar_id_fifo_full;
	assign AR_ready_o = ar_ready;
	
	/* data channel controller (R) */
	axi4_data_channel_controller #(
	.TRANSACTION_ID_WIDTH(TRANSACTION_ID_WIDTH),
	.SLAVE_NUM(SLAVE_NUM),
	.SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
	.MAX_OUTSTANDING_TRANSACTION(MAX_OUTSTANDING_TRANSACTION),
	.QOS_WIDTH(QOS_WIDTH)
	) u_data_channel_controller_R (
	.clk(clk),
	.rst_n(rst_n),
	.ready(R_ready_i),
	.last(R_last_i),
	.valid(R_valid_o),
	.id_fifo_data(ar_id_fifo_data_demux_out),
	.id_fifo_write(ar_id_fifo_write_demux_out),
	.id_fifo_full(ar_id_fifo_full_mux_in),
	.trans_id(R_trans_ID_i),
	.data_fifo_empty(R_empty_i),
	.grant(R_one_hot_grant_o)
	);
endmodule