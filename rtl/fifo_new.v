// // =============================================================================
// // fifo_top.v
// // -----------------------------------------------------------------------------
// // FIFO tu viet lai (behavioral RTL), thay the cho IP fifo_generator_0 do Vivado
// // sinh ra. Gom toan bo chuc nang vao 1 file .v duy nhat de de chinh sua,
// // khong phu thuoc thu vien IP cua Xilinx (khong can .xci, khong can glbl,
// // khong can simulation library rieng).
// //
// // Cau hinh duoc suy ra tu file fifo_generator_0_stub.v / .vho ban da generate:
// //   - Interface        : Native FIFO (khong phai AXI-Stream, du IP co bat AXI)
// //   - C_DIN_WIDTH       = 32   -> DATA_WIDTH
// //   - C_DOUT_WIDTH      = 32
// //   - C_WR_DEPTH        = 1024 -> DEPTH
// //   - C_RD_DEPTH        = 1024
// //   - C_WR_PNTR_WIDTH   = 10   -> ADDR_WIDTH
// //   - C_COMMON_CLOCK    = 1    -> 1 clock duy nhat cho ca write/read
// //   - C_MEMORY_TYPE     = 1    -> Block RAM
// //   - C_PRELOAD_REGS=1, C_PRELOAD_LATENCY=0 -> First-Word-Fall-Through (FWFT)
// //   - C_HAS_RST=1, C_HAS_SRST=0             -> 1 ngo vao "rst" (asynchronous-ish,
// //                                              duoc dong bo hoa noi bo)
// //   - C_EN_SAFETY_CKT=1, C_SYNCHRONIZER_STAGE=2 -> co wr_rst_busy / rd_rst_busy
// //   - Khong bat: almost_full/empty, prog_full/empty, data_count, overflow,
// //                underflow, wr_ack, ECC  (giu nguyen vi ban khong dung)
// //
// // Port list giong het fifo_generator_0_stub.v de co the thay the truc tiep
// // (drop-in replacement) cho module IP cu.
// // =============================================================================

// `timescale 1ns / 1ps

// module fifo_new #(
//     parameter DATA_WIDTH = 128,   // = C_DIN_WIDTH = C_DOUT_WIDTH
//     parameter DEPTH      = 32, // = C_WR_DEPTH  = C_RD_DEPTH
//     parameter ADDR_WIDTH = 5    // = clog2(DEPTH), = C_WR_PNTR_WIDTH
// )(
//     input  wire                   clk,
//     input  wire                   rst,          // active-high, giu >= vai chu ky de reset het

//     // Write side
//     input  wire [DATA_WIDTH-1:0]  din,
//     input  wire                   wr_en,
//     output wire                   full,

//     // Read side (FWFT: dout hop le ngay khi empty=0, khong can cho 1 chu ky)
//     input  wire                   rd_en,
//     output wire [DATA_WIDTH-1:0]  dout,
//     output wire                   empty,

//     // Safety-circuit reset-busy flags (giong ban goc khi C_EN_SAFETY_CKT=1)
//     output wire                   wr_rst_busy,
//     output wire                   rd_rst_busy
// );

//     // -------------------------------------------------------------------
//     // Reset synchronizer + "busy" generator
//     // Mo phong hanh vi cua IP goc: khi rst len 1, FIFO can vai chu ky de
//     // thuc su reset xong (busy=1), va wr_en/rd_en bi bo qua trong luc do.
//     // -------------------------------------------------------------------
//     localparam RST_BUSY_CYCLES = 4; // du de xoa pointer/flag, co the tang neu can

//     reg [2:0] rst_busy_cnt;
//     reg       rst_busy_r;

//     always @(posedge clk) begin
//         if (rst) begin
//             rst_busy_cnt <= RST_BUSY_CYCLES[2:0];
//             rst_busy_r   <= 1'b1;
//         end else if (rst_busy_cnt != 0) begin
//             rst_busy_cnt <= rst_busy_cnt - 1'b1;
//             rst_busy_r   <= 1'b1;
//         end else begin
//             rst_busy_r   <= 1'b0;
//         end
//     end

//     assign wr_rst_busy = rst_busy_r;
//     assign rd_rst_busy = rst_busy_r;

//     wire internal_rst = rst | rst_busy_r;

