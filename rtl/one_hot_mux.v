module one_hot_mux #(
    parameter N          = 4,  // Number of input ports (and width of one-hot sel)
    parameter DATA_WIDTH = 8   // Width of each data bus
) (
    // Input: Flattened vector containing N ports, total width = N * DATA_WIDTH
    input  wire [(N*DATA_WIDTH)-1:0] data_in,
    input  wire [N-1:0]              sel,      // One-hot select signal
    
    output reg  [DATA_WIDTH-1:0]     data_out  // Selected data output
);

    integer i;

    always @(*) begin
        // Initialize output to 0
        data_out = {DATA_WIDTH{1'bx}};
        
        // Loop through all N input channels
        for (i = 0; i < N; i = i + 1) begin
            // 1. {DATA_WIDTH{sel[i]}} replicates the 1-bit sel into a mask of DATA_WIDTH
            // 2. Bitwise AND (&) filters out the data if sel[i] is 0
            // 3. Bitwise OR (|) accumulates the active channel into data_out
            data_out = data_out | ({DATA_WIDTH{sel[i]}} & data_in[i*DATA_WIDTH +: DATA_WIDTH]);
        end
    end

endmodule