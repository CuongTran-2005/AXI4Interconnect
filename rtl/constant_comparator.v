module constant_comparator #(
    parameter DATA_WIDTH = 8,                           // Width of the input data
    parameter [DATA_WIDTH-1:0] COMP_VAL = {DATA_WIDTH{1'b0}} // The pre-configured constant (defaults to 0)
) (
    input  wire [DATA_WIDTH-1:0] data_in,               // Input to be checked
    output wire                  equal                  // 1 if equal, 0 otherwise
);

    // Continuous assignment handles the equality check.
    // Synthesizes to an XNOR-AND chain or an optimized LUT structure.
    assign equal = (data_in == COMP_VAL);

endmodule