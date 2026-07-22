module one_hot_encoder #(
    parameter N_AMT  = 4,
    parameter N_ID_W = $clog2(N_AMT)
)(
    input  wire [N_AMT-1:0] one_hot_grant_i,
    output reg  [N_ID_W-1:0] id_o
);

integer i;
integer count;

always @(*) begin

    id_o  = {N_ID_W{1'bx}};
    count = 0;

    // Detect X/Z
    if (^one_hot_grant_i === 1'bx) begin
        id_o = {N_ID_W{1'bx}};
    end

    else begin

        for (i = 0; i < N_AMT; i = i + 1) begin

            if (one_hot_grant_i[i]) begin
                id_o  = i[N_ID_W-1:0];
                count = count + 1;
            end

        end

        // Không phải one-hot
        if (count != 1)
            id_o = {N_ID_W{1'bx}};

    end

end

endmodule