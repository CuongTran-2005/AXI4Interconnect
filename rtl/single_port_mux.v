module single_port_mux #(
    parameter SEL_WIDTH  = 2, 
    parameter N          = 2**SEL_WIDTH, 
    parameter DATA_WIDTH = 2  
) (
    input  wire [(N * DATA_WIDTH)-1:0] data_in,
    input  wire [SEL_WIDTH-1:0]        sel,
    output reg  [DATA_WIDTH-1:0]       out
);

    always @(*) begin
        if (sel < N) begin
            out = data_in[(sel * DATA_WIDTH) +: DATA_WIDTH];
        end else begin
            out = {DATA_WIDTH{1'bx}};
        end
    end

endmodule