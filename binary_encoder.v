module binary_encoder #(
    parameter INPUT_WIDTH = 8,
    parameter OUTPUT_WIDTH = $clog2(INPUT_WIDTH)
)(
    input  wire [INPUT_WIDTH-1:0] one_hot,

    output reg  [OUTPUT_WIDTH-1:0] binary,
    output wire                    valid
);

integer i;

always @(*) begin
    binary = {OUTPUT_WIDTH{1'b0}};

    for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
        if (one_hot[i])
            binary = i[OUTPUT_WIDTH-1:0];
    end
end

assign valid = |one_hot;

endmodule