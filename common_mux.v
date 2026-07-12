module common_mux #(
    parameter DATA_WIDTH = 10,
    parameter OUT_AMT    = 4,
    parameter SEL_WIDTH  = $clog2(OUT_AMT)
)
(
    input  wire [DATA_WIDTH*OUT_AMT-1:0] data_i,
    input  wire [SEL_WIDTH-1:0]          sel_i,
    output reg  [DATA_WIDTH-1:0]         data_o
);

always @(*) begin
    if(sel_i < OUT_AMT)
        data_o = data_i[sel_i*DATA_WIDTH +: DATA_WIDTH];
    else
        data_o = 1'b0;
end

endmodule