module irq_pending
#(
    parameter SLV_AMT  = 4,
    parameter SLV_ID_W = $clog2(SLV_AMT)
)
(
    input  wire                     clk_i,
    input  wire                     rst_n_i,

    //------------------------------------------
    // Interrupt request from slaves
    //------------------------------------------
    input  wire [SLV_AMT-1:0]       irq_i,

    //------------------------------------------
    // Pending interrupt
    //------------------------------------------
    output wire [SLV_AMT-1:0]       pending_o
);

    //----------------------------------------------------------
    // Pending Register
    //----------------------------------------------------------

    reg [SLV_AMT-1:0] pending_r;

    integer i;

    always @(posedge clk_i or negedge rst_n_i)
    begin
        if (!rst_n_i)
        begin
            pending_r <= {SLV_AMT{1'b0}};
        end
        else
        begin

            //--------------------------------------------------
            // Store every interrupt request
            //--------------------------------------------------
            pending_r <= irq_i;
            
        end
    end

    assign pending_o = pending_r;

endmodule