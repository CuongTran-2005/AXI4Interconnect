module axi_interconnect_cover #(
    parameter MST_AMT             = 4,
    parameter SLV_AMT             = 4,

    parameter DATA_WIDTH          = 32,
    parameter ADDR_WIDTH          = 32,

    parameter TRANS_MST_ID_W      = 5,
    parameter TRANS_BURST_W       = 2,
    parameter TRANS_DATA_LEN_W    = 8,
    parameter TRANS_DATA_SIZE_W   = 3,
    parameter TRANS_WR_RESP_W     = 2,
    parameter TRANS_QOS_W         = 4,

    parameter MST_ID_W            = $clog2(MST_AMT),
    parameter SLV_ID_W            = $clog2(SLV_AMT),

    parameter OUTSTANDING_AMT     = 8,
    parameter FIFO_DEPTH          = 16
)(
    //------------------------------------------------------------
    // Global
    //------------------------------------------------------------
    input  wire                             ACLK_i,
    input  wire                             ARESETn_i,

    //------------------------------------------------------------
    // Select Master / Slave
    //------------------------------------------------------------
    input  wire [MST_ID_W-1:0]              master_id_i,
    input  wire [SLV_ID_W-1:0]              slave_id_i,

    //============================================================
    //                External Master Interface
    //============================================================

    //---------------- AW ----------------
    input  wire [TRANS_MST_ID_W-1:0]        m_AWID_i,
    input  wire [ADDR_WIDTH-1:0]            m_AWADDR_i,
    input  wire [TRANS_DATA_LEN_W-1:0]      m_AWLEN_i,
    input  wire [TRANS_DATA_SIZE_W-1:0]     m_AWSIZE_i,
    input  wire [TRANS_BURST_W-1:0]         m_AWBURST_i,
    input  wire [TRANS_QOS_W-1:0]           m_AWQOS_i,
    input  wire                             m_AWVALID_i,
    output wire                             m_AWREADY_o,

    //---------------- W -----------------
    input  wire [DATA_WIDTH-1:0]            m_WDATA_i,
    input  wire                             m_WLAST_i,
    input  wire                             m_WVALID_i,
    output wire                             m_WREADY_o,

    //---------------- B -----------------
    output wire [TRANS_MST_ID_W-1:0]        m_BID_o,
    output wire [TRANS_WR_RESP_W-1:0]       m_BRESP_o,
    output wire                             m_BVALID_o,
    input  wire                             m_BREADY_i,

    //---------------- AR ----------------
    input  wire [TRANS_MST_ID_W-1:0]        m_ARID_i,
    input  wire [ADDR_WIDTH-1:0]            m_ARADDR_i,
    input  wire [TRANS_DATA_LEN_W-1:0]      m_ARLEN_i,
    input  wire [TRANS_DATA_SIZE_W-1:0]     m_ARSIZE_i,
    input  wire [TRANS_BURST_W-1:0]         m_ARBURST_i,
    input  wire [TRANS_QOS_W-1:0]           m_ARQOS_i,
    input  wire                             m_ARVALID_i,
    output wire                             m_ARREADY_o,

    //---------------- R -----------------
    output wire [TRANS_MST_ID_W-1:0]        m_RID_o,
    output wire [DATA_WIDTH-1:0]            m_RDATA_o,
    output wire [TRANS_WR_RESP_W-1:0]       m_RRESP_o,
    output wire                             m_RLAST_o,
    output wire                             m_RVALID_o,
    input  wire                             m_RREADY_i,

    //============================================================
    //                External Slave Interface
    //============================================================

    //---------------- AW ----------------
    output wire [MST_ID_W+TRANS_MST_ID_W-1:0] s_AWID_o,
    output wire [ADDR_WIDTH-1:0]              s_AWADDR_o,
    output wire [TRANS_DATA_LEN_W-1:0]        s_AWLEN_o,
    output wire [TRANS_DATA_SIZE_W-1:0]       s_AWSIZE_o,
    output wire [TRANS_BURST_W-1:0]           s_AWBURST_o,
    output wire [TRANS_QOS_W-1:0]             s_AWQOS_o,
    output wire                               s_AWVALID_o,
    input  wire                               s_AWREADY_i,

    //---------------- W -----------------
    output wire [DATA_WIDTH-1:0]              s_WDATA_o,
    output wire                               s_WLAST_o,
    output wire                               s_WVALID_o,
    input  wire                               s_WREADY_i,

    //---------------- B -----------------
    input  wire [MST_ID_W+TRANS_MST_ID_W-1:0] s_BID_i,
    input  wire [TRANS_WR_RESP_W-1:0]         s_BRESP_i,
    input  wire                               s_BVALID_i,
    output wire                               s_BREADY_o,

    //---------------- AR ----------------
    output wire [MST_ID_W+TRANS_MST_ID_W-1:0] s_ARID_o,
    output wire [ADDR_WIDTH-1:0]              s_ARADDR_o,
    output wire [TRANS_DATA_LEN_W-1:0]        s_ARLEN_o,
    output wire [TRANS_DATA_SIZE_W-1:0]       s_ARSIZE_o,
    output wire [TRANS_BURST_W-1:0]           s_ARBURST_o,
    output wire [TRANS_QOS_W-1:0]             s_ARQOS_o,
    output wire                               s_ARVALID_o,
    input  wire                               s_ARREADY_i,

    //---------------- R -----------------
    input  wire [MST_ID_W+TRANS_MST_ID_W-1:0] s_RID_i,
    input  wire [DATA_WIDTH-1:0]              s_RDATA_i,
    input  wire [TRANS_WR_RESP_W-1:0]         s_RRESP_i,
    input  wire                               s_RLAST_i,
    input  wire                               s_RVALID_i,
    output wire                               s_RREADY_o
);


    // ---------------- Master side channel wires (theo MST_AMT) ------------
    wire [TRANS_MST_ID_W*MST_AMT-1:0]    w_m_AWID;
    wire [ADDR_WIDTH*MST_AMT-1:0]        w_m_AWADDR;
    wire [TRANS_DATA_LEN_W*MST_AMT-1:0]  w_m_AWLEN;
    wire [TRANS_DATA_SIZE_W*MST_AMT-1:0] w_m_AWSIZE;
    wire [TRANS_BURST_W*MST_AMT-1:0]     w_m_AWBURST;
    wire [TRANS_QOS_W*MST_AMT-1:0]       w_m_AWQOS;
    wire [MST_AMT-1:0]                   w_m_AWVALID;
    wire [MST_AMT-1:0]                   w_m_AWREADY;

    wire [DATA_WIDTH*MST_AMT-1:0]        w_m_WDATA;
    wire [MST_AMT-1:0]                   w_m_WLAST;
    wire [MST_AMT-1:0]                   w_m_WVALID;
    wire [MST_AMT-1:0]                   w_m_WREADY;

    wire [TRANS_MST_ID_W*MST_AMT-1:0]    w_m_BID;
    wire [TRANS_WR_RESP_W*MST_AMT-1:0]   w_m_BRESP;
    wire [MST_AMT-1:0]                   w_m_BVALID;
    wire [MST_AMT-1:0]                   w_m_BREADY;

    wire [TRANS_MST_ID_W*MST_AMT-1:0]    w_m_ARID;
    wire [ADDR_WIDTH*MST_AMT-1:0]        w_m_ARADDR;
    wire [TRANS_DATA_LEN_W*MST_AMT-1:0]  w_m_ARLEN;
    wire [TRANS_DATA_SIZE_W*MST_AMT-1:0] w_m_ARSIZE;
    wire [TRANS_BURST_W*MST_AMT-1:0]     w_m_ARBURST;
    wire [TRANS_QOS_W*MST_AMT-1:0]       w_m_ARQOS;
    wire [MST_AMT-1:0]                   w_m_ARVALID;
    wire [MST_AMT-1:0]                   w_m_ARREADY;

    wire [TRANS_MST_ID_W*MST_AMT-1:0]    w_m_RID;
    wire [DATA_WIDTH*MST_AMT-1:0]        w_m_RDATA;
    wire [TRANS_WR_RESP_W*MST_AMT-1:0]   w_m_RRESP;
    wire [MST_AMT-1:0]                   w_m_RLAST;
    wire [MST_AMT-1:0]                   w_m_RVALID;
    wire [MST_AMT-1:0]                   w_m_RREADY;

    // ---------------- Slave side channel wires (theo SLV_AMT) -------------
    wire [(TRANS_MST_ID_W+MST_ID_W)*SLV_AMT-1:0]          w_s_AWID;
    wire [ADDR_WIDTH*SLV_AMT-1:0]        w_s_AWADDR;
    wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]  w_s_AWLEN;
    wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0] w_s_AWSIZE;
    wire [TRANS_BURST_W*SLV_AMT-1:0]     w_s_AWBURST;
    wire [TRANS_QOS_W*SLV_AMT-1:0]       w_s_AWQOS;
    wire [SLV_AMT-1:0]                   w_s_AWVALID;
    wire [SLV_AMT-1:0]                   w_s_AWREADY;

    wire [DATA_WIDTH*SLV_AMT-1:0]        w_s_WDATA;
    wire [SLV_AMT-1:0]                   w_s_WLAST;
    wire [SLV_AMT-1:0]                   w_s_WVALID;
    wire [SLV_AMT-1:0]                   w_s_WREADY;

    wire [(TRANS_MST_ID_W+MST_ID_W)*SLV_AMT-1:0]          w_s_BID;
    wire [TRANS_WR_RESP_W*SLV_AMT-1:0]   w_s_BRESP;
    wire [SLV_AMT-1:0]                   w_s_BVALID;
    wire [SLV_AMT-1:0]                   w_s_BREADY;

    wire [(TRANS_MST_ID_W+MST_ID_W)*SLV_AMT-1:0]          w_s_ARID;
    wire [ADDR_WIDTH*SLV_AMT-1:0]        w_s_ARADDR;
    wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]  w_s_ARLEN;
    wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0] w_s_ARSIZE;
    wire [TRANS_BURST_W*SLV_AMT-1:0]     w_s_ARBURST;
    wire [TRANS_QOS_W*SLV_AMT-1:0]       w_s_ARQOS;
    wire [SLV_AMT-1:0]                   w_s_ARVALID;
    wire [SLV_AMT-1:0]                   w_s_ARREADY;

    wire [(TRANS_MST_ID_W+MST_ID_W)*SLV_AMT-1:0]          w_s_RID;
    wire [DATA_WIDTH*SLV_AMT-1:0]        w_s_RDATA;
    wire [TRANS_WR_RESP_W*SLV_AMT-1:0]   w_s_RRESP;
    wire [SLV_AMT-1:0]                   w_s_RLAST;
    wire [SLV_AMT-1:0]                   w_s_RVALID;
    wire [SLV_AMT-1:0]                   w_s_RREADY;

    //=========================================================================
    // Instantiate axi4_interconnect
    //=========================================================================
    axi4_interconnect #(
        .MST_AMT           (MST_AMT),
        .SLV_AMT           (SLV_AMT),
        .DATA_WIDTH        (DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH),
        .TRANS_MST_ID_W    (TRANS_MST_ID_W),
        .TRANS_BURST_W     (TRANS_BURST_W),
        .TRANS_DATA_LEN_W  (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W (TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W   (TRANS_WR_RESP_W),
        .TRANS_QOS_W       (TRANS_QOS_W),
        .MST_ID_W          (MST_ID_W),
        .SLV_ID_W          (SLV_ID_W),
        .OUTSTANDING_AMT   (OUTSTANDING_AMT),
        .FIFO_DEPTH        (FIFO_DEPTH)
    ) u_interconnect (
        .ACLK_i     (ACLK_i),
        .ARESETn_i  (ARESETn_i),

        // Master side
        .m_AWID_i    (w_m_AWID),
        .m_AWADDR_i  (w_m_AWADDR),
        .m_AWLEN_i   (w_m_AWLEN),
        .m_AWSIZE_i  (w_m_AWSIZE),
        .m_AWBURST_i (w_m_AWBURST),
        .m_AWQOS_i   (w_m_AWQOS),
        .m_AWVALID_i (w_m_AWVALID),
        .m_AWREADY_o (w_m_AWREADY),

        .m_WDATA_i   (w_m_WDATA),
        .m_WLAST_i   (w_m_WLAST),
        .m_WVALID_i  (w_m_WVALID),
        .m_WREADY_o  (w_m_WREADY),

        .m_BID_o     (w_m_BID),
        .m_BRESP_o   (w_m_BRESP),
        .m_BVALID_o  (w_m_BVALID),
        .m_BREADY_i  (w_m_BREADY),

        .m_ARID_i    (w_m_ARID),
        .m_ARADDR_i  (w_m_ARADDR),
        .m_ARLEN_i   (w_m_ARLEN),
        .m_ARSIZE_i  (w_m_ARSIZE),
        .m_ARBURST_i (w_m_ARBURST),
        .m_ARQOS_i   (w_m_ARQOS),
        .m_ARVALID_i (w_m_ARVALID),
        .m_ARREADY_o (w_m_ARREADY),

        .m_RID_o     (w_m_RID),
        .m_RDATA_o   (w_m_RDATA),
        .m_RRESP_o   (w_m_RRESP),
        .m_RLAST_o   (w_m_RLAST),
        .m_RVALID_o  (w_m_RVALID),
        .m_RREADY_i  (w_m_RREADY),

        // Slave side
        .s_AWID_o    (w_s_AWID),
        .s_AWADDR_o  (w_s_AWADDR),
        .s_AWLEN_o   (w_s_AWLEN),
        .s_AWSIZE_o  (w_s_AWSIZE),
        .s_AWBURST_o (w_s_AWBURST),
        .s_AWQOS_o   (w_s_AWQOS),
        .s_AWVALID_o (w_s_AWVALID),
        .s_AWREADY_i (w_s_AWREADY),

        .s_WDATA_o   (w_s_WDATA),
        .s_WLAST_o   (w_s_WLAST),
        .s_WVALID_o  (w_s_WVALID),
        .s_WREADY_i  (w_s_WREADY),

        .s_BID_i     (w_s_BID),
        .s_BRESP_i   (w_s_BRESP),
        .s_BVALID_i  (w_s_BVALID),
        .s_BREADY_o  (w_s_BREADY),

        .s_ARID_o    (w_s_ARID),
        .s_ARADDR_o  (w_s_ARADDR),
        .s_ARLEN_o   (w_s_ARLEN),
        .s_ARSIZE_o  (w_s_ARSIZE),
        .s_ARBURST_o (w_s_ARBURST),
        .s_ARQOS_o   (w_s_ARQOS),
        .s_ARVALID_o (w_s_ARVALID),
        .s_ARREADY_i (w_s_ARREADY),

        .s_RID_i     (w_s_RID),
        .s_RDATA_i   (w_s_RDATA),
        .s_RRESP_i   (w_s_RRESP),
        .s_RLAST_i   (w_s_RLAST),
        .s_RVALID_i  (w_s_RVALID),
        .s_RREADY_o  (w_s_RREADY)
    );
genvar mst, slv;


assign m_AWREADY_o = w_m_AWREADY[master_id_i];
assign m_WREADY_o  = w_m_WREADY[master_id_i];
assign m_ARREADY_o = w_m_ARREADY[master_id_i];

assign m_BVALID_o = w_m_BVALID[master_id_i];  
assign m_RVALID_o = w_m_RVALID[master_id_i];

assign m_BID_o =
    w_m_BID[
        TRANS_MST_ID_W*master_id_i +:
        TRANS_MST_ID_W
    ];

assign m_BRESP_o =
    w_m_BRESP[
        TRANS_WR_RESP_W*master_id_i +:
        TRANS_WR_RESP_W
    ];

assign m_RID_o =
    w_m_RID[
        TRANS_MST_ID_W*master_id_i +:
        TRANS_MST_ID_W
    ];

assign m_RDATA_o =
    w_m_RDATA[
        DATA_WIDTH*master_id_i +:
        DATA_WIDTH
    ];

assign m_RRESP_o =
    w_m_RRESP[
        TRANS_WR_RESP_W*master_id_i +:
        TRANS_WR_RESP_W
    ];

assign m_RLAST_o =
    w_m_RLAST[master_id_i];

generate
    for (mst = 0; mst < MST_AMT; mst = mst + 1) begin : gen_mst

        assign w_m_RREADY[mst] = (mst == master_id_i) ? m_RREADY_i : 1'b0;
        assign w_m_BREADY[mst] = (mst == master_id_i) ? m_BREADY_i : 1'b0;

        assign w_m_AWVALID[mst] = (mst == master_id_i) ? m_AWVALID_i : 1'b0;
        assign w_m_WVALID[mst] = (mst == master_id_i) ? m_WVALID_i : 1'b0;
        assign w_m_ARVALID[mst] = (mst == master_id_i) ? m_ARVALID_i : 1'b0;

        assign w_m_AWID[TRANS_MST_ID_W*mst +: TRANS_MST_ID_W] = (mst == master_id_i) ? m_AWID_i : {TRANS_MST_ID_W{1'b0}};
        assign w_m_AWADDR[ADDR_WIDTH*mst +: ADDR_WIDTH] = (mst == master_id_i) ? m_AWADDR_i : {ADDR_WIDTH{1'b0}};
        assign w_m_AWLEN[TRANS_DATA_LEN_W*mst +: TRANS_DATA_LEN_W] = (mst == master_id_i) ? m_AWLEN_i : {TRANS_DATA_LEN_W{1'b0}};
        assign w_m_AWSIZE[TRANS_DATA_SIZE_W*mst +: TRANS_DATA_SIZE_W] = (mst == master_id_i) ? m_AWSIZE_i : {TRANS_DATA_SIZE_W{1'b0}};
        assign w_m_AWBURST[TRANS_BURST_W*mst +: TRANS_BURST_W] = (mst == master_id_i) ? m_AWBURST_i : {TRANS_BURST_W{1'b0}};
        assign w_m_AWQOS[TRANS_QOS_W*mst +: TRANS_QOS_W] = (mst == master_id_i) ? m_AWQOS_i : {TRANS_QOS_W{1'b0}};
        
        assign w_m_WDATA[DATA_WIDTH*mst +: DATA_WIDTH] = (mst == master_id_i) ? m_WDATA_i : {DATA_WIDTH{1'b0}};
        assign w_m_WLAST[mst] = (mst == master_id_i) ? m_WLAST_i : 1'b0;
        

        assign w_m_ARID[TRANS_MST_ID_W*mst +: TRANS_MST_ID_W] = (mst == master_id_i) ? m_ARID_i : {TRANS_MST_ID_W{1'b0}};
        assign w_m_ARADDR[ADDR_WIDTH*mst +: ADDR_WIDTH] = (mst == master_id_i) ? m_ARADDR_i : {ADDR_WIDTH{1'b0}};
        assign w_m_ARLEN[TRANS_DATA_LEN_W*mst +: TRANS_DATA_LEN_W] = (mst == master_id_i) ? m_ARLEN_i : {TRANS_DATA_LEN_W{1'b0}};
        assign w_m_ARSIZE[TRANS_DATA_SIZE_W*mst +: TRANS_DATA_SIZE_W] = (mst == master_id_i) ? m_ARSIZE_i : {TRANS_DATA_SIZE_W{1'b0}};
        assign w_m_ARBURST[TRANS_BURST_W*mst +: TRANS_BURST_W] = (mst == master_id_i) ? m_ARBURST_i : {TRANS_BURST_W{1'b0}};
        assign w_m_ARQOS[TRANS_QOS_W*mst +: TRANS_QOS_W] = (mst == master_id_i) ? m_ARQOS_i : {TRANS_QOS_W{1'b0}};

    end
endgenerate
// ---- Slave nhận (đọc từ mảng dùng chỉ số slave_id_i) ----
assign s_AWVALID_o = w_s_AWVALID[slave_id_i];
assign s_WVALID_o  = w_s_WVALID[slave_id_i];
assign s_ARVALID_o = w_s_ARVALID[slave_id_i];
assign s_RREADY_o  = w_s_RREADY[slave_id_i];
assign s_BREADY_o  = w_s_BREADY[slave_id_i];

assign s_AWID_o    = w_s_AWID   [(TRANS_MST_ID_W +MST_ID_W)  *slave_id_i +: TRANS_MST_ID_W + MST_ID_W];
assign s_AWADDR_o  = w_s_AWADDR [ADDR_WIDTH       *slave_id_i +: ADDR_WIDTH];
assign s_AWLEN_o   = w_s_AWLEN  [TRANS_DATA_LEN_W *slave_id_i +: TRANS_DATA_LEN_W];
assign s_AWSIZE_o  = w_s_AWSIZE [TRANS_DATA_SIZE_W*slave_id_i +: TRANS_DATA_SIZE_W];
assign s_AWBURST_o = w_s_AWBURST[TRANS_BURST_W    *slave_id_i +: TRANS_BURST_W];
assign s_AWQOS_o   = w_s_AWQOS  [TRANS_QOS_W      *slave_id_i +: TRANS_QOS_W];

assign s_WDATA_o   = w_s_WDATA  [DATA_WIDTH       *slave_id_i +: DATA_WIDTH];
assign s_WLAST_o   = w_s_WLAST  [slave_id_i];

assign s_ARID_o    = w_s_ARID   [(TRANS_MST_ID_W +MST_ID_W)  *slave_id_i +: TRANS_MST_ID_W + MST_ID_W];
assign s_ARADDR_o  = w_s_ARADDR [ADDR_WIDTH       *slave_id_i +: ADDR_WIDTH];
assign s_ARLEN_o   = w_s_ARLEN  [TRANS_DATA_LEN_W *slave_id_i +: TRANS_DATA_LEN_W];
assign s_ARSIZE_o  = w_s_ARSIZE [TRANS_DATA_SIZE_W*slave_id_i +: TRANS_DATA_SIZE_W];
assign s_ARBURST_o = w_s_ARBURST[TRANS_BURST_W    *slave_id_i +: TRANS_BURST_W];
assign s_ARQOS_o   = w_s_ARQOS  [TRANS_QOS_W      *slave_id_i +: TRANS_QOS_W];

// ---- Slave drive (flow-control 1 bit, ghi trực tiếp vào mảng) ----


// ---- Slave drive payload nhiều bit (B/R channel) -> generate + mux-zero ----
generate
    for (slv = 0; slv < SLV_AMT; slv = slv + 1) begin : gen_slv

        assign w_s_AWREADY[slv] = (slv == slave_id_i) ? s_AWREADY_i : 1'b0;
        assign w_s_WREADY [slv] = (slv == slave_id_i) ? s_WREADY_i : 1'b0;
        assign w_s_ARREADY[slv] = (slv == slave_id_i) ? s_ARREADY_i : 1'b0;
        assign w_s_BVALID [slv] = (slv == slave_id_i) ? s_BVALID_i : 1'b0;
        assign w_s_RVALID [slv] = (slv == slave_id_i) ? s_RVALID_i : 1'b0;

        assign w_s_BID[(TRANS_MST_ID_W + MST_ID_W)*slv +: TRANS_MST_ID_W + MST_ID_W] =
            (slv == slave_id_i) ? s_BID_i : {(TRANS_MST_ID_W + MST_ID_W){1'b0}};
        assign w_s_BRESP[TRANS_WR_RESP_W*slv +: TRANS_WR_RESP_W] =
            (slv == slave_id_i) ? s_BRESP_i : {TRANS_WR_RESP_W{1'b0}};

        assign w_s_RID[(TRANS_MST_ID_W + MST_ID_W)*slv +: TRANS_MST_ID_W + MST_ID_W] =
            (slv == slave_id_i) ? s_RID_i : {(TRANS_MST_ID_W + MST_ID_W){1'b0}};
        assign w_s_RDATA[(DATA_WIDTH)*slv +: DATA_WIDTH] =
            (slv == slave_id_i) ? s_RDATA_i : {DATA_WIDTH{1'b0}};
        assign w_s_RRESP[TRANS_WR_RESP_W*slv +: TRANS_WR_RESP_W] =
            (slv == slave_id_i) ? s_RRESP_i : {TRANS_WR_RESP_W{1'b0}};
        assign w_s_RLAST[slv] =
            (slv == slave_id_i) ? s_RLAST_i : 1'b0;
    end
endgenerate
endmodule