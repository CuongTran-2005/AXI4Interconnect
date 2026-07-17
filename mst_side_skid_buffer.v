module mst_side_skid_buffer
#(
    parameter DATA_WIDTH          = 32,
    parameter ADDR_WIDTH          = 32,
    parameter TRANS_MST_ID_W      = 5,
    parameter TRANS_BURST_W       = 2,
    parameter TRANS_DATA_LEN_W    = 3,
    parameter TRANS_DATA_SIZE_W   = 3,
    parameter TRANS_WR_RESP_W     = 2,
    parameter TRANS_QOS_W         = 16
)
(
    input                                   ACLK_i,
    input                                   ARESETn_i,

    //--------------------------------------------------
    // MASTER SIDE
    //--------------------------------------------------

    // AR
    input  [TRANS_MST_ID_W-1:0]             m_ARID_i,
    input  [ADDR_WIDTH-1:0]                 m_ARADDR_i,
    input  [TRANS_BURST_W-1:0]              m_ARBURST_i,
    input  [TRANS_DATA_LEN_W-1:0]           m_ARLEN_i,
    input  [TRANS_DATA_SIZE_W-1:0]          m_ARSIZE_i,
    input  [TRANS_QOS_W -1:0]               m_ARQOS_i,
    input                                   m_ARVALID_i,
    output                                  m_ARREADY_o,

    // AW
    input  [TRANS_MST_ID_W-1:0]             m_AWID_i,
    input  [ADDR_WIDTH-1:0]                 m_AWADDR_i,
    input  [TRANS_BURST_W-1:0]              m_AWBURST_i,
    input  [TRANS_DATA_LEN_W-1:0]           m_AWLEN_i,
    input  [TRANS_DATA_SIZE_W-1:0]          m_AWSIZE_i,
    input  [TRANS_QOS_W -1:0]               m_AWQOS_i,
    input                                   m_AWVALID_i,
    output                                  m_AWREADY_o,

    // W
    input  [DATA_WIDTH-1:0]                 m_WDATA_i,
    input                                   m_WLAST_i,
    input                                   m_WVALID_i,
    output                                  m_WREADY_o,

    // R
    output [TRANS_MST_ID_W-1:0]             m_RID_o,
    output [DATA_WIDTH-1:0]                 m_RDATA_o,
    output [TRANS_WR_RESP_W-1:0]            m_RRESP_o,
    output                                  m_RLAST_o,
    output                                  m_RVALID_o,
    input                                   m_RREADY_i,

    // B
    output [TRANS_MST_ID_W-1:0]             m_BID_o,
    output [TRANS_WR_RESP_W-1:0]            m_BRESP_o,
    output                                  m_BVALID_o,
    input                                   m_BREADY_i,

    //--------------------------------------------------
    // DSP SIDE
    //--------------------------------------------------

    // AR
    output [TRANS_MST_ID_W-1:0]             dsp_ARID_o,
    output [ADDR_WIDTH-1:0]                 dsp_ARADDR_o,
    output [TRANS_BURST_W-1:0]              dsp_ARBURST_o,
    output [TRANS_DATA_LEN_W-1:0]           dsp_ARLEN_o,
    output [TRANS_DATA_SIZE_W-1:0]          dsp_ARSIZE_o,
    output  [TRANS_QOS_W -1:0]              dsp_ARQOS_o,
    output                                  dsp_ARVALID_o,
    input                                   dsp_ARREADY_i,

    // AW
    output [TRANS_MST_ID_W-1:0]             dsp_AWID_o,
    output [ADDR_WIDTH-1:0]                 dsp_AWADDR_o,
    output [TRANS_BURST_W-1:0]              dsp_AWBURST_o,
    output [TRANS_DATA_LEN_W-1:0]           dsp_AWLEN_o,
    output [TRANS_DATA_SIZE_W-1:0]          dsp_AWSIZE_o,
    output  [TRANS_QOS_W -1:0]              dsp_AWQOS_o,
    output                                  dsp_AWVALID_o,
    input                                   dsp_AWREADY_i,

    // W
    output [DATA_WIDTH-1:0]                 dsp_WDATA_o,
    output                                  dsp_WLAST_o,
    output                                  dsp_WVALID_o,
    input                                   dsp_WREADY_i,

    // R
    input  [TRANS_MST_ID_W-1:0]             dsp_RID_i,
    input  [DATA_WIDTH-1:0]                 dsp_RDATA_i,
    input  [TRANS_WR_RESP_W-1:0]            dsp_RRESP_i,
    input                                   dsp_RLAST_i,
    input                                   dsp_RVALID_i,
    output                                  dsp_RREADY_o,

    // B
    input  [TRANS_MST_ID_W-1:0]             dsp_BID_i,
    input  [TRANS_WR_RESP_W-1:0]            dsp_BRESP_i,
    input                                   dsp_BVALID_i,
    output                                  dsp_BREADY_o
);

