module slv_side_skid_buffer
#(
    parameter DATA_WIDTH          = 32,
    parameter ADDR_WIDTH          = 32,
    parameter TRANS_MST_ID_W      = 5,
    parameter TRANS_BURST_W       = 2,
    parameter TRANS_DATA_LEN_W    = 3,
    parameter TRANS_DATA_SIZE_W   = 3,
    parameter TRANS_WR_RESP_W     = 2,
	 parameter TRANS_QOS_W			 =16
)
(
    input                                   ACLK_i,
    input                                   ARESETn_i,

    //--------------------------------------------------
    // DSP SIDE
    //--------------------------------------------------

    // AR
    input  [TRANS_MST_ID_W-1:0]             dsp_ARID_i,
    input  [ADDR_WIDTH-1:0]                 dsp_ARADDR_i,
    input  [TRANS_BURST_W-1:0]              dsp_ARBURST_i,
    input  [TRANS_DATA_LEN_W-1:0]           dsp_ARLEN_i,
    input  [TRANS_DATA_SIZE_W-1:0]          dsp_ARSIZE_i,
    input  [TRANS_QOS_W-1:0]                dsp_ARQOS_i,
    input                                   dsp_ARVALID_i,
    output                                  dsp_ARREADY_o,

    // AW
    input  [TRANS_MST_ID_W-1:0]             dsp_AWID_i,
    input  [ADDR_WIDTH-1:0]                 dsp_AWADDR_i,
    input  [TRANS_BURST_W-1:0]              dsp_AWBURST_i,
    input  [TRANS_DATA_LEN_W-1:0]           dsp_AWLEN_i,
    input  [TRANS_DATA_SIZE_W-1:0]          dsp_AWSIZE_i,
    input  [TRANS_QOS_W-1:0]                dsp_AWQOS_i,
    input                                   dsp_AWVALID_i,
    output                                  dsp_AWREADY_o,

    // W
    input  [DATA_WIDTH-1:0]                 dsp_WDATA_i,
    input                                   dsp_WLAST_i,
    input                                   dsp_WVALID_i,
    output                                  dsp_WREADY_o,

    // R
    output [TRANS_MST_ID_W-1:0]             dsp_RID_o,
    output [DATA_WIDTH-1:0]                 dsp_RDATA_o,
    output [TRANS_WR_RESP_W-1:0]            dsp_RRESP_o,
    output                                  dsp_RLAST_o,
    output                                  dsp_RVALID_o,
    input                                   dsp_RREADY_i,

    // B
    output [TRANS_MST_ID_W-1:0]             dsp_BID_o,
    output [TRANS_WR_RESP_W-1:0]            dsp_BRESP_o,
    output                                  dsp_BVALID_o,
    input                                   dsp_BREADY_i,

    //--------------------------------------------------
    // SLAVE SIDE
    //--------------------------------------------------

    // AR
    output [TRANS_MST_ID_W-1:0]             s_ARID_o,
    output [ADDR_WIDTH-1:0]                 s_ARADDR_o,
    output [TRANS_BURST_W-1:0]              s_ARBURST_o,
    output [TRANS_DATA_LEN_W-1:0]           s_ARLEN_o,
    output [TRANS_DATA_SIZE_W-1:0]          s_ARSIZE_o,
    output [TRANS_QOS_W-1:0]                s_ARQOS_o,
    output                                  s_ARVALID_o,
    input                                   s_ARREADY_i,

    // AW
    output [TRANS_MST_ID_W-1:0]             s_AWID_o,
    output [ADDR_WIDTH-1:0]                 s_AWADDR_o,
    output [TRANS_BURST_W-1:0]              s_AWBURST_o,
    output [TRANS_DATA_LEN_W-1:0]           s_AWLEN_o,
    output [TRANS_DATA_SIZE_W-1:0]          s_AWSIZE_o,
    output [TRANS_QOS_W-1:0]                s_AWQOS_o,
    output                                  s_AWVALID_o,
    input                                   s_AWREADY_i,

    // W
    output [DATA_WIDTH-1:0]                 s_WDATA_o,
    output                                  s_WLAST_o,
    output                                  s_WVALID_o,
    input                                   s_WREADY_i,

    // R
    input  [TRANS_MST_ID_W-1:0]             s_RID_i,
    input  [DATA_WIDTH-1:0]                 s_RDATA_i,
    input  [TRANS_WR_RESP_W-1:0]            s_RRESP_i,
    input                                   s_RLAST_i,
    input                                   s_RVALID_i,
    output                                  s_RREADY_o,

    // B
    input  [TRANS_MST_ID_W-1:0]             s_BID_i,
    input  [TRANS_WR_RESP_W-1:0]            s_BRESP_i,
    input                                   s_BVALID_i,
    output                                  s_BREADY_o
);

//--------------------------------------------------
// Payload Width
//--------------------------------------------------

localparam AR_CH_W =
      TRANS_MST_ID_W
    + ADDR_WIDTH
    + TRANS_BURST_W
    + TRANS_DATA_LEN_W
    + TRANS_DATA_SIZE_W
    + TRANS_QOS_W;

localparam AW_CH_W =
      TRANS_MST_ID_W
    + ADDR_WIDTH
    + TRANS_BURST_W
    + TRANS_DATA_LEN_W
    + TRANS_DATA_SIZE_W
    +TRANS_QOS_W;

