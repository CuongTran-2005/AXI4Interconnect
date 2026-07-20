`timescale 1ns/1ps

module axi4_data_channel_controller # (
	parameter TRANSACTION_ID_WIDTH 			= 2,
	parameter SLAVE_NUM						= 4,
	parameter SLAVE_ID_WIDTH 				= $clog2(SLAVE_NUM),
	parameter MAX_OUTSTANDING_TRANSACTION 	= 8,
	parameter QOS_WIDTH						= 4
)
(
	input wire clk,
	input wire rst_n,
	
	/* data controller */
	input wire ready,
	input wire last,
	output wire valid,
	
	/* id fifo */
	input wire [(2**TRANSACTION_ID_WIDTH)*(SLAVE_ID_WIDTH+QOS_WIDTH)-1:0] id_fifo_data,
	input wire [(2**TRANSACTION_ID_WIDTH)-1:0] id_fifo_write,
	output wire [(2**TRANSACTION_ID_WIDTH)-1:0] id_fifo_full,
	
	/* data channel */
	input wire [SLAVE_NUM * TRANSACTION_ID_WIDTH - 1:0] trans_id,
	input wire [SLAVE_NUM - 1:0] data_fifo_empty,
	output wire [SLAVE_NUM -1:0] grant
);

	localparam ID_FIFO_NUM = 2**TRANSACTION_ID_WIDTH;
	localparam ID_FIFO_WIDTH = SLAVE_ID_WIDTH + QOS_WIDTH; // ID FIFO structure = {slave id, qos}

	/* internal nets */
	
	
	/* generate ID FIFOs */
	wire [ID_FIFO_NUM*(SLAVE_ID_WIDTH+QOS_WIDTH)-1:0] id_fifo_out;
	wire [ID_FIFO_NUM-1:0] id_fifo_read;
	genvar id_fifo_index;
	generate
		for (id_fifo_index = 0; id_fifo_index < ID_FIFO_NUM; id_fifo_index = id_fifo_index + 1) begin : id_fifo
			sc_fifo_lookahead # (.DATA_WIDTH(SLAVE_ID_WIDTH + QOS_WIDTH), .ADDR_WIDTH($clog2(MAX_OUTSTANDING_TRANSACTION)))
			u_sc_fifo_lookahead(
			.clk(clk), 
			.rst_n(rst_n),
			.wr_en(id_fifo_write[id_fifo_index]), 
			.rd_en(id_fifo_read[id_fifo_index]),
			.data(id_fifo_data[id_fifo_index*ID_FIFO_WIDTH +: ID_FIFO_WIDTH]),
			.q(id_fifo_out[id_fifo_index*ID_FIFO_WIDTH +: ID_FIFO_WIDTH]),
			.full(id_fifo_full[id_fifo_index]),
			.empty());
		end
	endgenerate
	
	/* generate slave id mux */
	wire [SLAVE_ID_WIDTH*ID_FIFO_NUM-1:0] slave_id_mux_in [0:SLAVE_NUM-1];
	wire [SLAVE_ID_WIDTH-1:0] slave_id_mux_out [0:SLAVE_NUM-1];
	genvar slave_index;
	generate 
		for (slave_index = 0; slave_index < SLAVE_NUM; slave_index = slave_index + 1) begin : slave_id_mux
			for (id_fifo_index = 0; id_fifo_index <ID_FIFO_NUM; id_fifo_index = id_fifo_index + 1) begin : slave_id_mux_input_assign
				/* extract slave id from fifo output */
				assign slave_id_mux_in[slave_index][id_fifo_index*SLAVE_ID_WIDTH+:SLAVE_ID_WIDTH] = id_fifo_out[id_fifo_index*ID_FIFO_WIDTH+QOS_WIDTH+:SLAVE_ID_WIDTH]; 
			end
			single_port_mux # (.SEL_WIDTH(TRANSACTION_ID_WIDTH), .N(ID_FIFO_NUM), .DATA_WIDTH(SLAVE_ID_WIDTH))
			u_slave_id_mux (
			.data_in(slave_id_mux_in[slave_index]),
			.sel(trans_id[slave_index*TRANSACTION_ID_WIDTH+:TRANSACTION_ID_WIDTH]),
			.out(slave_id_mux_out[slave_index])
			);
		end
	endgenerate
	
	/* generate slave id comparators */
	genvar slave_id_comparator_index;
	wire slave_id_compare_equal [0:SLAVE_NUM-1];
	generate 
		for (slave_id_comparator_index = 0; slave_id_comparator_index < SLAVE_NUM; slave_id_comparator_index = slave_id_comparator_index + 1) begin : slave_id_comparator
			constant_comparator #(.DATA_WIDTH(SLAVE_ID_WIDTH), .COMP_VAL(slave_id_comparator_index))
			u_slave_id_compare(.data_in(slave_id_mux_out[slave_id_comparator_index]), .equal(slave_id_compare_equal[slave_id_comparator_index]));
		end
	endgenerate
	
	/* request bus combinational logic */
	wire [SLAVE_NUM-1:0] request_bus;
	genvar request_index;
	generate 
		for (request_index = 0; request_index < SLAVE_NUM; request_index = request_index + 1) begin : request
			assign request_bus[request_index] = slave_id_compare_equal[request_index] & ~data_fifo_empty[request_index];
		end
	endgenerate
	
	/* QoS mux */
	wire [QOS_WIDTH-1:0] QoS [0:ID_FIFO_NUM-1];
	wire [QOS_WIDTH*ID_FIFO_NUM-1:0] QoS_mux_in;
	wire [QOS_WIDTH-1:0] QoS_mux_out;
	wire [TRANSACTION_ID_WIDTH-1:0] QoS_mux_sel;
	genvar qos_mux_input_index;
	generate 
		for (qos_mux_input_index = 0; qos_mux_input_index < ID_FIFO_NUM; qos_mux_input_index = qos_mux_input_index + 1) begin : qos_input_assign
			assign QoS[qos_mux_input_index] = id_fifo_out[qos_mux_input_index*ID_FIFO_WIDTH+:QOS_WIDTH];
			assign QoS_mux_in[qos_mux_input_index*QOS_WIDTH+:QOS_WIDTH] = QoS[qos_mux_input_index];
		end
	endgenerate
	single_port_mux # (.SEL_WIDTH(TRANSACTION_ID_WIDTH), .N(ID_FIFO_NUM), .DATA_WIDTH(QOS_WIDTH))
	u_qos_mux (.data_in(QoS_mux_in), .sel(QoS_mux_sel), .out(QoS_mux_out));
	
	/* data controller */
	wire [SLAVE_NUM-1:0] one_hot_grant;
	wire [SLAVE_NUM-1:0] next_granted_slave;
	wire id_fifo_rd_en;
	data_controller #(.REQUESTER_NUM(SLAVE_NUM))
	u_data_controller (
	.clk(clk),
	.rst_n(rst_n),
	.QoS(QoS_mux_out),
	.request_bus(request_bus),
	.ready(ready),
	.last(last),
	.valid(valid),
	.id_fifo_read(id_fifo_rd_en), 
	.grant_bus(one_hot_grant),
	.next_granted_slave(next_granted_slave)
	);
	assign grant = one_hot_grant;
	
	/* id read fifo demux */
	wire [TRANSACTION_ID_WIDTH-1:0] id_read_fifo_demux_sel;
	demux #(.SEL_WIDTH(TRANSACTION_ID_WIDTH), .DATA_WIDTH(1))
	u_id_fifo_rd_en_demux(.data_in(id_fifo_rd_en), .sel(id_read_fifo_demux_sel), .data_out(id_fifo_read));
	
	/* next granted slave trans id mux */
	wire [TRANSACTION_ID_WIDTH-1:0] next_granted_trans_id;
	one_hot_mux #(.N(SLAVE_NUM), .DATA_WIDTH(TRANSACTION_ID_WIDTH))
	next_granted_trans_id_mux(.data_in(trans_id), .sel(next_granted_slave), .data_out(next_granted_trans_id));
	assign QoS_mux_sel = next_granted_trans_id;
	
	/* current granted slave trans id mux */
	wire [TRANSACTION_ID_WIDTH-1:0] curr_granted_trans_id;
	one_hot_mux #(.N(SLAVE_NUM), .DATA_WIDTH(TRANSACTION_ID_WIDTH))
	curr_granted_trans_id_mux(.data_in(trans_id), .sel(one_hot_grant), .data_out(curr_granted_trans_id));
	assign id_read_fifo_demux_sel = curr_granted_trans_id;
	
endmodule