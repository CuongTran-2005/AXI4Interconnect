module round_robin_arbiter #(
    parameter REQUESTER_NUM = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [REQUESTER_NUM-1:0] request,
    input  wire                     enable,
    output reg  [REQUESTER_NUM-1:0] grant,
    output wire [REQUESTER_NUM-1:0] next_grant,
    output wire                     slv_req    
);

    wire [REQUESTER_NUM-1:0] mask;
    wire [REQUESTER_NUM-1:0] req_masked;
    wire [REQUESTER_NUM-1:0] grant_masked;
    wire [REQUESTER_NUM-1:0] grant_unmasked;
    wire [REQUESTER_NUM-1:0] next_grant_val;

    assign mask = ~((grant << 1) - 1'b1);
    assign req_masked = request & mask;
    assign grant_masked   = req_masked & (-req_masked);
    assign grant_unmasked = request & (-request);
    assign next_grant_val = (|req_masked) ? grant_masked : grant_unmasked;
    assign next_grant = next_grant_val;
    assign slv_req = |(request & grant);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= {REQUESTER_NUM{1'b0}};
        end else if (enable) begin
            grant <= next_grant_val;
        end
    end

endmodule