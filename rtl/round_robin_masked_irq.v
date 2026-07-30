module round_robin_masked_irq
#(
    parameter SLV_AMT    = 4,
    parameter SLV_ID_W   = $clog2(SLV_AMT),
    parameter PRIORITY_W = 3
)(
    input wire      clk,
    input wire      rst_n,

    input wire      pending_irq_i,
    input wire      irq_en_i,
    input wire      selected_i,
    //input wire      selected_en_i,
    input wire      interupt_done_i,
    input wire      controler_free_i,
    
    output [SLV_ID_W :0]  counter_block_o,
    output reg         masked_irq_o
);

    //--------------------------------------------------------------
    // FSM state
    //--------------------------------------------------------------
    localparam BYPASS     = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam BLOCK      = 2'b10;

    reg [1:0] state_r;
    

    //--------------------------------------------------------------
    // Counter
    //
    // Counter needs to represent SLV_AMT.
    // Example:
    // SLV_AMT = 4
    // SLV_ID_W = 2
    // counter needs 3 bits to represent 0..4
    //--------------------------------------------------------------
    reg [SLV_ID_W:0] counter_r;

    //--------------------------------------------------------------
    // Output
    //--------------------------------------------------------------
    assign counter_block_o = counter_r[SLV_ID_W:0];

    // assign masked_irq_o =   (state_r == BYPASS) ? (pending_irq_i & irq_en_i) :
    //                         (state_r == PROCESSING) ? 1'b1 : 1'b0;
    //                         //(state_r == BLOCK && controler_free_i == 1'b1)? (pending_irq_i & irq_en_i): 1'b0;


    //--------------------------------------------------------------
    // State and counter sequential logic
    //--------------------------------------------------------------


    //--------------------------------------------------------------
    // FSM next-state and counter logic
    //--------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state_r   <= BYPASS;
            counter_r <= {(SLV_ID_W){1'b0}};
        end
        else
        begin
            case (state_r)

                //----------------------------------------------------------
                // BYPASS
                //
                // Interrupt is allowed to enter arbiter.
                //----------------------------------------------------------
                BYPASS: begin
                    
                    if (selected_i) begin
                        state_r <= PROCESSING;
                        masked_irq_o <=1'b1;
                    end 
                    else
                    begin
                        masked_irq_o <= pending_irq_i & irq_en_i;
                    end

                end


                //----------------------------------------------------------
                // PROCESSING
                //
                // Current slave is being serviced.
                // Do not allow this slave to be selected again until
                // its interrupt is completed.
                //----------------------------------------------------------
                PROCESSING: begin
                    
                    if (interupt_done_i) begin

                        // Current interrupt has completed.
                        // Start blocking this slave.
                        counter_r <= {{SLV_ID_W{1'b0}},1'b1};
                        state_r   <= BLOCK;
                        masked_irq_o <=1'b0;
                    end
                    else
                    begin
                        masked_irq_o <=1'b1;
                    end
                end

                //----------------------------------------------------------
                // BLOCK
                //
                // Current slave is temporarily excluded from arbitration.
                //----------------------------------------------------------
                BLOCK: begin

                    // Controller has no other interrupt to process.
                    // Allow this slave to participate again immediately.
                    if (controler_free_i && selected_i) begin

                        counter_r <= {{(SLV_ID_W+1){1'b0}}};
                        state_r   <= BYPASS;
                        masked_irq_o <=pending_irq_i & irq_en_i;
                    end
                    else if (interupt_done_i) begin
                        // One arbitration opportunity has passed.
                        if (counter_r >= SLV_AMT-1) begin

                            // SLV_AMT arbitration opportunities completed.
                            counter_r <= {{(SLV_ID_W+1){1'b0}}};
                            state_r   <= BYPASS;
                            masked_irq_o <=pending_irq_i & irq_en_i;

                        end
                        else begin
                            masked_irq_o <=1'b0;
                            counter_r <= counter_r + 1'b1;
                        end

                    end

                end


                //----------------------------------------------------------
                // Default
                //----------------------------------------------------------
                default: begin
                    state_r   <= BYPASS;
                    counter_r <= {(SLV_ID_W){1'b0}};
                end

            endcase
        end

    end

endmodule
