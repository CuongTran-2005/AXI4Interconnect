module fifo
#(
    parameter  DATA_WIDTH    = 120,
    parameter  FIFO_DEPTH    = 32,
    // Do not configure
    parameter  ADDR_WIDTH    = $clog2(FIFO_DEPTH)
)
(
    input                       clk,
    
    input   [DATA_WIDTH - 1:0]  data_i,
    output  [DATA_WIDTH - 1:0]  data_o,
    
    input                       wr_valid_i,
    input                       rd_valid_i,
    
    output                      empty_o,
    output                      full_o,
    output                      almost_empty_o,
    output                      almost_full_o,
    
    output  [ADDR_WIDTH:0]      counter,
    input                       rst_n
    );

    // Bo nho FIFO
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // Con tro doc/ghi
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0]   cnt;

    wire wr_en = wr_valid_i && !full_o;
    wire rd_en = rd_valid_i && !empty_o;

    // Ghi
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (wr_en) begin
            mem[wr_ptr] <= data_i;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    // Doc - con tro chi nhay khi thuc su pop (rd_en)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= 0;
        else if (rd_en)
            rd_ptr <= rd_ptr + 1'b1;
    end

    // Bo dem so phan tu
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else case ({wr_en, rd_en})
            2'b10:   cnt <= cnt + 1'b1;
            2'b01:   cnt <= cnt - 1'b1;
            default: cnt <= cnt;
        endcase
    end

    // FWFT: data_o la to hop, luon "lo" san du lieu dau hang doi
    // khi FIFO khong rong, khong can doi them chu ky sau rd_valid_i.
    assign data_o  = mem[rd_ptr];
    assign counter = cnt;

    assign empty_o = (cnt == 0);
    assign full_o  = (cnt == FIFO_DEPTH);

    assign almost_empty_o = (cnt == 1);
    assign almost_full_o  = (cnt == FIFO_DEPTH - 1);

endmodule

// // // Old version FIFO
// // module fifo
// // #(
// //     parameter  DATA_WIDTH    = 8,
// //     parameter  FIFO_DEPTH    = 32,
// //     // Do not configure
// //     parameter  ADDR_WIDTH    = $clog2(FIFO_DEPTH)
// // )
// // (
// //     input                       clk,
    
// //     input   [DATA_WIDTH - 1:0]  data_i,
// //     output  [DATA_WIDTH - 1:0]  data_o,
    
// //     input                       wr_valid_i,
// //     input                       rd_valid_i,
    
// //     output                      empty_o,
// //     output                      full_o,
// //     output                      almost_empty_o,
// //     output                      almost_full_o,
    
// //     output  [ADDR_WIDTH:0]      counter,
// //     input                       rst_n
// //     );
// //     // Internal variable declaration
// //     genvar addr;
    
// //     // Internal signal declaration
// //     // wire declaration
// //     wire[ADDR_WIDTH:0]      wr_addr_inc;
// //     wire[ADDR_WIDTH - 1:0]  wr_addr_map;
// //     wire[ADDR_WIDTH:0]      rd_addr_inc;
// //     wire[ADDR_WIDTH - 1:0]  rd_addr_map;
// //     wire[DATA_WIDTH - 1:0]  buffer_nxt [0:FIFO_DEPTH - 1];
// //     // reg declaration
// // 	reg [DATA_WIDTH - 1:0]  buffer     [0:FIFO_DEPTH - 1];
// // 	reg [ADDR_WIDTH:0]      wr_addr;
// //     reg [ADDR_WIDTH:0]      rd_addr;
    
// //     // combinational logic
// //     assign data_o = buffer[rd_addr_map];
    
// //     assign wr_addr_inc = wr_addr + 1'b1;
// //     assign rd_addr_inc = rd_addr + 1'b1;
// //     assign wr_addr_map = wr_addr[ADDR_WIDTH - 1:0];
// //     assign rd_addr_map = rd_addr[ADDR_WIDTH - 1:0];
    
// //     assign empty_o = wr_addr == rd_addr;
// //     assign almost_empty_o = rd_addr_inc ==  wr_addr;
// //     assign full_o = (wr_addr_map == rd_addr_map) & (wr_addr[ADDR_WIDTH] ^ rd_addr[ADDR_WIDTH]);
// //     assign almost_full_o = wr_addr_map + 1'b1 == rd_addr_map;
    
