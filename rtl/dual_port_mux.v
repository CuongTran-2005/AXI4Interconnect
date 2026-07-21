module dual_port_mux #(
    parameter SEL_WIDTH  = 2, 
    parameter N          = 4, 
    parameter DATA_WIDTH = 2  
) (
    input  wire [(N * DATA_WIDTH)-1:0] data_in,
    
    input  wire [SEL_WIDTH-1:0]        sel_0,
    input  wire [SEL_WIDTH-1:0]        sel_1,
    
   
    output wire [DATA_WIDTH-1:0]       out_0,
    output wire [DATA_WIDTH-1:0]       out_1
);

    single_port_mux #(
        .SEL_WIDTH(SEL_WIDTH),
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) mux_inst_0 (
        .data_in (data_in),
        .sel     (sel_0),
        .out     (out_0)
    );

    single_port_mux #(
        .SEL_WIDTH(SEL_WIDTH),
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) mux_inst_1 (
        .data_in (data_in),
        .sel     (sel_1),
        .out     (out_1)
    );

endmodule