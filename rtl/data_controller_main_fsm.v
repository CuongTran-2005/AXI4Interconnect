`timescale 1ns/1ps

module data_controller_main_fsm
(
    input clk, 
    input rst_n,
    input [3:0] QoS,
    input request,
    input ready,
    input last,
    input slv_req,
    output reg arbiter_enable,
    output reg valid,
    output reg id_fifo_read,
	output reg grant_enable
);
    localparam S_IDLE = 2'd0;
    localparam S_ARBITRATION = 2'd1;
    localparam S_ALLOCATED = 2'd2;
    localparam S_STALL = 2'd3;

    reg [1:0] state, next_state;
    reg [3:0] qos_counter;
	reg data_shift_enable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    /* next state logic */
    always @(*) begin
			next_state = S_IDLE;
        case (state)
            S_IDLE:begin
				if (request) next_state = S_ARBITRATION;
				else next_state = S_IDLE;
			end
            S_ARBITRATION: next_state = (ready)?S_ALLOCATED:S_STALL;
            S_ALLOCATED: begin
                if (request == 0) next_state = S_IDLE;
                else if (!ready) next_state = S_STALL;
				else next_state = S_ALLOCATED;
            end
            S_STALL: begin 
				if (ready) next_state = S_ALLOCATED;
				else next_state = S_STALL;
			end 
            default: next_state = S_IDLE;
        endcase
    end

    /* state action */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            qos_counter = 0;
        end
        else begin
            case (state)
                S_IDLE: begin
					qos_counter = 0;
                end
                S_ARBITRATION: begin
                    qos_counter = QoS;
                end
                S_ALLOCATED: begin
                    qos_counter = (data_shift_enable)?qos_counter-4'd1:qos_counter;
                    qos_counter = (arbiter_enable)?QoS:qos_counter;
                end
                default:;
            endcase
        end
    end

    /* combinational output */
	always @(*) begin
		/* valid */
		if ((state == S_ALLOCATED | state == S_STALL) & slv_req == 1'b1) valid = 1'b1;
		else valid = 1'b0;
		
		/* data_shift_enable */
		if (ready == 1'b1 & state == S_ALLOCATED & valid == 1'b1) data_shift_enable = 1'b1;
		else data_shift_enable = 1'b0;
		
		/* arbiter_enable */
		if (state == S_ARBITRATION) arbiter_enable = 1'b1;
		else if (state == S_ALLOCATED & (qos_counter == 0 | slv_req == 1'b0 | last == 1'b1)) arbiter_enable = 1'b1;
		else arbiter_enable = 1'b0;
		
		/* id_fifo_read */
		if (last == 1'b1 & data_shift_enable == 1'b1) id_fifo_read = 1'b1;
		else id_fifo_read = 1'b0;
		
		/* grant_enable */
		grant_enable = data_shift_enable;
	end
    
endmodule