// //     assign counter = wr_addr - rd_addr;
// //     generate
// //         for(addr = 0; addr < FIFO_DEPTH; addr = addr + 1) begin : BUF_NXT_GEN
// //             assign buffer_nxt[addr] = (wr_addr_map == addr) ? data_i : buffer[addr];
// //         end
// //     endgenerate
    
// //     // flip-flop logic
// //     // -- Buffer updater
// //     generate
// //         for(addr = 0; addr < FIFO_DEPTH; addr = addr + 1) begin : BUF_LOAD
// //             always @(posedge clk) begin
// //                 if(!rst_n) begin 
// //                     buffer[addr] <= {DATA_WIDTH{1'b0}};
// //                 end
// //                 else if(wr_valid_i & !full_o) begin
// //                     buffer[addr] <= buffer_nxt[addr];
// //                 end
// //             end
// //         end
// //     endgenerate
// //     // -- Write pointer updater
// //     always @(posedge clk) begin
// //         if(!rst_n) begin 
// //             wr_addr <= 0;        
// //         end
// //         else if(wr_valid_i & !full_o) begin
// //             wr_addr <= wr_addr_inc;
// //         end
// //     end
// //     // -- Read pointer updater
// //     always @(posedge clk) begin
// //         if(!rst_n) begin
// //             rd_addr <= 0;
// //         end
// //         else if(rd_valid_i & !empty_o) begin
// //             rd_addr <= rd_addr_inc;
// //         end
        
// //     end
// // endmodule
// // //    fifo 
// // //        #(
// // //        .DATA_WIDTH(),
// // //        .FIFO_DEPTH(32)
// // //        ) fifo (
// // //        .clk(clk),
// // //        .data_i(),
// // //        .data_o(),
// // //        .rd_valid_i(),
// // //        .wr_valid_i(),
// // //        .empty_o(),
// // //        .full_o(),
// // //        .almost_empty_o(),
// // //        .almost_full_o(),
// // //        .rst_n(rst_n)
// // //        );

// module fifo
// #(
//     parameter  DATA_WIDTH    = 120,
//     parameter  FIFO_DEPTH    = 32,
//     // Do not configure
//     parameter  ADDR_WIDTH    = $clog2(FIFO_DEPTH)
// )
// (
//     input                       clk,
    
//     input   [DATA_WIDTH - 1:0]  data_i,
//     output  [DATA_WIDTH - 1:0]  data_o,
    
//     input                       wr_valid_i,
//     input                       rd_valid_i,
    
//     output                      empty_o,
//     output                      full_o,
//     output                      almost_empty_o,
//     output                      almost_full_o,
    
//     output  [ADDR_WIDTH:0]      counter,
//     input                       rst_n
//     );

//     // Bo nho FIFO
//     reg [DATA_WIDTH *FIFO_DEPTH-1:0] mem;

//     // Con tro doc/ghi
//     reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
//     reg [ADDR_WIDTH:0]   cnt;

//     wire wr_en = wr_valid_i && !full_o;
//     wire rd_en = rd_valid_i && !empty_o;

//     // Ghi
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n)
//             wr_ptr <= 0;
//         else if (wr_en) begin
//             mem[wr_ptr * DATA_WIDTH -1 +: DATA_WIDTH] <= data_i;
//             wr_ptr      <= wr_ptr + 1'b1;
//         end
//     end

//     // Doc - con tro chi nhay khi thuc su pop (rd_en)
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n)
//             rd_ptr <= 0;
//         else if (rd_en)
//             rd_ptr <= rd_ptr + 1'b1;
//     end

//     // Bo dem so phan tu
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n)
//             cnt <= 0;
//         else case ({wr_en, rd_en})
//             2'b10:   cnt <= cnt + 1'b1;
//             2'b01:   cnt <= cnt - 1'b1;
//             default: cnt <= cnt;
//         endcase
//     end

//     // FWFT: data_o la to hop, luon "lo" san du lieu dau hang doi
//     // khi FIFO khong rong, khong can doi them chu ky sau rd_valid_i.
//     assign data_o  = mem[rd_ptr *DATA_WIDTH-1 +: DATA_WIDTH];
//     assign counter = cnt;

//     assign empty_o = (cnt == 0);
//     assign full_o  = (cnt == FIFO_DEPTH);

//     assign almost_empty_o = (cnt == 1);
//     assign almost_full_o  = (cnt == FIFO_DEPTH - 1);

// endmodule