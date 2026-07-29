module controller_free_select #(
    parameter SLV_AMT  = 4,
    parameter SLV_ID_W = (SLV_AMT > 1) ? $clog2(SLV_AMT) : 1
)(
    input wire [SLV_ID_W*SLV_AMT-1:0] counter_block,
    input wire [SLV_AMT-1:0]         masked_irq,
    input wire [SLV_AMT-1:0]         pending_irq,
    output reg [SLV_AMT-1:0]         controler_free
);

    integer i;

    reg [SLV_ID_W-1:0] max_counter;
    reg [SLV_ID_W-1:0] counter_tmp;
    reg                 masked_irq_exist;

    always @(*) begin

        //----------------------------------------------------------
        // Default
        //----------------------------------------------------------
        controler_free   = {SLV_AMT{1'b0}};
        max_counter      = {SLV_ID_W{1'b0}};
        counter_tmp      = {SLV_ID_W{1'b0}};
        masked_irq_exist = 1'b0;


        //----------------------------------------------------------
        // Check whether any masked IRQ is active
        //----------------------------------------------------------
        for (i = 0; i < SLV_AMT; i = i + 1) begin

            if (masked_irq[i])
                masked_irq_exist = 1'b1;

        end


        //----------------------------------------------------------
        // If no masked IRQ is active:
        // Find the pending slave with the highest counter.
        //----------------------------------------------------------
        if (!masked_irq_exist) begin

            for (i = 0; i < SLV_AMT; i = i + 1) begin

                if (pending_irq[i]) begin

                    // Extract counter of slave i
                    counter_tmp = counter_block[
                        i*SLV_ID_W +: SLV_ID_W
                    ];

                    if (counter_tmp >= max_counter) begin

                        max_counter = counter_tmp;

                        // One-hot selection
                        controler_free = {SLV_AMT{1'b0}};
                        controler_free[i] = 1'b1;

                    end

                end

            end

        end

    end

endmodule