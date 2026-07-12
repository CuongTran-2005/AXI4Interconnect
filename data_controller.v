`timescale 1ns / 1ps

module data_controller #(
	parameter REQUESTER_NUM = 4
)(
	input wire clk,
	input wire rst_n,
	input wire [3:0] QoS,
	input wire [REQUESTER_NUM-1:0] request_bus,
	input wire ready,
	input wire last,
	output wire valid,
	output wire id_fifo_read,
	output wire [REQUESTER_NUM-1:0] grant_bus, 
	output wire [REQUESTER_NUM-1:0] next_granted_slave
);

	/* internal wires */
	wire slv_request;
	wire arbiter_enable;
	wire grant_enable;
	wire request;
	wire [REQUESTER_NUM-1:0] grant_bus_buffer;
	
	/* assignement */
	assign request = |request_bus;
	assign grant_bus = (grant_enable)?grant_bus_buffer:{REQUESTER_NUM{1'bZ}};
	
	/* instantiation */
	data_controller_main_fsm u_main_fsm(
		.clk(clk),
		.rst_n(rst_n),
		.QoS(QoS),
		.request(request),
		.ready(ready),
		.last(last),
		.slv_req(slv_request),
		.arbiter_enable(arbiter_enable),
		.valid(valid),
		.id_fifo_read(id_fifo_read),
		.grant_enable(grant_enable)
	);
	
	round_robin_arbiter #(
		.REQUESTER_NUM(REQUESTER_NUM)
	)
	u_arbiter (
		.clk(clk),
		.rst_n(rst_n),
		.request(request_bus),
		.enable(arbiter_enable),
		.grant(grant_bus_buffer),
		.next_grant(next_granted_slave),
		.slv_req(slv_request)
	);
	
	


endmodule