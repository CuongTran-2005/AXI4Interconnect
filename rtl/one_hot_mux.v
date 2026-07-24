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
        // QUAN TRỌNG: Khởi tạo bằng 0 để tránh lỗi toàn bit đỏ (X) khi mô phỏng
        data_out = {DATA_WIDTH{1'b0}};
        
        // Loop through all N input channels
        for (i = 0; i < N; i = i + 1) begin
            // Sử dụng ánh xạ thuận (i): sel[0] chọn in[0], sel[1] chọn in[1],...
            data_out = data_out | ({DATA_WIDTH{sel[i]}} & data_in[i*DATA_WIDTH +: DATA_WIDTH]);
        end
    end

endmodule