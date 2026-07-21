module arbiter_priority_irq
#(
    parameter SLV_AMT    = 4,
    parameter SLV_ID_W   = $clog2(SLV_AMT),
    parameter PRIORITY_W = 3
)
(
    input  wire [SLV_AMT-1:0]                 masked_irq_i,
    input  wire [SLV_AMT*PRIORITY_W-1:0]      priority_i,

    output reg                               irq_valid_o,
    output reg [SLV_ID_W-1:0]                irq_slv_id_o
);

    integer i;

    reg [PRIORITY_W-1:0] best_priority;

    always @(*) begin

        irq_valid_o   = 1'b0;
        irq_slv_id_o  = {SLV_ID_W{1'b0}};
        best_priority = {PRIORITY_W{1'b0}};

        //------------------------------------------------------
        // Find highest priority pending interrupt
        //------------------------------------------------------
        for (i = 0; i < SLV_AMT; i = i + 1) begin

            if (masked_irq_i[i]) begin

                if (!irq_valid_o) begin
                    irq_valid_o   = 1'b1;
                    irq_slv_id_o  = i[SLV_ID_W-1:0];
                    best_priority = priority_i[i*PRIORITY_W +: PRIORITY_W];
                end
                else if (priority_i[i*PRIORITY_W +: PRIORITY_W] > best_priority) begin
                    irq_slv_id_o  = i[SLV_ID_W-1:0];
                    best_priority = priority_i[i*PRIORITY_W +: PRIORITY_W];
                end

            end

        end

    end

endmodule