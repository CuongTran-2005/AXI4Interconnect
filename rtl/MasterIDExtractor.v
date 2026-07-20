`timescale 1ns / 1ps

module MasterIDExtractor #(
    parameter ID_WIDTH = 5,
    parameter MST_ID_WIDTH = 2
)
(
    input wire [ID_WIDTH-1:0] id_i,
    output reg [MST_ID_WIDTH-1:0] mst_id_o 
);

    always @(*) begin
        mst_id_o = id_i[ID_WIDTH-1 -: MST_ID_WIDTH];
    end
    
endmodule