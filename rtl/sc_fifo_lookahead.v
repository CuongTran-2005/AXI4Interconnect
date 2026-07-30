`timescale 1ns / 1ps

module sc_fifo_lookahead #(
    parameter DATA_WIDTH = 120,  // Width of the data bus
    parameter ADDR_WIDTH = 5   // Depth of FIFO is 2^ADDR_WIDTH
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,  // Write Enable
    input  wire                  rd_en,  // Read Enable
    input  wire [DATA_WIDTH-1:0] data,   // Data Input
    output wire [DATA_WIDTH-1:0] q,      // Data Output (Now a wire for look-ahead)
    output wire                  full,   // FIFO Full Flag
    output wire                  empty   // FIFO Empty Flag
);

    // Calculate depth based on address width
    localparam DEPTH = 1 << ADDR_WIDTH;

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers with an extra bit for status flags
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // -------------------------------------------------------------------------
    // Status Flags
    // -------------------------------------------------------------------------
    assign empty = (wr_ptr == rd_ptr);
    
    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

    // -------------------------------------------------------------------------
    // Write Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= data;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read Logic (Pointer Advance Only)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            // In look-ahead mode, rd_en just moves the pointer to the next item
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Look-Ahead (FWFT) Output Generation
    // -------------------------------------------------------------------------
    // q continuously drives whatever is at the current read pointer location.
    // When the FIFO transitions from empty to not-empty, the data appears here instantly.
    assign q = mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule