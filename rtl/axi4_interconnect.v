`timescale 1ns / 1ps

module axi4_interconnect #(
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
    //----------------------------------------------------------------------
    // Global
    //----------------------------------------------------------------------
    input  wire                                         ACLK_i,
    input  wire                                         ARESETn_i,

    //======================================================================
    // MASTER SIDE
    //======================================================================

    //------------------------- AW Channel -------------------------
    input  wire [TRANS_MST_ID_W*MST_AMT-1:0]            m_AWID_i,
    input  wire [ADDR_WIDTH*MST_AMT-1:0]                m_AWADDR_i,
    input  wire [TRANS_DATA_LEN_W*MST_AMT-1:0]          m_AWLEN_i,
    input  wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]         m_AWSIZE_i,
    input  wire [TRANS_BURST_W*MST_AMT-1:0]             m_AWBURST_i,
    input  wire [TRANS_QOS_W*MST_AMT-1:0]               m_AWQOS_i,
    input  wire [MST_AMT-1:0]                           m_AWVALID_i,
    output wire [MST_AMT-1:0]                           m_AWREADY_o,

    //------------------------- W Channel --------------------------
    input  wire [DATA_WIDTH*MST_AMT-1:0]                m_WDATA_i,
    input  wire [MST_AMT-1:0]                           m_WLAST_i,
    input  wire [MST_AMT-1:0]                           m_WVALID_i,
    output wire [MST_AMT-1:0]                           m_WREADY_o,

    //------------------------- B Channel --------------------------
    output wire [TRANS_MST_ID_W*MST_AMT-1:0]            m_BID_o,
    output wire [TRANS_WR_RESP_W*MST_AMT-1:0]           m_BRESP_o,
    output wire [MST_AMT-1:0]                           m_BVALID_o,
    input  wire [MST_AMT-1:0]                           m_BREADY_i,

    //------------------------- AR Channel -------------------------
    input  wire [TRANS_MST_ID_W*MST_AMT-1:0]            m_ARID_i,
    input  wire [ADDR_WIDTH*MST_AMT-1:0]                m_ARADDR_i,
    input  wire [TRANS_DATA_LEN_W*MST_AMT-1:0]          m_ARLEN_i,
    input  wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]         m_ARSIZE_i,
    input  wire [TRANS_BURST_W*MST_AMT-1:0]             m_ARBURST_i,
    input  wire [TRANS_QOS_W*MST_AMT-1:0]               m_ARQOS_i,
    input  wire [MST_AMT-1:0]                           m_ARVALID_i,
    output wire [MST_AMT-1:0]                           m_ARREADY_o,

    //------------------------- R Channel --------------------------
    output wire [TRANS_MST_ID_W*MST_AMT-1:0]            m_RID_o,
    output wire [DATA_WIDTH*MST_AMT-1:0]                m_RDATA_o,
    output wire [TRANS_WR_RESP_W*MST_AMT-1:0]           m_RRESP_o,
    output wire [MST_AMT-1:0]                           m_RLAST_o,
    output wire [MST_AMT-1:0]                           m_RVALID_o,
    input  wire [MST_AMT-1:0]                           m_RREADY_i,

    //======================================================================
    // SLAVE SIDE
    //======================================================================

    //------------------------- AW Channel -------------------------
    output wire [(MST_ID_W+TRANS_MST_ID_W)*SLV_AMT-1:0]            s_AWID_o,
    output wire [ADDR_WIDTH*SLV_AMT-1:0]                s_AWADDR_o,
    output wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]          s_AWLEN_o,
    output wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]         s_AWSIZE_o,
    output wire [TRANS_BURST_W*SLV_AMT-1:0]             s_AWBURST_o,
    output wire [TRANS_QOS_W*SLV_AMT-1:0]               s_AWQOS_o,
    output wire [SLV_AMT-1:0]                           s_AWVALID_o,
    input  wire [SLV_AMT-1:0]                           s_AWREADY_i,

    //------------------------- W Channel --------------------------
    output wire [DATA_WIDTH*SLV_AMT-1:0]                s_WDATA_o,
    output wire [SLV_AMT-1:0]                           s_WLAST_o,
    output wire [SLV_AMT-1:0]                           s_WVALID_o,
    input  wire [SLV_AMT-1:0]                           s_WREADY_i,

    //------------------------- B Channel --------------------------
    input  wire [(MST_ID_W+TRANS_MST_ID_W)*SLV_AMT-1:0]            s_BID_i,
    input  wire [TRANS_WR_RESP_W*SLV_AMT-1:0]           s_BRESP_i,
    input  wire [SLV_AMT-1:0]                           s_BVALID_i,
    output wire [SLV_AMT-1:0]                           s_BREADY_o,

    //------------------------- AR Channel -------------------------
    output wire [(MST_ID_W+TRANS_MST_ID_W)*SLV_AMT-1:0]            s_ARID_o,
    output wire [ADDR_WIDTH*SLV_AMT-1:0]                s_ARADDR_o,
    output wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]          s_ARLEN_o,
    output wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]         s_ARSIZE_o,
    output wire [TRANS_BURST_W*SLV_AMT-1:0]             s_ARBURST_o,
    output wire [TRANS_QOS_W*SLV_AMT-1:0]               s_ARQOS_o,
    output wire [SLV_AMT-1:0]                           s_ARVALID_o,
    input  wire [SLV_AMT-1:0]                           s_ARREADY_i,

    //------------------------- R Channel --------------------------
    input  wire [(MST_ID_W+TRANS_MST_ID_W)*SLV_AMT-1:0]            s_RID_i,
    input  wire [DATA_WIDTH*SLV_AMT-1:0]                s_RDATA_i,
    input  wire [TRANS_WR_RESP_W*SLV_AMT-1:0]           s_RRESP_i,
    input  wire [SLV_AMT-1:0]                           s_RLAST_i,
    input  wire [SLV_AMT-1:0]                           s_RVALID_i,
    output wire [SLV_AMT-1:0]                           s_RREADY_o

);

    //=====================================================================
    // Controller <-> Datapath
    //=====================================================================

    // Slave ID (Controller -> Datapath)
    wire [SLV_ID_W*MST_AMT-1:0]      ctl_slave_id_aw;
    wire [SLV_ID_W*MST_AMT-1:0]      ctl_slave_id_w;
    wire [SLV_ID_W*MST_AMT-1:0]      ctl_slave_id_b;
    wire [SLV_ID_W*MST_AMT-1:0]      ctl_slave_id_ar;
    wire [SLV_ID_W*MST_AMT-1:0]      ctl_slave_id_r;

    // Master ID (Arbiter -> Datapath)
    wire [MST_ID_W*SLV_AMT-1:0]      ctl_master_id_aw;
    wire [MST_ID_W*SLV_AMT-1:0]      ctl_master_id_w;
    wire [MST_ID_W*SLV_AMT-1:0]      ctl_master_id_b;
    wire [MST_ID_W*SLV_AMT-1:0]      ctl_master_id_ar;
    wire [MST_ID_W*SLV_AMT-1:0]      ctl_master_id_r;

    // AW/AR information (Datapath -> Controller)
    wire [(ADDR_WIDTH+TRANS_MST_ID_W+TRANS_QOS_W)*MST_AMT-1:0]
                                            ctl_mst_AWINFO;

    wire [(ADDR_WIDTH+TRANS_MST_ID_W+TRANS_QOS_W)*MST_AMT-1:0]
                                            ctl_mst_ARINFO;

    // Last signals
    wire [MST_AMT-1:0]              ctl_mst_wlast;
    wire [MST_AMT-1:0]              ctl_mst_rlast;

    // Transaction ID
    wire [TRANS_MST_ID_W*SLV_AMT * MST_AMT-1:0] r_trans_mst_id;
    wire [TRANS_MST_ID_W*SLV_AMT * MST_AMT-1:0] b_trans_mst_id;

    wire [(MST_ID_W+TRANS_MST_ID_W)*SLV_AMT-1:0] r_trans_slv_id;
    wire [(MST_ID_W+TRANS_MST_ID_W)*SLV_AMT-1:0] b_trans_slv_id;

    // QoS
    wire [TRANS_QOS_W*MST_AMT*SLV_AMT-1:0]  ctl_slv_AWQOS;
    wire [TRANS_QOS_W*MST_AMT*SLV_AMT-1:0]  ctl_slv_ARQOS;

    //=====================================================================
    // FIFO Signals
    //=====================================================================

    //---------------- AW FIFO ----------------
    wire [SLV_AMT*MST_AMT-1:0]      aw_fifo_full;
    wire [SLV_AMT*MST_AMT-1:0]      aw_fifo_empty;
    wire [SLV_AMT*MST_AMT-1:0]      aw_fifo_wr_en;
    wire [SLV_AMT*MST_AMT-1:0]      aw_fifo_rd_en;

    wire [MST_AMT * SLV_AMT - 1 : 0] aw_fifo_wr_en_xbar;

    //---------------- W FIFO ----------------
    wire [SLV_AMT*MST_AMT-1:0]      w_fifo_full;
    wire [SLV_AMT*MST_AMT-1:0]      w_fifo_empty;
    wire [SLV_AMT*MST_AMT-1:0]      w_fifo_wr_en;
    wire [SLV_AMT*MST_AMT-1:0]      w_fifo_rd_en;

    wire [MST_AMT * SLV_AMT - 1 : 0] w_fifo_wr_en_xbar;

    //---------------- AR FIFO ----------------
    wire [SLV_AMT*MST_AMT-1:0]      ar_fifo_full;
    wire [SLV_AMT*MST_AMT-1:0]      ar_fifo_empty;
    wire [SLV_AMT*MST_AMT-1:0]      ar_fifo_wr_en;
    wire [SLV_AMT*MST_AMT-1:0]      ar_fifo_rd_en;

    wire [MST_AMT * SLV_AMT - 1 : 0] ar_fifo_wr_en_xbar;

    //---------------- B FIFO ----------------
    wire [MST_AMT*SLV_AMT-1:0]      b_fifo_full;
    wire [MST_AMT*SLV_AMT-1:0]      b_fifo_empty;
    wire [MST_AMT*SLV_AMT-1:0]      b_fifo_wr_en;
    wire [MST_AMT*SLV_AMT-1:0]      b_fifo_rd_en;

    wire [MST_AMT * SLV_AMT - 1 : 0] b_fifo_wr_en_xbar;
    //---------------- R FIFO ----------------
    wire [MST_AMT*SLV_AMT-1:0]      r_fifo_full;
    wire [MST_AMT*SLV_AMT-1:0]      r_fifo_empty;
    wire [MST_AMT*SLV_AMT-1:0]      r_fifo_wr_en;
    wire [MST_AMT*SLV_AMT-1:0]      r_fifo_rd_en;

    wire [MST_AMT * SLV_AMT - 1 : 0] r_fifo_wr_en_xbar;

    //=====================================================================
    // Master Skid Buffer Control
    //=====================================================================

    wire [MST_AMT-1:0]              ctl_mst_sk_aw_valid;
    wire [MST_AMT-1:0]              ctl_mst_sk_ar_valid;
    wire [MST_AMT-1:0]              ctl_mst_sk_w_valid;

    wire [MST_AMT-1:0]              ctl_mst_sk_r_valid;
    wire [MST_AMT-1:0]              ctl_mst_sk_b_valid;

    wire [MST_AMT-1:0]              ctl_mst_sk_aw_ready;
    wire [MST_AMT-1:0]              ctl_mst_sk_ar_ready;
    wire [MST_AMT-1:0]              ctl_mst_sk_w_ready;

    wire [MST_AMT-1:0]              ctl_mst_sk_r_ready;
    wire [MST_AMT-1:0]              ctl_mst_sk_b_ready;

    //=====================================================================
    // Slave Skid Buffer Control
    //=====================================================================

    wire [SLV_AMT-1:0]              ctl_slv_sk_aw_valid;
    wire [SLV_AMT-1:0]              ctl_slv_sk_ar_valid;
    wire [SLV_AMT-1:0]              ctl_slv_sk_w_valid;

    wire [SLV_AMT-1:0]              ctl_slv_sk_r_valid;
    wire [SLV_AMT-1:0]              ctl_slv_sk_b_valid;

    wire [SLV_AMT-1:0]              ctl_slv_sk_aw_ready;
    wire [SLV_AMT-1:0]              ctl_slv_sk_ar_ready;
    wire [SLV_AMT-1:0]              ctl_slv_sk_w_ready;

    wire [SLV_AMT-1:0]              ctl_slv_sk_r_ready;
    wire [SLV_AMT-1:0]              ctl_slv_sk_b_ready;


    //=====================================================================
    // Datapath
    //=====================================================================
    axi_datapath #(
        .MST_AMT                (MST_AMT),
        .SLV_AMT                (SLV_AMT),
        .MST_ID_W               (MST_ID_W),
        .SLV_ID_W               (SLV_ID_W),

        .OUTSTANDING_AMT        (OUTSTANDING_AMT),
        .DATA_WIDTH             (DATA_WIDTH),
        .ADDR_WIDTH             (ADDR_WIDTH),

        .TRANS_MST_ID_W         (TRANS_MST_ID_W),
        .TRANS_BURST_W          (TRANS_BURST_W),
        .TRANS_DATA_LEN_W       (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W      (TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W        (TRANS_WR_RESP_W),
        .TRANS_QOS_W            (TRANS_QOS_W),

        .SLV_ID_MSB_IDX         (ADDR_WIDTH-1),
        .SLV_ID_LSB_IDX         (ADDR_WIDTH-$clog2(SLV_AMT)),

        .FIFO_DEPTH             (FIFO_DEPTH)
    )
    u_axi_datapath
    (
        //----------------------------------------------------------------------
        // Global
        //----------------------------------------------------------------------
        .ACLK_i                 (ACLK_i),
        .ARESETn_i              (ARESETn_i),

        //----------------------------------------------------------------------
        // Master Side
        //----------------------------------------------------------------------
        // AR
        .m_ARID_i               (m_ARID_i),
        .m_ARADDR_i             (m_ARADDR_i),
        .m_ARBURST_i            (m_ARBURST_i),
        .m_ARLEN_i              (m_ARLEN_i),
        .m_ARSIZE_i             (m_ARSIZE_i),
        .m_ARQOS_i              (m_ARQOS_i),
        .m_ARVALID_i            (m_ARVALID_i),
        .m_ARREADY_o            (m_ARREADY_o),

        // R
        .m_RID_o                (m_RID_o),
        .m_RDATA_o              (m_RDATA_o),
        .m_RRESP_o              (m_RRESP_o),
        .m_RLAST_o              (m_RLAST_o),
        .m_RVALID_o             (m_RVALID_o),
        .m_RREADY_i             (m_RREADY_i),

        // AW
        .m_AWID_i               (m_AWID_i),
        .m_AWADDR_i             (m_AWADDR_i),
        .m_AWBURST_i            (m_AWBURST_i),
        .m_AWLEN_i              (m_AWLEN_i),
        .m_AWSIZE_i             (m_AWSIZE_i),
        .m_AWQOS_i              (m_AWQOS_i),
        .m_AWVALID_i            (m_AWVALID_i),
        .m_AWREADY_o            (m_AWREADY_o),

        // W
        .m_WDATA_i              (m_WDATA_i),
        .m_WLAST_i              (m_WLAST_i),
        .m_WVALID_i             (m_WVALID_i),
        .m_WREADY_o             (m_WREADY_o),

        // B
        .m_BID_o                (m_BID_o),
        .m_BRESP_o              (m_BRESP_o),
        .m_BVALID_o             (m_BVALID_o),
        .m_BREADY_i             (m_BREADY_i),

        //----------------------------------------------------------------------
        // Slave Side
        //----------------------------------------------------------------------
        // AR
        .s_ARID_o               (s_ARID_o),
        .s_ARADDR_o             (s_ARADDR_o),
        .s_ARBURST_o            (s_ARBURST_o),
        .s_ARLEN_o              (s_ARLEN_o),
        .s_ARSIZE_o             (s_ARSIZE_o),
        .s_ARQOS_o              (s_ARQOS_o),
        .s_ARVALID_o            (s_ARVALID_o),
        .s_ARREADY_i            (s_ARREADY_i),

        // R
        .s_RID_i                (s_RID_i),
        .s_RDATA_i              (s_RDATA_i),
        .s_RRESP_i              (s_RRESP_i),
        .s_RLAST_i              (s_RLAST_i),
        .s_RVALID_i             (s_RVALID_i),
        .s_RREADY_o             (s_RREADY_o),

        // AW
        .s_AWID_o               (s_AWID_o),
        .s_AWADDR_o             (s_AWADDR_o),
        .s_AWBURST_o            (s_AWBURST_o),
        .s_AWLEN_o              (s_AWLEN_o),
        .s_AWSIZE_o             (s_AWSIZE_o),
        .s_AWQOS_o              (s_AWQOS_o),
        .s_AWVALID_o            (s_AWVALID_o),
        .s_AWREADY_i            (s_AWREADY_i),

        // W
        .s_WDATA_o              (s_WDATA_o),
        .s_WLAST_o              (s_WLAST_o),
        .s_WVALID_o             (s_WVALID_o),
        .s_WREADY_i             (s_WREADY_i),

        // B
        .s_BID_i                (s_BID_i),
        .s_BRESP_i              (s_BRESP_i),
        .s_BVALID_i             (s_BVALID_i),
        .s_BREADY_o             (s_BREADY_o),

        //----------------------------------------------------------------------
        // Controller Interface
        //----------------------------------------------------------------------
        .ctl_slave_id_aw_i      (ctl_slave_id_aw),
        .ctl_slave_id_w_i       (ctl_slave_id_w),
        .ctl_slave_id_b_i       (ctl_slave_id_b),
        .ctl_slave_id_ar_i      (ctl_slave_id_ar),
        .ctl_slave_id_r_i       (ctl_slave_id_r),

        .ctl_master_id_aw_i     (ctl_master_id_aw),
        .ctl_master_id_w_i      (ctl_master_id_w),
        .ctl_master_id_b_i      (ctl_master_id_b),
        .ctl_master_id_ar_i     (ctl_master_id_ar),
        .ctl_master_id_r_i      (ctl_master_id_r),

        .ctl_mst_AWINFO_o       (ctl_mst_AWINFO),
        .ctl_mst_ARINFO_o       (ctl_mst_ARINFO),

        .ctl_mst_wlast_o        (ctl_mst_wlast),
        .ctl_mst_rlast_o        (ctl_mst_rlast),

        .r_trans_mst_id_o       (r_trans_mst_id),
        .b_trans_mst_id_o       (b_trans_mst_id),

        //----------------------------------------------------------------------
        // Arbiter Interface
        //----------------------------------------------------------------------
        .r_trans_slv_id_o       (r_trans_slv_id),
        .b_trans_slv_id_o       (b_trans_slv_id),

        .ctl_slv_AWQOS_o        (ctl_slv_AWQOS),
        .ctl_slv_ARQOS_o        (ctl_slv_ARQOS),

        //----------------------------------------------------------------------
        // FIFO
        //----------------------------------------------------------------------
        .r_fifo_full_o          (r_fifo_full),
        .r_fifo_empty_o         (r_fifo_empty),
        .r_fifo_wr_en_i         (r_fifo_wr_en_xbar),
        .r_fifo_rd_en_i         (r_fifo_rd_en),

        .b_fifo_full_o          (b_fifo_full),
        .b_fifo_empty_o         (b_fifo_empty),
        .b_fifo_wr_en_i         (b_fifo_wr_en_xbar),
        .b_fifo_rd_en_i         (b_fifo_rd_en),

        .ar_fifo_full_o         (ar_fifo_full),
        .ar_fifo_empty_o        (ar_fifo_empty),
        .ar_fifo_wr_en_i        (ar_fifo_wr_en_xbar),
        .ar_fifo_rd_en_i        (ar_fifo_rd_en),

        .aw_fifo_full_o         (aw_fifo_full),
        .aw_fifo_empty_o        (aw_fifo_empty),
        .aw_fifo_wr_en_i        (aw_fifo_wr_en_xbar),
        .aw_fifo_rd_en_i        (aw_fifo_rd_en),

        .w_fifo_full_o          (w_fifo_full),
        .w_fifo_empty_o         (w_fifo_empty),
        .w_fifo_wr_en_i         (w_fifo_wr_en_xbar),
        .w_fifo_rd_en_i         (w_fifo_rd_en),

        //----------------------------------------------------------------------
        // Master Skid Buffer
        //----------------------------------------------------------------------
        .ctl_mst_sk_aw_valid_o  (ctl_mst_sk_aw_valid),
        .ctl_mst_sk_ar_valid_o  (ctl_mst_sk_ar_valid),
        .ctl_mst_sk_w_valid_o   (ctl_mst_sk_w_valid),

        .ctl_mst_sk_r_valid_i   (ctl_mst_sk_r_valid),
        .ctl_mst_sk_b_valid_i   (ctl_mst_sk_b_valid),

        .ctl_mst_sk_aw_ready_i  (ctl_mst_sk_aw_ready),
        .ctl_mst_sk_ar_ready_i  (ctl_mst_sk_ar_ready),
        .ctl_mst_sk_w_ready_i   (ctl_mst_sk_w_ready),

        .ctl_mst_sk_r_ready_o   (ctl_mst_sk_r_ready),
        .ctl_mst_sk_b_ready_o   (ctl_mst_sk_b_ready),

        //----------------------------------------------------------------------
        // Slave Skid Buffer
        //----------------------------------------------------------------------
        .ctl_slv_sk_aw_valid_i  (ctl_slv_sk_aw_valid),
        .ctl_slv_sk_ar_valid_i  (ctl_slv_sk_ar_valid),
        .ctl_slv_sk_w_valid_i   (ctl_slv_sk_w_valid),

        .ctl_slv_sk_r_valid_o   (ctl_slv_sk_r_valid),
        .ctl_slv_sk_b_valid_o   (ctl_slv_sk_b_valid),

        .ctl_slv_sk_aw_ready_o  (ctl_slv_sk_aw_ready),
        .ctl_slv_sk_ar_ready_o  (ctl_slv_sk_ar_ready),
        .ctl_slv_sk_w_ready_o   (ctl_slv_sk_w_ready),

        .ctl_slv_sk_r_ready_i   (ctl_slv_sk_r_ready),
        .ctl_slv_sk_b_ready_i   (ctl_slv_sk_b_ready)
    );

    //=====================================================================
    // Controller (One controller per Master)
    //=====================================================================
    genvar m;
    generate
        for (m = 0; m < MST_AMT; m = m + 1) begin : GEN_CONTROLLER

            controller #(
                .SLAVE_NUM                     (SLV_AMT),
                .SLAVE_ID_WIDTH                (SLV_ID_W),
                .ADDR_WIDTH                    (ADDR_WIDTH),
                .TRANSACTION_ID_WIDTH          (TRANS_MST_ID_W),
                .QOS_WIDTH                     (TRANS_QOS_W),
                .AXINFO_WIDTH                  (ADDR_WIDTH + TRANS_MST_ID_W + TRANS_QOS_W),
                .MAX_OUTSTANDING_TRANSACTION   (OUTSTANDING_AMT)
            )
            u_controller (

                //----------------------------------------------------------
                // Global
                //----------------------------------------------------------
                .clk                (ACLK_i),
                .rst_n              (ARESETn_i),

                //----------------------------------------------------------
                // Dispatch side input
                //----------------------------------------------------------
                .AW_fifo_full_i     (
                    aw_fifo_full[m*SLV_AMT +: SLV_AMT]
                ),

                .W_fifo_full_i      (
                    w_fifo_full[m*SLV_AMT +: SLV_AMT]
                ),

                .AR_fifo_full_i     (
                    ar_fifo_full[m*SLV_AMT +: SLV_AMT]
                ),

                .B_last_i           (1'b1),

                .B_trans_ID_i       (
                    b_trans_mst_id [m*(TRANS_MST_ID_W*SLV_AMT) +: (TRANS_MST_ID_W*SLV_AMT)]
                ),

                .B_empty_i          (
                    b_fifo_empty[m*SLV_AMT +: SLV_AMT]
                ),

                .R_last_i           (ctl_mst_rlast[m]),

                .R_trans_ID_i       (
                    r_trans_mst_id [m*(TRANS_MST_ID_W*SLV_AMT) +: (TRANS_MST_ID_W*SLV_AMT)]
                ),

                .R_empty_i          (
                    r_fifo_empty[m*SLV_AMT +: SLV_AMT]
                ),

                //----------------------------------------------------------
                // Dispatch side output
                //----------------------------------------------------------
                .AW_slave_id_o      (
                    ctl_slave_id_aw[(m+1)*SLV_ID_W-1 -: SLV_ID_W]
                ),

                .W_slave_id_o       (
                    ctl_slave_id_w[(m+1)*SLV_ID_W-1 -: SLV_ID_W]
                ),

                .AR_slave_id_o      (
                    ctl_slave_id_ar[(m+1)*SLV_ID_W-1 -: SLV_ID_W]
                ),

                .B_one_hot_grant_o  (
                    b_fifo_rd_en[m*SLV_AMT +: SLV_AMT]
                ),

                .B_slave_id_o(
                    ctl_slave_id_b[(m+1)*SLV_ID_W-1 -: SLV_ID_W]
                ),
                
                .R_one_hot_grant_o  (
                    r_fifo_rd_en[m*SLV_AMT +: SLV_AMT]
                ),
                
                .R_slave_id_o(
                    ctl_slave_id_r[(m+1)*SLV_ID_W-1 -: SLV_ID_W]
                ),
                .AW_fifo_write_o    (
                    aw_fifo_wr_en[m*SLV_AMT +: SLV_AMT]
                ),

                .W_fifo_write_o     (
                    w_fifo_wr_en[m*SLV_AMT +: SLV_AMT]
                ),

                .AR_fifo_write_o    (
                    ar_fifo_wr_en[m*SLV_AMT +: SLV_AMT]
                ),

                //----------------------------------------------------------
                // Master side input
                //----------------------------------------------------------
                .AW_infor_i         (
                    ctl_mst_AWINFO[(m+1)*(ADDR_WIDTH+TRANS_MST_ID_W+TRANS_QOS_W)-1
                                    -:(ADDR_WIDTH+TRANS_MST_ID_W+TRANS_QOS_W)]
                ),

                .AR_infor_i         (
                    ctl_mst_ARINFO[(m+1)*(ADDR_WIDTH+TRANS_MST_ID_W+TRANS_QOS_W)-1
                                    -:(ADDR_WIDTH+TRANS_MST_ID_W+TRANS_QOS_W)]
                ),

                .AW_valid_i         (
                    ctl_mst_sk_aw_valid[m]
                ),

                .W_valid_i          (
                    ctl_mst_sk_w_valid[m]
                ),

                .B_ready_i          (
                    ctl_mst_sk_b_ready[m]
                ),

                .AR_valid_i         (
                    ctl_mst_sk_ar_valid[m]
                ),

                .R_ready_i          (
                    ctl_mst_sk_r_ready[m]
                ),

                .W_last_i           (
                    ctl_mst_wlast[m]
                ),

                //----------------------------------------------------------
                // Master side output
                //----------------------------------------------------------
                .AW_ready_o         (
                    ctl_mst_sk_aw_ready[m]
                ),

                .W_ready_o          (
                    ctl_mst_sk_w_ready[m]
                ),

                .B_valid_o          (
                    ctl_mst_sk_b_valid[m]
                ),

                .AR_ready_o         (
                    ctl_mst_sk_ar_ready[m]
                ),

                .R_valid_o          (
                    ctl_mst_sk_r_valid[m]
                )

            );

        end
    endgenerate
//write fifo en xbar for slv dsp
genvar mst, slv;
generate
    for (slv = 0; slv < SLV_AMT; slv = slv + 1) begin : GEN_SLV
        for (mst = 0; mst < MST_AMT; mst = mst + 1) begin : GEN_MST
            assign aw_fifo_wr_en_xbar[slv*MST_AMT + mst] = aw_fifo_wr_en[mst*SLV_AMT + slv];
            assign ar_fifo_wr_en_xbar[slv*MST_AMT + mst] = ar_fifo_wr_en[mst*SLV_AMT + slv];
            assign w_fifo_wr_en_xbar[slv*MST_AMT + mst] = w_fifo_wr_en[mst*SLV_AMT + slv];
        end
    end
endgenerate


//=====================================================================
// Arbiter (One Arbiter per Slave)
//=====================================================================
    genvar s;
    generate
        for (s = 0; s < SLV_AMT; s = s + 1) begin : GEN_ARBITER

            arbiter_top #(
                .SLAVE_TRANSACTION_ID_WIDTH    (TRANS_MST_ID_W+MST_ID_W),
                .MASTER_NUM                    (MST_AMT),
                .MASTER_ID_WIDTH               (MST_ID_W),
                .QOS_WIDTH                     (TRANS_QOS_W),
                .MAX_OUTSTANDING_TRANSACTION   (OUTSTANDING_AMT)
            )
            u_arbiter (

                //----------------------------------------------------------
                // Global
                //----------------------------------------------------------
                .clk                    (ACLK_i),
                .rst_n                  (ARESETn_i),

                //----------------------------------------------------------
                // Dispatch Side
                //----------------------------------------------------------
                .AW_fifo_empty_i        (
                    aw_fifo_empty[s*MST_AMT +: MST_AMT]
                ),

                .AW_qos_i               (
                    ctl_slv_AWQOS[(s+1)*TRANS_QOS_W*MST_AMT-1 -: TRANS_QOS_W*MST_AMT]
                ),

                .W_fifo_empty_i         (
                    w_fifo_empty[s*MST_AMT +: MST_AMT]
                ),

                .B_fifo_full_i          (
                    b_fifo_full[s*MST_AMT +: MST_AMT]
                ),

                .AR_fifo_empty_i        (
                    ar_fifo_empty[s*MST_AMT +: MST_AMT]
                ),

                .R_fifo_full_i          (
                    r_fifo_full[s*MST_AMT +: MST_AMT]
                ),

                .AR_qos_i               (
                    ctl_slv_ARQOS[(s+1)*TRANS_QOS_W*MST_AMT-1 -: TRANS_QOS_W*MST_AMT]
                ),

                //----------------------------------------------------------
                // Dispatch Outputs
                //----------------------------------------------------------
                .AW_fifo_read_o         (
                    aw_fifo_rd_en[s*MST_AMT +: MST_AMT]
                ),

                .W_fifo_read_o          (
                    w_fifo_rd_en[s*MST_AMT +: MST_AMT]
                ),

                .B_fifo_write_o         (
                    b_fifo_wr_en[s*MST_AMT +: MST_AMT]
                ),

                .AR_fifo_read_o         (
                    ar_fifo_rd_en[s*MST_AMT +: MST_AMT]
                ),

                .R_fifo_write_o         (
                    r_fifo_wr_en[s*MST_AMT +: MST_AMT]
                ),

                .AW_master_id_o         (
                    ctl_master_id_aw[(s+1)*MST_ID_W-1 -: MST_ID_W]
                ),

                .W_master_id_o          (
                    ctl_master_id_w[(s+1)*MST_ID_W-1 -: MST_ID_W]
                ),

                .B_master_id_o          (
                    ctl_master_id_b[(s+1)*MST_ID_W-1 -: MST_ID_W]
                ),

                .AR_master_id_o         (
                    ctl_master_id_ar[(s+1)*MST_ID_W-1 -: MST_ID_W]
                ),

                .R_master_id_o          (
                    ctl_master_id_r[(s+1)*MST_ID_W-1 -: MST_ID_W]
                ),

                //----------------------------------------------------------
                // Slave Side
                //----------------------------------------------------------
                .AW_ready_i             (
                    ctl_slv_sk_aw_ready[s]
                ),

                .AR_ready_i             (
                    ctl_slv_sk_ar_ready[s]
                ),

                .W_ready_i              (
                    ctl_slv_sk_w_ready[s]
                ),

                .W_last_i               (
                    s_WLAST_o[s]
                ),

                .B_valid_i              (
                    ctl_slv_sk_b_valid[s]
                ),

                .R_valid_i              (
                    ctl_slv_sk_r_valid[s]
                ),

                .B_ID_i                 (
                    b_trans_slv_id[(s+1)*(MST_ID_W+TRANS_MST_ID_W)-1 -:
                                TRANS_MST_ID_W+MST_ID_W]
                ),

                .R_ID_i                 (
                    r_trans_slv_id[(s+1)*(MST_ID_W+TRANS_MST_ID_W)-1 -:
                                TRANS_MST_ID_W+MST_ID_W]
                ),

                //----------------------------------------------------------
                // Slave Outputs
                //----------------------------------------------------------
                .AW_valid_o             (
                    ctl_slv_sk_aw_valid[s]
                ),

                .AR_valid_o             (
                    ctl_slv_sk_ar_valid[s]
                ),

                .W_valid_o              (
                    ctl_slv_sk_w_valid[s]
                ),

                .B_ready_o              (
                    ctl_slv_sk_b_ready[s]
                ),

                .R_ready_o              (
                    ctl_slv_sk_r_ready[s]
                )

            );

        end
    endgenerate 
    // write fifo crossbar for master dsp
    generate
        for (slv = 0; slv < SLV_AMT; slv = slv + 1) begin : GEN_SLV_M
            for (mst = 0; mst < MST_AMT; mst = mst + 1) begin : GEN_MST_M
                assign r_fifo_wr_en_xbar[mst*SLV_AMT + slv] = r_fifo_wr_en[slv*MST_AMT + mst];
                assign b_fifo_wr_en_xbar[mst*SLV_AMT + slv] = b_fifo_wr_en[slv*MST_AMT + mst];
            end
        end
    endgenerate
endmodule