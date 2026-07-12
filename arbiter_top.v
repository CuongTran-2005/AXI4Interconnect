`timescale 1ns / 1ps

module arbiter_top #(
    parameter NUM_MASTERS  = 4,
    parameter ID_WIDTH     = 2,
    parameter AXI_ID_WIDTH = 4, // Width of AXI BID and RID signals
    parameter FIFO_DEPTH   = 4  // Address width for FIFO (2^4 = 16 depth)
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // -------------------------------------------------------------------------
    // AW Channel (Write Address)
    // -------------------------------------------------------------------------
    input  wire [NUM_MASTERS-1:0]  aw_req,
    //input  wire                    aw_handshake,
    output wire [ID_WIDTH-1:0]     Master_id_aw,
    output wire                    aw_fifo_full,

    // -------------------------------------------------------------------------
    // W Channel (Write Data)
    // -------------------------------------------------------------------------
    //input  wire                    w_handshake,
    input  wire                    WLAST,
    output wire [ID_WIDTH-1:0]     Master_id_w,

    // -------------------------------------------------------------------------
    // B Channel (Write Response)
    // -------------------------------------------------------------------------
    input  wire [AXI_ID_WIDTH-1:0] BID,
    output wire [ID_WIDTH-1:0]     Master_id_b,

    // -------------------------------------------------------------------------
    // AR Channel (Read Address)
    // -------------------------------------------------------------------------
    input  wire [NUM_MASTERS-1:0]  ar_req,
    //input  wire                    ar_handshake,
    output wire [ID_WIDTH-1:0]     Master_id_ar,

    // -------------------------------------------------------------------------
    // R Channel (Read Data)
    // -------------------------------------------------------------------------
    input  wire [AXI_ID_WIDTH-1:0] RID,
    output wire [ID_WIDTH-1:0]     Master_id_r,
    //
    //valid signal for slave dsp
    input 								ctl_slv_dsp_aw_valid_i,
    input 								ctl_slv_dsp_ar_valid_i,
    input 								ctl_slv_dsp_w_valid_i,
    output 								ctl_slv_dsp_r_valid_o,
    output  								ctl_slv_dsp_b_valid_o,
    //ready signal for slave dsp
    output 								ctl_slv_dsp_aw_ready_o,
    output 								ctl_slv_dsp_ar_ready_o,
    output 								ctl_slv_dsp_w_ready_o,
    input 								ctl_slv_dsp_r_ready_i,
    input 								ctl_slv_dsp_b_ready_i,
	 
    // -------------slave skid buffer-----------------
    
    //valid signal for slave skid buffer
    output 								ctl_slv_sk_aw_valid_o,
    output 								ctl_slv_sk_ar_valid_o,
    output 								ctl_slv_sk_w_valid_o,
    input 								ctl_slv_sk_r_valid_i,
    input  								ctl_slv_sk_b_valid_i,
    //ready signal for slave skid buffer
    input 								ctl_slv_sk_aw_ready_i,
    input 								ctl_slv_sk_ar_ready_i,
    input 								ctl_slv_sk_w_ready_i,
    output 								ctl_slv_sk_r_ready_o,
    output 								ctl_slv_sk_b_ready_o
);
    //
    wire aw_handshake;
    wire ar_handshake ;
    wire w_handshake;

    // Internal wires for FIFO control
    wire fifo_write;
    wire fifo_read;
    // handshake
    assign aw_handshake = ctl_slv_sk_aw_valid_o & ctl_slv_sk_aw_ready_i;
    assign ar_handshake = ctl_slv_sk_ar_valid_o & ctl_slv_sk_ar_ready_i;
    assign w_handshake = ctl_slv_sk_w_valid_o & ctl_slv_sk_w_ready_i;
    //valid ready
    assign ctl_slv_sk_aw_valid_o = ctl_slv_dsp_aw_valid_i  & ~aw_fifo_full;
    assign ctl_slv_sk_ar_valid_o = ctl_slv_dsp_ar_valid_i;
    assign ctl_slv_sk_w_valid_o = ctl_slv_dsp_w_valid_i ;
    assign ctl_slv_dsp_r_valid_o = ctl_slv_sk_r_valid_i ;
    assign ctl_slv_dsp_b_valid_o = ctl_slv_sk_b_valid_i ;

    assign ctl_slv_dsp_aw_ready_o = ctl_slv_sk_aw_ready_i ;
    assign ctl_slv_dsp_ar_ready_o = ctl_slv_sk_ar_ready_i ;
    assign ctl_slv_dsp_w_ready_o = ctl_slv_sk_w_ready_i ;
    assign ctl_slv_sk_r_ready_o = ctl_slv_dsp_r_ready_i ;
    assign ctl_slv_sk_b_ready_o = ctl_slv_dsp_b_ready_i ;
    // =========================================================================
    // AW Channel Arbitration & ID Tracking
    // =========================================================================

    // AW Arbiter instantiation
    round_robin_arbiter #(
        .NUM_MASTERS(NUM_MASTERS),
        .ID_WIDTH(ID_WIDTH)
    ) aw_arbiter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ax_req(aw_req),
        .ax_handshake(aw_handshake),
        .Master_id_ax(Master_id_aw),
        .fifo_write(fifo_write)
    );

    // FIFO Pop Logic: AND gate combining w_handshake and WLAST
    // We only pop the ID from the FIFO when the *last* data beat is transferred.
    assign fifo_read = w_handshake & WLAST;

    // ID Tracking FIFO (Look-ahead FWFT)
    sc_fifo_lookahead #(
        .DATA_WIDTH(ID_WIDTH),
        .ADDR_WIDTH(FIFO_DEPTH)
    ) aw_id_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_write),
        .rd_en(fifo_read),
        .data(Master_id_aw),
        .q(Master_id_w),
        .full(aw_fifo_full),
        .empty(aw_fifo_empty) // Empty flag not used in the diagram
    );

    // Master's ID Extractor for B Channel
    master_id_extractor #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) bid_extractor_inst (
        .axi_id(BID),
        .master_id(Master_id_b)
    );

    // =========================================================================
    // AR Channel Arbitration & ID Tracking
    // =========================================================================

    // AR Arbiter instantiation
    round_robin_arbiter #(
        .NUM_MASTERS(NUM_MASTERS),
        .ID_WIDTH(ID_WIDTH)
    ) ar_arbiter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ax_req(ar_req),
        .ax_handshake(ar_handshake),
        .Master_id_ax(Master_id_ar),
        .fifo_write() // FIFO write is unused on the AR side in the diagram
    );

    // Master's ID Extractor for R Channel
    master_id_extractor #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) rid_extractor_inst (
        .axi_id(RID),
        .master_id(Master_id_r)
    );

endmodule


// =========================================================================
// Helper Module: Master's ID Extractor
// =========================================================================
// Extracts the Master ID from the AXI ID bus (typically the lower bits)
module master_id_extractor #(
    parameter AXI_ID_WIDTH = 4,
    parameter ID_WIDTH     = 2
)(
    input  wire [AXI_ID_WIDTH-1:0] axi_id,
    output wire [ID_WIDTH-1:0]     master_id
);
    
    // Extract the relevant bits (Assuming Master ID occupies the lowest bits)
    assign master_id = axi_id[ID_WIDTH-1:0];

endmodule