localparam W_CH_W =
      DATA_WIDTH
    + 1;

localparam R_CH_W =
      TRANS_MST_ID_W
    + DATA_WIDTH
    + TRANS_WR_RESP_W
    + 1;

localparam B_CH_W =
      TRANS_MST_ID_W
    + TRANS_WR_RESP_W;

//--------------------------------------------------
// AR skid
//--------------------------------------------------

wire [AR_CH_W-1:0] ar_in;
wire [AR_CH_W-1:0] ar_out;

assign ar_in = {
    dsp_ARID_i,
    dsp_ARADDR_i,
    dsp_ARBURST_i,
    dsp_ARLEN_i,
    dsp_ARSIZE_i,
    dsp_ARQOS_i
};

skid_buffer
#(
    .DATA_WIDTH(AR_CH_W)
)
u_ar_skid
(
    .clk            (ACLK_i),
    .rst_n          (ARESETn_i),

    .bwd_data_i     (ar_in),
    .bwd_valid_i    (dsp_ARVALID_i),
    .bwd_ready_o    (dsp_ARREADY_o),

    .fwd_data_o     (ar_out),
    .fwd_valid_o    (s_ARVALID_o),
    .fwd_ready_i    (s_ARREADY_i)
);

assign {
    s_ARID_o,
    s_ARADDR_o,
    s_ARBURST_o,
    s_ARLEN_o,
    s_ARSIZE_o,
    s_ARQOS_o
} = ar_out;

//--------------------------------------------------
// AW skid
//--------------------------------------------------

wire [AW_CH_W-1:0] aw_in;
wire [AW_CH_W-1:0] aw_out;

assign aw_in = {
    dsp_AWID_i,
    dsp_AWADDR_i,
    dsp_AWBURST_i,
    dsp_AWLEN_i,
    dsp_AWSIZE_i,
    dsp_AWQOS_i
};

skid_buffer
#(
    .DATA_WIDTH(AW_CH_W)
)
u_aw_skid
(
    .clk            (ACLK_i),
    .rst_n          (ARESETn_i),

    .bwd_data_i     (aw_in),
    .bwd_valid_i    (dsp_AWVALID_i),
    .bwd_ready_o    (dsp_AWREADY_o),

    .fwd_data_o     (aw_out),
    .fwd_valid_o    (s_AWVALID_o),
    .fwd_ready_i    (s_AWREADY_i)
);

assign {
    s_AWID_o,
    s_AWADDR_o,
    s_AWBURST_o,
    s_AWLEN_o,
    s_AWSIZE_o,
    s_AWQOS_o
} = aw_out;

//--------------------------------------------------
// W skid
//--------------------------------------------------

wire [W_CH_W-1:0] w_in;
wire [W_CH_W-1:0] w_out;

assign w_in = {
    dsp_WDATA_i,
    dsp_WLAST_i
};

skid_buffer
#(
    .DATA_WIDTH(W_CH_W)
)
u_w_skid
(
    .clk            (ACLK_i),
    .rst_n          (ARESETn_i),

    .bwd_data_i     (w_in),
    .bwd_valid_i    (dsp_WVALID_i),
    .bwd_ready_o    (dsp_WREADY_o),

    .fwd_data_o     (w_out),
    .fwd_valid_o    (s_WVALID_o),
    .fwd_ready_i    (s_WREADY_i)
);

assign {
    s_WDATA_o,
    s_WLAST_o
} = w_out;

//--------------------------------------------------
// R skid
//--------------------------------------------------

wire [R_CH_W-1:0] r_in;
wire [R_CH_W-1:0] r_out;

assign r_in = {
    s_RID_i,
    s_RDATA_i,
    s_RRESP_i,
    s_RLAST_i
};

skid_buffer
#(
    .DATA_WIDTH(R_CH_W)
)
u_r_skid
(
    .clk            (ACLK_i),
    .rst_n          (ARESETn_i),

    .bwd_data_i     (r_in),
    .bwd_valid_i    (s_RVALID_i),
    .bwd_ready_o    (s_RREADY_o),

    .fwd_data_o     (r_out),
    .fwd_valid_o    (dsp_RVALID_o),
    .fwd_ready_i    (dsp_RREADY_i)
);

assign {
    dsp_RID_o,
    dsp_RDATA_o,
    dsp_RRESP_o,
    dsp_RLAST_o
} = r_out;

//--------------------------------------------------
// B skid
//--------------------------------------------------

wire [B_CH_W-1:0] b_in;
wire [B_CH_W-1:0] b_out;

assign b_in = {
    s_BID_i,
    s_BRESP_i
};

skid_buffer
#(
    .DATA_WIDTH(B_CH_W)
)
u_b_skid
(
    .clk            (ACLK_i),
    .rst_n          (ARESETn_i),

    .bwd_data_i     (b_in),
    .bwd_valid_i    (s_BVALID_i),
    .bwd_ready_o    (s_BREADY_o),

    .fwd_data_o     (b_out),
    .fwd_valid_o    (dsp_BVALID_o),
    .fwd_ready_i    (dsp_BREADY_i)
);

assign {
    dsp_BID_o,
    dsp_BRESP_o
} = b_out;

endmodule