module common_demux #(
    parameter DATA_WIDTH = 10,
    parameter OUT_AMT    = 4,
    parameter SEL_WIDTH  = $clog2(OUT_AMT)
)
(
    input  wire [DATA_WIDTH-1:0]           data_i,
    input  wire [SEL_WIDTH-1:0]            sel_i,
    output wire [DATA_WIDTH*OUT_AMT-1:0]   data_o
);

genvar idx;

generate
    for (idx = 0; idx < OUT_AMT; idx = idx + 1)
    begin : GEN_DEMUX
        assign data_o[idx*DATA_WIDTH +: DATA_WIDTH]= (sel_i == idx) ? data_i : {DATA_WIDTH{1'b0}};
    end
endgenerate

endmodule