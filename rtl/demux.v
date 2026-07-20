module demux #(
    parameter SEL_WIDTH  = 2, // Width of the binary select signal
    parameter DATA_WIDTH = 8  // Width of the data bus
) (
    input  wire [DATA_WIDTH-1:0]                  data_in,
    input  wire [SEL_WIDTH-1:0]                   sel,
    
    // Output is a flattened vector of 2^SEL_WIDTH ports
    output reg  [((1<<SEL_WIDTH)*DATA_WIDTH)-1:0] data_out
);

    // Calculate the total number of output ports (N = 2^SEL_WIDTH)
    localparam N = 1 << SEL_WIDTH;

    always @(*) begin
        // 1. Initialize all output ports to 0 to prevent unwanted latches
        data_out = {(N * DATA_WIDTH){1'b0}};
        
        // 2. Route the input data to the specifically selected port
        // The unselected ports will naturally remain 0 due to the initialization above
        data_out[sel * DATA_WIDTH +: DATA_WIDTH] = data_in;
    end

endmodule