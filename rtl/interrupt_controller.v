module interrupt_controller
#(
    parameter SLV_AMT    = 4,
    parameter SLV_ID_W   = $clog2(SLV_AMT),
    parameter PRIORITY_W = 3
)
(
    input  wire                             clk_i,
    input  wire                             rst_n_i,

    //-------------------------------------------------
    // Interrupt request from slaves
    //-------------------------------------------------
    input  wire [SLV_AMT-1:0]               irq_i,

    //-------------------------------------------------
    // Configuration from Master
    //-------------------------------------------------
    input  wire [SLV_AMT-1:0]               irq_en_i,
    input  wire [SLV_AMT*PRIORITY_W-1:0]    priority_i,

    //-------------------------------------------------
    // Master acknowledge
    //-------------------------------------------------
    input  wire                             irq_ack_i,

    //-------------------------------------------------
    // Interrupt output
    //-------------------------------------------------
    output reg                              irq_o,
    output reg [SLV_ID_W-1:0]               irq_id_o
);

    //-------------------------------------------------
    // Internal Signals
    //-------------------------------------------------

    wire [SLV_AMT-1:0] pending_irq;

    wire [SLV_AMT-1:0] masked_irq;

    wire arb_irq_valid;

    wire [SLV_ID_W-1:0] arb_irq_id;

    wire [SLV_AMT-1:0] selected;
    reg interupt_done;
    wire [SLV_AMT-1:0] controler_free;
    wire [SLV_ID_W*SLV_AMT-1:0] counter_block;

    //-------------------------------------------------
    // FSM
    //-------------------------------------------------

    localparam IDLE   = 2'd0;
	localparam ASSERT_IRQ = 2'd1;
    localparam WAIT_RELEASE = 2'd2;
    localparam DONE = 2'd3;
    

    reg [1:0] state;

    //-------------------------------------------------
    // Pending Register
    //-------------------------------------------------

    irq_pending
    #(
        .SLV_AMT (SLV_AMT),
        .SLV_ID_W(SLV_ID_W)
    )
    u_irq_pending
    (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .irq_i(irq_i),

        .pending_o(pending_irq)
    );

    //-------------------------------------------------
    // Enable Mask
    //-------------------------------------------------
    genvar i;

    generate
        for (i = 0; i < SLV_AMT; i = i + 1) begin : GEN_RR_MASK

            round_robin_masked_irq #(
                .SLV_AMT    (SLV_AMT),
                .SLV_ID_W   (SLV_ID_W),
                .PRIORITY_W (PRIORITY_W)                    //fixed
            ) u_round_robin_masked_irq (
                .clk               (clk_i),
                .rst_n             (rst_n_i),

                .pending_irq_i     (pending_irq[i]), //wire da co
                .irq_en_i          (irq_en_i[i]), //wire da co
                .selected_i        (selected[i]), //wire da co
                //.selected_en_i     (),
                .interupt_done_i   (interupt_done), //da co
                .controler_free_i  (controler_free[i]), 

                .counter_block_o   (counter_block[i]),
                .masked_irq_o      (masked_irq[i]) //daco
            );

        end
    endgenerate
// free select
    controller_free_select #(
        .SLV_AMT  (SLV_AMT),
        .SLV_ID_W (SLV_ID_W)
    ) u_controller_free_select (
        .counter_block   (counter_block),
        .masked_irq      (masked_irq),
        .pending_irq     (pending_irq & irq_en_i),

        .controler_free  (controler_free)
    );
    //assign masked_irq = pending_irq & irq_en_i;
    //-------------------------------------------------
    // Priority Arbiter
    //-------------------------------------------------

    arbiter_priority_irq
    #(
        .SLV_AMT(SLV_AMT),
        .SLV_ID_W(SLV_ID_W),
        .PRIORITY_W(PRIORITY_W)
    )
    u_arbiter_priority_irq
    (
        .masked_irq_i(masked_irq),

        .priority_i(priority_i),

        .irq_valid_o(arb_irq_valid),

        .irq_slv_id_o(arb_irq_id)
    );

    generate
        for (i = 0; i < SLV_AMT; i = i + 1) begin : GEN_DECODER_SELECT
            assign selected[i] = (arb_irq_id == i) & irq_o;
        end
    endgenerate
    //-------------------------------------------------
    // FSM
    //-------------------------------------------------

    always @(posedge clk_i or negedge rst_n_i)
    begin
        if(!rst_n_i)
        begin
            state    <= IDLE;
            irq_o    <= 1'b0;
            irq_id_o <= {SLV_ID_W{1'b0}};
            interupt_done <= 1'b0;
        end
        else
        begin

            case(state)

            //-----------------------------------------
            // IDLE
            //-----------------------------------------

            IDLE:
            begin

                irq_o <= 1'b0;

                if(arb_irq_valid)
                begin
                    interupt_done <=1'b0;
                    irq_o    <= 1'b1;
                    irq_id_o <= arb_irq_id;
                    state    <= ASSERT_IRQ;
                end

            end

            //-----------------------------------------
            // ASSERT_IRQ
            //-----------------------------------------

            ASSERT_IRQ:
            begin

                irq_o <= 1'b1;
                if(irq_ack_i)
                begin
                    irq_o <= 1'b0;
                    state <= WAIT_RELEASE;
                end

            end
				
			//-----------------------------------------
            // WAIT_RELEASE
            //-----------------------------------------
            WAIT_RELEASE:
            begin
                irq_o <=1'b0;
                if (irq_i[arb_irq_id] == 0)
                    begin
                        interupt_done <=1'b1;
                        state <= DONE;
                    end
            end

            DONE:
            begin
                interupt_done <=1'b0;
                state <=IDLE;
            end
				
				default : state <=IDLE;
            endcase

        end
    end

endmodule