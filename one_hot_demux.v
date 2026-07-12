module one_hot_demux #(
    parameter N          = 4,  // Number of output ports (and width of the one-hot sel)
    parameter DATA_WIDTH = 8   // Width of the data bus
) (
    input  wire [DATA_WIDTH-1:0]       data_in,  // Input data to be routed
    input  wire [N-1:0]                sel,      // One-hot select signal
    
    // Output: Flattened vector containing N ports, total width = N * DATA_WIDTH
    output wire [(N*DATA_WIDTH)-1:0]   data_out
);

    // Generate block to spawn parallel masking logic for each output port
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_demux_lanes
            // If the i-th bit of 'sel' is high, route 'data_in' to the i-th output slot.
            // Otherwise, drive the i-th output slot to 0.
            assign data_out[i*DATA_WIDTH +: DATA_WIDTH] = sel[i] ? data_in : {DATA_WIDTH{1'b0}};
        end
    endgenerate

endmodule