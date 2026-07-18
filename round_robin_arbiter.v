module round_robin_arbiter #(
    parameter REQUESTER_NUM = 4,
    parameter MODE = 0               // 0: Default, 1: Look-Ahead
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [REQUESTER_NUM-1:0]     request,
    input  wire                         enable,

    output wire [REQUESTER_NUM-1:0]     grant,
    output wire [REQUESTER_NUM-1:0]     next_grant,
    output wire                         slv_req
);

localparam MODE_DEFAULT   = 0;
localparam MODE_LOOKAHEAD = 1;

generate

//======================================================================
// Default Round-Robin Arbiter
//======================================================================
if (MODE == MODE_DEFAULT) begin : GEN_DEFAULT

    reg  [REQUESTER_NUM-1:0] grant_reg;

    wire [REQUESTER_NUM-1:0] mask;
    wire [REQUESTER_NUM-1:0] req_masked;
    wire [REQUESTER_NUM-1:0] grant_masked;
    wire [REQUESTER_NUM-1:0] grant_unmasked;
    wire [REQUESTER_NUM-1:0] next_grant_int;

    //--------------------------------------------------------------
    // Round-robin combinational logic
    //--------------------------------------------------------------

    assign mask           = ~((grant_reg << 1) - 1'b1);
    assign req_masked     = request & mask;
    assign grant_masked   = req_masked & (-req_masked);
    assign grant_unmasked = request & (-request);

    assign next_grant_int =
                (|req_masked) ?
                grant_masked :
                grant_unmasked;

    //--------------------------------------------------------------
    // Sequential update
    //--------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            grant_reg <= {REQUESTER_NUM{1'b0}};
        else if(enable)
            grant_reg <= next_grant_int;
    end

    //--------------------------------------------------------------
    // Outputs
    //--------------------------------------------------------------

    assign grant      = grant_reg;
    assign next_grant = next_grant_int;
    assign slv_req    = |(grant_reg & request);

end

//======================================================================
// Look-Ahead Round-Robin Arbiter
//======================================================================
else begin : GEN_LOOKAHEAD

    //--------------------------------------------------------------
    // Reg & Wire declarations (Đã khôi phục khai báo bị thiếu)
    //--------------------------------------------------------------
    reg [REQUESTER_NUM-1:0] pointer;
    reg [REQUESTER_NUM-1:0] grant_reg;

    wire [REQUESTER_NUM-1:0] mask;
    wire [REQUESTER_NUM-1:0] req_masked;
    wire [REQUESTER_NUM-1:0] grant_masked;
    wire [REQUESTER_NUM-1:0] grant_unmasked;
    wire [REQUESTER_NUM-1:0] arb_result;
    wire [REQUESTER_NUM-1:0] current_base;

    //--------------------------------------------------------------
    // Combinational arbitration logic
    //--------------------------------------------------------------
    assign current_base   = (grant_reg != {REQUESTER_NUM{1'b0}}) ? grant_reg : pointer;
    assign mask           = ~((current_base << 1) - 1'b1);

    assign req_masked     = request & mask;
    assign grant_masked   = req_masked & (-req_masked);
    assign grant_unmasked = request & (-request);

    assign arb_result     = (|req_masked) ? grant_masked : grant_unmasked;

    //--------------------------------------------------------------
    // Outputs
    //--------------------------------------------------------------
    assign grant      = (grant_reg == {REQUESTER_NUM{1'b0}}) ? arb_result : grant_reg;
    assign next_grant = arb_result;
    assign slv_req    = |(grant & request);

    //--------------------------------------------------------------
    // Sequential logic
    //--------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pointer   <= {REQUESTER_NUM{1'b0}};
            grant_reg <= {REQUESTER_NUM{1'b0}};
        end
        else begin
            if (grant_reg == {REQUESTER_NUM{1'b0}}) begin
                if (arb_result != {REQUESTER_NUM{1'b0}}) begin
                    if (enable) begin
                        pointer   <= arb_result; 
                        grant_reg <= {REQUESTER_NUM{1'b0}}; 
                    end else begin
                        grant_reg <= arb_result; 
                    end
                end
            end
            else begin
                if (enable) begin
                    pointer <= grant_reg; 
                    if (arb_result != {REQUESTER_NUM{1'b0}} && |(request & ~grant_reg)) 
                        grant_reg <= arb_result;
                    else
                        grant_reg <= {REQUESTER_NUM{1'b0}};
                end
            end
        end
    end

end 
endgenerate

endmodule