//     // -------------------------------------------------------------------
//     // Bo nho FIFO (suy luan thanh Block RAM khi tong hop, giong C_MEMORY_TYPE=1)
//     // -------------------------------------------------------------------
//     reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

//     reg [ADDR_WIDTH-1:0] wr_ptr;
//     reg [ADDR_WIDTH-1:0] rd_ptr;
//     reg [ADDR_WIDTH:0]   fifo_cnt; // rong hon 1 bit de dem toi DEPTH

//     wire wr_valid = wr_en & ~full  & ~internal_rst;
//     wire rd_valid = rd_en & ~empty & ~internal_rst;

//     // ---- Write pointer + bo nho ----
//     always @(posedge clk) begin
//         if (internal_rst) begin
//             wr_ptr <= {ADDR_WIDTH{1'b0}};
//         end else if (wr_valid) begin
//             mem[wr_ptr] <= din;
//             wr_ptr      <= wr_ptr + 1'b1;
//         end
//     end

//     // ---- Read pointer ----
//     always @(posedge clk) begin
//         if (internal_rst) begin
//             rd_ptr <= {ADDR_WIDTH{1'b0}};
//         end else if (rd_valid) begin
//             rd_ptr <= rd_ptr + 1'b1;
//         end
//     end

//     // ---- Bo dem so phan tu trong FIFO -> sinh full/empty ----
//     always @(posedge clk) begin
//         if (internal_rst) begin
//             fifo_cnt <= {(ADDR_WIDTH+1){1'b0}};
//         end else begin
//             case ({wr_valid, rd_valid})
//                 2'b10:   fifo_cnt <= fifo_cnt + 1'b1;
//                 2'b01:   fifo_cnt <= fifo_cnt - 1'b1;
//                 default: fifo_cnt <= fifo_cnt; // 00 hoac 11: khong doi
//             endcase
//         end
//     end

//     assign full  = (fifo_cnt == DEPTH[ADDR_WIDTH:0]);
//     assign empty = (fifo_cnt == 0);

//     // ---- Du lieu dau ra kieu FWFT ----
//     // Doc thang (combinational) tu mem theo rd_ptr: dout luon la gia tri
//     // hop le cua phan tu dau FIFO ngay khi empty=0, khong lech chu ky nao
//     // so voi co empty (dung ban chat First-Word-Fall-Through). Day la cach
//     // don gian, de doc/de sua nhat cho 1 file gop; tong hop se suy ra BRAM
//     // co output-mux/bo doc bat dong bo tuong duong hanh vi IP goc.
//     assign dout = mem[rd_ptr];

// endmodule




// =============================================================================
// fifo_top.v
// -----------------------------------------------------------------------------
// FIFO tu viet lai (behavioral RTL), thay the cho IP fifo_generator_0 do Vivado
// sinh ra. Gom toan bo chuc nang vao 1 file .v duy nhat de de chinh sua,
// khong phu thuoc thu vien IP cua Xilinx (khong can .xci, khong can glbl,
// khong can simulation library rieng).
//
// Cau hinh duoc suy ra tu file fifo_generator_0_stub.v / .vho ban da generate:
//   - Interface        : Native FIFO (khong phai AXI-Stream, du IP co bat AXI)
//   - C_DIN_WIDTH       = 32   -> DATA_WIDTH
//   - C_DOUT_WIDTH      = 32
//   - C_WR_DEPTH        = 1024 -> DEPTH
//   - C_RD_DEPTH        = 1024
//   - C_WR_PNTR_WIDTH   = 10   -> ADDR_WIDTH
//   - C_COMMON_CLOCK    = 1    -> 1 clock duy nhat cho ca write/read
//   - C_MEMORY_TYPE     = 1    -> Block RAM
//   - C_PRELOAD_REGS=1, C_PRELOAD_LATENCY=0 -> First-Word-Fall-Through (FWFT)
//   - C_HAS_RST=1, C_HAS_SRST=0             -> 1 ngo vao "rst_n" (active-low,
//                                              duoc dong bo hoa noi bo)
//   - C_EN_SAFETY_CKT=1, C_SYNCHRONIZER_STAGE=2 -> co wr_rst_busy / rd_rst_busy
//   - Khong bat: almost_full/empty, prog_full/empty, data_count, overflow,
//                underflow, wr_ack, ECC  (giu nguyen vi ban khong dung)
//
// Port list giong het fifo_generator_0_stub.v (tru rst -> rst_n, active-low)
// de co the thay the truc tiep (drop-in replacement) cho module IP cu.
// =============================================================================