//PAYLOAD WITDH
localparam AR_CH_W = TRANS_MST_ID_W + ADDR_WIDTH + TRANS_BURST_W + TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W + TRANS_QOS_W;

localparam AW_CH_W = TRANS_MST_ID_W + ADDR_WIDTH + TRANS_BURST_W + TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W + TRANS_QOS_W;

localparam W_CH_W = DATA_WIDTH + 1;

localparam R_CH_W = TRANS_MST_ID_W + DATA_WIDTH + TRANS_WR_RESP_W + 1;

localparam B_CH_W = TRANS_MST_ID_W + TRANS_WR_RESP_W;

//AR skid
wire [AR_CH_W-1:0] ar_in;
wire [AR_CH_W-1:0] ar_out;

assign ar_in = {
    m_ARID_i,
    m_ARADDR_i,
    m_ARBURST_i,
    m_ARLEN_i,
    m_ARSIZE_i,
    m_ARQOS_i
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
    .bwd_valid_i    (m_ARVALID_i),
    .bwd_ready_o    (m_ARREADY_o),

    .fwd_data_o     (ar_out),
    .fwd_valid_o    (dsp_ARVALID_o),
    .fwd_ready_i    (dsp_ARREADY_i)
);

assign {
    dsp_ARID_o,
    dsp_ARADDR_o,
    dsp_ARBURST_o,
    dsp_ARLEN_o,
    dsp_ARSIZE_o,
    dsp_ARQOS_o
} = ar_out;

//AW skid
wire [AW_CH_W-1:0] aw_in;
wire [AW_CH_W-1:0] aw_out;

assign aw_in = {
    m_AWID_i,
    m_AWADDR_i,
    m_AWBURST_i,
    m_AWLEN_i,
    m_AWSIZE_i,
    m_AWQOS_i
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
    .bwd_valid_i    (m_AWVALID_i),
    .bwd_ready_o    (m_AWREADY_o),

    .fwd_data_o     (aw_out),
    .fwd_valid_o    (dsp_AWVALID_o),
    .fwd_ready_i    (dsp_AWREADY_i)
);

assign {
    dsp_AWID_o,
    dsp_AWADDR_o,
    dsp_AWBURST_o,
    dsp_AWLEN_o,
    dsp_AWSIZE_o,
    dsp_AWQOS_o
} = aw_out;

//W skid
wire [W_CH_W-1:0] w_in;
wire [W_CH_W-1:0] w_out;

assign w_in = {
    m_WDATA_i,
    m_WLAST_i
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
    .bwd_valid_i    (m_WVALID_i),
    .bwd_ready_o    (m_WREADY_o),

    .fwd_data_o     (w_out),
    .fwd_valid_o    (dsp_WVALID_o),
    .fwd_ready_i    (dsp_WREADY_i)
);

assign {
    dsp_WDATA_o,
    dsp_WLAST_o
} = w_out;

//R skid
wire [R_CH_W-1:0] r_in;
wire [R_CH_W-1:0] r_out;

assign r_in = {
    dsp_RID_i,
    dsp_RDATA_i,
    dsp_RRESP_i,
    dsp_RLAST_i
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
    .bwd_valid_i    (dsp_RVALID_i),
    .bwd_ready_o    (dsp_RREADY_o),

    .fwd_data_o     (r_out),
    .fwd_valid_o    (m_RVALID_o),
    .fwd_ready_i    (m_RREADY_i)
);

assign {
    m_RID_o,
    m_RDATA_o,
    m_RRESP_o,
    m_RLAST_o
} = r_out;

//B skid
wire [B_CH_W-1:0] b_in;
wire [B_CH_W-1:0] b_out;

assign b_in = {
    dsp_BID_i,
    dsp_BRESP_i
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
    .bwd_valid_i    (dsp_BVALID_i),
    .bwd_ready_o    (dsp_BREADY_o),

    .fwd_data_o     (b_out),
    .fwd_valid_o    (m_BVALID_o),
    .fwd_ready_i    (m_BREADY_i)
);

assign {
    m_BID_o,
    m_BRESP_o
} = b_out;
endmodule