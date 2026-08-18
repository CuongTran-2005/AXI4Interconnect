// `timescale 1ns / 1ps

// module sc_fifo_lookahead #(
//     parameter DATA_WIDTH = 120,  // Width of the data bus
//     parameter ADDR_WIDTH = 5   // Depth of FIFO is 2^ADDR_WIDTH
// )(
//     input  wire                  clk,
//     input  wire                  rst_n,
//     input  wire                  wr_en,  // Write Enable
//     input  wire                  rd_en,  // Read Enable
//     input  wire [DATA_WIDTH-1:0] data,   // Data Input
//     output wire [DATA_WIDTH-1:0] q,      // Data Output (Now a wire for look-ahead)
//     output wire                  full,   // FIFO Full Flag
//     output wire                  empty   // FIFO Empty Flag
// );

//     // Calculate depth based on address width
//     localparam DEPTH = 1 << ADDR_WIDTH;

//     // Memory array
//     reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

//     // Pointers with an extra bit for status flags
//     reg [ADDR_WIDTH:0] wr_ptr;
//     reg [ADDR_WIDTH:0] rd_ptr;

//     // -------------------------------------------------------------------------
//     // Status Flags
//     // -------------------------------------------------------------------------
//     assign empty = (wr_ptr == rd_ptr);
    
//     assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
//                    (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

//     // -------------------------------------------------------------------------
//     // Write Logic
//     // -------------------------------------------------------------------------
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
//         end else begin
//             if (wr_en && !full) begin
//                 mem[wr_ptr[ADDR_WIDTH-1:0]] <= data;
//                 wr_ptr <= wr_ptr + 1'b1;
//             end
//         end
//     end

//     // -------------------------------------------------------------------------
//     // Read Logic (Pointer Advance Only)
//     // -------------------------------------------------------------------------
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
//         end else begin
//             // In look-ahead mode, rd_en just moves the pointer to the next item
//             if (rd_en && !empty) begin
//                 rd_ptr <= rd_ptr + 1'b1;
//             end
//         end
//     end

//     // -------------------------------------------------------------------------
//     // Look-Ahead (FWFT) Output Generation
//     // -------------------------------------------------------------------------
//     // q continuously drives whatever is at the current read pointer location.
//     // When the FIFO transitions from empty to not-empty, the data appears here instantly.
//     assign q = mem[rd_ptr[ADDR_WIDTH-1:0]];

// endmodule


module sc_fifo_lookahead #(
    parameter DATA_WIDTH = 128,   // = C_DIN_WIDTH = C_DOUT_WIDTH
    //parameter DEPTH      = 32, // = C_WR_DEPTH  = C_RD_DEPTH
    parameter ADDR_WIDTH = 5    // = clog2(DEPTH), = C_WR_PNTR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst_n,        // active-low, giu = 0 vai chu ky de reset het

    // Write side
    input  wire [DATA_WIDTH-1:0]  data, //din
    input  wire                   wr_en,
    output wire                   full, //full_o

    // Read side (FWFT: dout hop le ngay khi empty=0, khong can cho 1 chu ky)
    input  wire                   rd_en,
    output wire [DATA_WIDTH-1:0]  q, //dout
    output wire                   empty, //empty_o

    // Safety-circuit reset-busy flags (giong ban goc khi C_EN_SAFETY_CKT=1)
    output wire                   wr_rst_busy,
    output wire                   rd_rst_busy


//     input  wire                  clk,
//     input  wire                  rst_n,
//     input  wire                  wr_en,  // Write Enable
//     input  wire                  rd_en,  // Read Enable
//     input  wire [DATA_WIDTH-1:0] data,   // Data Input
//     output wire [DATA_WIDTH-1:0] q,      // Data Output (Now a wire for look-ahead)
//     output wire                  full,   // FIFO Full Flag
//     output wire                  empty   // FIFO Empty Flag
);

//assign
wire [DATA_WIDTH-1:0]  din;
wire [DATA_WIDTH-1:0]  dout;
wire                  full_o;
wire                  empty_o;
assign din  = data;
assign q    = dout;
assign full = full_o;
assign empty = empty_o;
    // -------------------------------------------------------------------
    // Reset synchronizer + "busy" generator
    // Mo phong hanh vi cua IP goc: khi rst_n xuong 0, FIFO can vai chu ky de
    // thuc su reset xong (busy=1), va wr_en/rd_en bi bo qua trong luc do.
    // -------------------------------------------------------------------
    localparam DEPTH = 1 << ADDR_WIDTH;
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