`timescale 1ns / 1ps

module fifo_new #(
    parameter DATA_WIDTH = 128,   // = C_DIN_WIDTH = C_DOUT_WIDTH
    parameter DEPTH      = 32, // = C_WR_DEPTH  = C_RD_DEPTH
    parameter ADDR_WIDTH = 5    // = clog2(DEPTH), = C_WR_PNTR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst_n,        // active-low, giu = 0 vai chu ky de reset het

    // Write side
    input  wire [DATA_WIDTH-1:0]  din,
    input  wire                   wr_en,
    output wire                   full_o,

    // Read side (FWFT: dout hop le ngay khi empty=0, khong can cho 1 chu ky)
    input  wire                   rd_en,
    output wire [DATA_WIDTH-1:0]  dout,
    output wire                   empty_o,

    // Safety-circuit reset-busy flags (giong ban goc khi C_EN_SAFETY_CKT=1)
    output wire                   wr_rst_busy,
    output wire                   rd_rst_busy
);

    // -------------------------------------------------------------------
    // Reset synchronizer + "busy" generator
    // Mo phong hanh vi cua IP goc: khi rst_n xuong 0, FIFO can vai chu ky de
    // thuc su reset xong (busy=1), va wr_en/rd_en bi bo qua trong luc do.
    // -------------------------------------------------------------------
    localparam RST_BUSY_CYCLES = 4; // du de xoa pointer/flag, co the tang neu can

    reg [2:0] rst_busy_cnt;
    reg       rst_busy_r;

    always @(posedge clk) begin
        if (!rst_n) begin
            rst_busy_cnt <= RST_BUSY_CYCLES[2:0];
            rst_busy_r   <= 1'b1;
        end else if (rst_busy_cnt != 0) begin
            rst_busy_cnt <= rst_busy_cnt - 1'b1;
            rst_busy_r   <= 1'b1;
        end else begin
            rst_busy_r   <= 1'b0;
        end
    end

    assign wr_rst_busy = rst_busy_r;
    assign rd_rst_busy = rst_busy_r;

    wire internal_rst = (~rst_n) | rst_busy_r;

    // -------------------------------------------------------------------
    // Bo nho FIFO (suy luan thanh Block RAM khi tong hop, giong C_MEMORY_TYPE=1)
    // -------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   fifo_cnt; // rong hon 1 bit de dem toi DEPTH

    wire wr_valid = wr_en & ~full_o  & ~internal_rst;
    wire rd_valid = rd_en & ~empty_o & ~internal_rst;

    // ---- Write pointer + bo nho ----
    always @(posedge clk) begin
        if (internal_rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (wr_valid) begin
            mem[wr_ptr] <= din;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    // ---- Read pointer ----
    always @(posedge clk) begin
        if (internal_rst) begin
            rd_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (rd_valid) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // ---- Bo dem so phan tu trong FIFO -> sinh full/empty ----
    always @(posedge clk) begin
        if (internal_rst) begin
            fifo_cnt <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            case ({wr_valid, rd_valid})
                2'b10:   fifo_cnt <= fifo_cnt + 1'b1;
                2'b01:   fifo_cnt <= fifo_cnt - 1'b1;
                default: fifo_cnt <= fifo_cnt; // 00 hoac 11: khong doi
            endcase
        end
    end

    assign full_o  = (fifo_cnt == DEPTH[ADDR_WIDTH:0]);
    assign empty_o = (fifo_cnt == 0);

    // ---- Du lieu dau ra kieu FWFT ----
    // Doc thang (combinational) tu mem theo rd_ptr: dout luon la gia tri
    // hop le cua phan tu dau FIFO ngay khi empty=0, khong lech chu ky nao
    // so voi co empty (dung ban chat First-Word-Fall-Through). Day la cach
    // don gian, de doc/de sua nhat cho 1 file gop; tong hop se suy ra BRAM
    // co output-mux/bo doc bat dong bo tuong duong hanh vi IP goc.
    assign dout = mem[rd_ptr];

endmodule