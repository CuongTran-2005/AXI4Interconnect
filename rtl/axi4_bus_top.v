//=============================================================================
// axi_bus_top
// -----------------------------------------------------------------------
// Khoi top gan MST_AMT axi_master_if + SLV_AMT axi_slave_if vao
// axi4_interconnect. Interface top chi gom:
//   - Global: ACLK_i, ARESETn_i
//   - Tin hieu dieu khien LOCAL (doc/ghi RAM noi) cho tung master/slave
//   - Tin hieu "set transaction" (kich hoat AR/AW) cho tung master
// Tat ca la bus phang (flatten) theo MST_AMT / SLV_AMT, giong style cua
// axi4_interconnect goc.
//
// Quy uoc ID:
//   - ID_WIDTH cua axi_master_if  = TRANS_MST_ID_W
//   - ID_WIDTH cua axi_slave_if   = MST_ID_W + TRANS_MST_ID_W (= SLV_ID_WIDTH)
//     (vi interconnect gan them MST_ID_W bit index cua master vao truoc ID
//      goc truoc khi dua toi slave, dung de dinh tuyen B/R response nguoc lai)
//=============================================================================

module axi4_bus_top #(
    parameter MST_AMT           = 4,
    parameter SLV_AMT           = 4,
    parameter DATA_WIDTH        = 16,
    parameter ADDR_WIDTH        = 16,
    parameter TRANS_MST_ID_W    = 5,
    parameter TRANS_BURST_W     = 2,
    parameter TRANS_DATA_LEN_W  = 8,
    parameter TRANS_DATA_SIZE_W = 3,
    parameter TRANS_WR_RESP_W   = 2,
    parameter TRANS_QOS_W       = 4,
    parameter OUTSTANDING_AMT   = 8,
    parameter FIFO_DEPTH        = 16,
    parameter RAM_SIZE          = 128,

    // Cac parameter suy ra, khong nen override truc tiep
    parameter MST_ID_W      = $clog2(MST_AMT),
    parameter SLV_ID_W      = $clog2(SLV_AMT),
    parameter SLV_ID_WIDTH  = MST_ID_W + TRANS_MST_ID_W,
    parameter RAM_ADDR_WIDTH = $clog2(RAM_SIZE)
)(
    //-------------------------------------------------------------------
    // Global
    //-------------------------------------------------------------------
    input  wire ACLK_i,
    input  wire ARESETn_i,

    //=====================================================================
    // MASTER SIDE - tin hieu dieu khien tu ben ngoai cho tung master (i)
    //=====================================================================
    // Doc/ghi truc tiep RAM noi cua tung master
    input  wire [RAM_ADDR_WIDTH*MST_AMT-1:0] m_address_memory_i,
    input  wire [MST_AMT-1:0]                m_READ_EN_i,
    input  wire [DATA_WIDTH*MST_AMT-1:0]     m_DATA_MEMORY_i_i,
    input  wire [MST_AMT-1:0]                m_WRITE_EN_i,
    output wire [DATA_WIDTH*MST_AMT-1:0]     m_DATA_MEMORY_o_o,

    // Kich hoat transaction READ (AR)
    input  wire [MST_AMT-1:0]                    m_ReadTrans_EN_i,
    input  wire [RAM_ADDR_WIDTH*MST_AMT-1:0]      m_r_set_addr_memory_i,
    input  wire [TRANS_MST_ID_W*MST_AMT-1:0]      m_set_ARID_i,
    input  wire [ADDR_WIDTH*MST_AMT-1:0]          m_set_ARADDR_i,
    // input  wire [TRANS_BURST_W*MST_AMT-1:0]       m_set_ARBURST_i,
    // input  wire [TRANS_DATA_LEN_W*MST_AMT-1:0]    m_set_ARLEN_i,
    // input  wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]   m_set_ARSIZE_i,
    //input  wire [TRANS_QOS_W*MST_AMT-1:0]         m_set_ARQOS_i,

    // Kich hoat transaction WRITE (AW)
    input  wire [MST_AMT-1:0]                    m_WriteTrans_EN_i,
    input  wire [RAM_ADDR_WIDTH*MST_AMT-1:0]      m_w_set_addr_memory_i,
    input  wire [TRANS_MST_ID_W*MST_AMT-1:0]      m_set_AWID_i,
    input  wire [ADDR_WIDTH*MST_AMT-1:0]          m_set_AWADDR_i,
    // input  wire [TRANS_BURST_W*MST_AMT-1:0]       m_set_AWBURST_i,
    // input  wire [TRANS_DATA_LEN_W*MST_AMT-1:0]    m_set_AWLEN_i,
    // input  wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]   m_set_AWSIZE_i,
    //input  wire [TRANS_QOS_W*MST_AMT-1:0]         m_set_AWQOS_i,

    //=====================================================================
    // SLAVE SIDE - tin hieu dieu khien tu ben ngoai cho tung slave (j)
    //=====================================================================
    input  wire [RAM_ADDR_WIDTH*SLV_AMT-1:0] s_address_memory_i,
    input  wire [SLV_AMT-1:0]                s_READ_EN_i,
    input  wire [DATA_WIDTH*SLV_AMT-1:0]     s_DATA_MEMORY_i_i,
    input  wire [SLV_AMT-1:0]                s_WRITE_EN_i,
    output wire [DATA_WIDTH*SLV_AMT-1:0]     s_DATA_MEMORY_o_o
);

    //=========================================================================
    // Wire noi giua axi4_interconnect <-> tung axi_master_if / axi_slave_if
    //=========================================================================

    //   wire [RAM_ADDR_WIDTH*MST_AMT-1:0] m_address_memory_i;
    //   //wire [MST_AMT-1:0]                m_READ_EN_i;
    //   wire [DATA_WIDTH*MST_AMT-1:0]     m_DATA_MEMORY_i_i;
    //   //wire [MST_AMT-1:0]                m_WRITE_EN_i;
    //  wire [DATA_WIDTH*MST_AMT-1:0]     m_DATA_MEMORY_o_o;

    // // Kich hoat transaction READ (AR)
    //   //wire [MST_AMT-1:0]                    m_ReadTrans_EN_i;
    //   wire [RAM_ADDR_WIDTH*MST_AMT-1:0]      m_r_set_addr_memory_i;
    //   wire [TRANS_MST_ID_W*MST_AMT-1:0]      m_set_ARID_i;
    //   wire [ADDR_WIDTH*MST_AMT-1:0]          m_set_ARADDR_i;
      wire [TRANS_BURST_W*MST_AMT-1:0]       m_set_ARBURST_i;
      wire [TRANS_DATA_LEN_W*MST_AMT-1:0]    m_set_ARLEN_i;
      wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]   m_set_ARSIZE_i;
       wire [TRANS_QOS_W*MST_AMT-1:0]         m_set_ARQOS_i;

    // // Kich hoat transaction WRITE (AW)
    //   //wire [MST_AMT-1:0]                    m_WriteTrans_EN_i;
    //   wire [RAM_ADDR_WIDTH*MST_AMT-1:0]      m_w_set_addr_memory_i;
    //   wire [TRANS_MST_ID_W*MST_AMT-1:0]      m_set_AWID_i;
    //   wire [ADDR_WIDTH*MST_AMT-1:0]          m_set_AWADDR_i;
      wire [TRANS_BURST_W*MST_AMT-1:0]       m_set_AWBURST_i;
      wire [TRANS_DATA_LEN_W*MST_AMT-1:0]    m_set_AWLEN_i;
      wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]   m_set_AWSIZE_i;
       wire [TRANS_QOS_W*MST_AMT-1:0]         m_set_AWQOS_i;

    // //=====================================================================
    // // SLAVE SIDE - tin hieu dieu khien tu ben ngoai cho tung slave (j)
    // //=====================================================================
    //   wire [RAM_ADDR_WIDTH*SLV_AMT-1:0] s_address_memory_i;
    //   //wire [SLV_AMT-1:0]                s_READ_EN_i;
    //   wire [DATA_WIDTH*SLV_AMT-1:0]     s_DATA_MEMORY_i_i;
    //   //wire [SLV_AMT-1:0]                s_WRITE_EN_i;
    //  wire [DATA_WIDTH*SLV_AMT-1:0]     s_DATA_MEMORY_o_o;

    //  //=====================================================================
    // // Gia tri mac dinh (tie-off = 0) cho cac wire input con lai
    // //=====================================================================
    // assign m_address_memory_i     = {RAM_ADDR_WIDTH*MST_AMT{1'b0}};
    // assign m_DATA_MEMORY_i_i      = {DATA_WIDTH*MST_AMT{1'b0}};

    // // Kich hoat transaction READ (AR)
    // assign m_r_set_addr_memory_i  = {RAM_ADDR_WIDTH*MST_AMT{1'b0}};
    // assign m_set_ARID_i           = {TRANS_MST_ID_W*MST_AMT{1'b0}};
    // assign m_set_ARADDR_i         = {ADDR_WIDTH*MST_AMT{1'b0}};
     assign m_set_ARBURST_i        = {TRANS_BURST_W*MST_AMT{4'b0101}};
     assign m_set_ARLEN_i          = {TRANS_DATA_LEN_W*MST_AMT{1'b0}};
     assign m_set_ARSIZE_i         = {TRANS_DATA_SIZE_W*MST_AMT{1'b0}};
     assign m_set_ARQOS_i          = {TRANS_QOS_W*MST_AMT{1'b0}};

    // // Kich hoat transaction WRITE (AW)
    // assign m_w_set_addr_memory_i  = {RAM_ADDR_WIDTH*MST_AMT{1'b0}};
    // assign m_set_AWID_i           = {TRANS_MST_ID_W*MST_AMT{1'b0}};
    // assign m_set_AWADDR_i         = {ADDR_WIDTH*MST_AMT{1'b0}};
     assign m_set_AWBURST_i        = {TRANS_BURST_W*MST_AMT{4'b0101}};
     assign m_set_AWLEN_i          = {TRANS_DATA_LEN_W*MST_AMT{1'b0}};
     assign m_set_AWSIZE_i         = {TRANS_DATA_SIZE_W*MST_AMT{1'b0}};
     assign m_set_AWQOS_i          = {TRANS_QOS_W*MST_AMT{1'b0}};

    // //=====================================================================
    // // SLAVE SIDE
    // //=====================================================================
    // assign s_address_memory_i     = {RAM_ADDR_WIDTH*SLV_AMT{1'b0}};
    // assign s_DATA_MEMORY_i_i      = {DATA_WIDTH*SLV_AMT{1'b0}};

    // m_DATA_MEMORY_o_o, s_DATA_MEMORY_o_o: KHONG assign - la output, do
    // axi_master_if / axi_slave_if lai ra khi noi instance that.

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
    wire [SLV_ID_WIDTH*SLV_AMT-1:0]      w_s_AWID;
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

    wire [SLV_ID_WIDTH*SLV_AMT-1:0]      w_s_BID;
    wire [TRANS_WR_RESP_W*SLV_AMT-1:0]   w_s_BRESP;
    wire [SLV_AMT-1:0]                   w_s_BVALID;
    wire [SLV_AMT-1:0]                   w_s_BREADY;

    wire [SLV_ID_WIDTH*SLV_AMT-1:0]      w_s_ARID;
    wire [ADDR_WIDTH*SLV_AMT-1:0]        w_s_ARADDR;
    wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]  w_s_ARLEN;
    wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0] w_s_ARSIZE;
    wire [TRANS_BURST_W*SLV_AMT-1:0]     w_s_ARBURST;
    wire [TRANS_QOS_W*SLV_AMT-1:0]       w_s_ARQOS;
    wire [SLV_AMT-1:0]                   w_s_ARVALID;
    wire [SLV_AMT-1:0]                   w_s_ARREADY;

    wire [SLV_ID_WIDTH*SLV_AMT-1:0]      w_s_RID;
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

    //=========================================================================
    // Generate: MST_AMT khoi axi_master_if
    //=========================================================================
    genvar i;
    generate
        for (i = 0; i < MST_AMT; i = i + 1) begin : gen_master

            axi_master_if #(
                .ID_WIDTH   (TRANS_MST_ID_W),
                .ADDR_WIDTH (ADDR_WIDTH),
                .DATA_WIDTH (DATA_WIDTH),
                .RAM_SIZE   (RAM_SIZE)
            ) u_master_if (
                .ACLK_i    (ACLK_i),
                .ARESETn_i (ARESETn_i),

                //---------------- Local RAM control ----------------
                .m_address_memory (m_address_memory_i[RAM_ADDR_WIDTH*i +: RAM_ADDR_WIDTH]),
                .m_READ_EN        (m_READ_EN_i[i]),
                .m_DATA_MEMORY_i  (m_DATA_MEMORY_i_i[DATA_WIDTH*i +: DATA_WIDTH]),
                .m_WRITE_EN       (m_WRITE_EN_i[i]),
                .m_DATA_MEMORY_o  (m_DATA_MEMORY_o_o[DATA_WIDTH*i +: DATA_WIDTH]),

                //---------------- Transaction READ ------------------
                .ReadTrans_EN_i   (m_ReadTrans_EN_i[i]),
                .r_set_addr_memory(m_r_set_addr_memory_i[RAM_ADDR_WIDTH*i +: RAM_ADDR_WIDTH]),
                .set_ARID_i       (m_set_ARID_i[TRANS_MST_ID_W*i +: TRANS_MST_ID_W]),
                .set_ARADDR_i     (m_set_ARADDR_i[ADDR_WIDTH*i +: ADDR_WIDTH]),
                .set_ARBURST_i    (m_set_ARBURST_i[TRANS_BURST_W*i +: TRANS_BURST_W]),
                .set_ARLEN_i      (m_set_ARLEN_i[TRANS_DATA_LEN_W*i +: TRANS_DATA_LEN_W]),
                .set_ARSIZE_i     (m_set_ARSIZE_i[TRANS_DATA_SIZE_W*i +: TRANS_DATA_SIZE_W]),
                .set_ARQOS_i      (m_set_ARQOS_i[TRANS_QOS_W*i +: TRANS_QOS_W]),

                //---------------- Transaction WRITE -----------------
                .WriteTrans_EN_i  (m_WriteTrans_EN_i[i]),
                .w_set_addr_memory(m_w_set_addr_memory_i[RAM_ADDR_WIDTH*i +: RAM_ADDR_WIDTH]),
                .set_AWID_i       (m_set_AWID_i[TRANS_MST_ID_W*i +: TRANS_MST_ID_W]),
                .set_AWADDR_i     (m_set_AWADDR_i[ADDR_WIDTH*i +: ADDR_WIDTH]),
                .set_AWBURST_i    (m_set_AWBURST_i[TRANS_BURST_W*i +: TRANS_BURST_W]),
                .set_AWLEN_i      (m_set_AWLEN_i[TRANS_DATA_LEN_W*i +: TRANS_DATA_LEN_W]),
                .set_AWSIZE_i     (m_set_AWSIZE_i[TRANS_DATA_SIZE_W*i +: TRANS_DATA_SIZE_W]),
                .set_AWQOS_i      (m_set_AWQOS_i[TRANS_QOS_W*i +: TRANS_QOS_W]),

                //---------------- AXI4 - Write Address ---------------
                .m_AWVALID_o (w_m_AWVALID[i]),
                .m_AWID_o    (w_m_AWID[TRANS_MST_ID_W*i +: TRANS_MST_ID_W]),
                .m_AWADDR_o  (w_m_AWADDR[ADDR_WIDTH*i +: ADDR_WIDTH]),
                .m_AWBURST_o (w_m_AWBURST[TRANS_BURST_W*i +: TRANS_BURST_W]),
                .m_AWLEN_o   (w_m_AWLEN[TRANS_DATA_LEN_W*i +: TRANS_DATA_LEN_W]),
                .m_AWSIZE_o  (w_m_AWSIZE[TRANS_DATA_SIZE_W*i +: TRANS_DATA_SIZE_W]),
                .m_AWQOS_o   (w_m_AWQOS[TRANS_QOS_W*i +: TRANS_QOS_W]),
                .m_AWREADY_i (w_m_AWREADY[i]),

                //---------------- AXI4 - Write Data -------------------
                .m_WVALID_o (w_m_WVALID[i]),
                .m_WDATA_o  (w_m_WDATA[DATA_WIDTH*i +: DATA_WIDTH]),
                .m_WLAST_o  (w_m_WLAST[i]),
                .m_WREADY_i (w_m_WREADY[i]),

                //---------------- AXI4 - Write Response ---------------
                .m_BVALID_i (w_m_BVALID[i]),
                .m_BID_i    (w_m_BID[TRANS_MST_ID_W*i +: TRANS_MST_ID_W]),
                .m_BRESP_i  (w_m_BRESP[TRANS_WR_RESP_W*i +: TRANS_WR_RESP_W]),
                .m_BREADY_o (w_m_BREADY[i]),

                //---------------- AXI4 - Read Address -----------------
                .m_ARVALID_o (w_m_ARVALID[i]),
                .m_ARID_o    (w_m_ARID[TRANS_MST_ID_W*i +: TRANS_MST_ID_W]),
                .m_ARADDR_o  (w_m_ARADDR[ADDR_WIDTH*i +: ADDR_WIDTH]),
                .m_ARBURST_o (w_m_ARBURST[TRANS_BURST_W*i +: TRANS_BURST_W]),
                .m_ARLEN_o   (w_m_ARLEN[TRANS_DATA_LEN_W*i +: TRANS_DATA_LEN_W]),
                .m_ARSIZE_o  (w_m_ARSIZE[TRANS_DATA_SIZE_W*i +: TRANS_DATA_SIZE_W]),
                .m_ARQOS_o   (w_m_ARQOS[TRANS_QOS_W*i +: TRANS_QOS_W]),
                .m_ARREADY_i (w_m_ARREADY[i]),

                //---------------- AXI4 - Read Data --------------------
                .m_RVALID_i (w_m_RVALID[i]),
                .m_RLAST_i  (w_m_RLAST[i]),
                .m_RID_i    (w_m_RID[TRANS_MST_ID_W*i +: TRANS_MST_ID_W]),
                .m_RDATA_i  (w_m_RDATA[DATA_WIDTH*i +: DATA_WIDTH]),
                .m_RRESP_i  (w_m_RRESP[TRANS_WR_RESP_W*i +: TRANS_WR_RESP_W]),
                .m_RREADY_o (w_m_RREADY[i])
            );

        end
    endgenerate

    //=========================================================================
    // Generate: SLV_AMT khoi axi_slave_if
    //=========================================================================
    genvar j;
    generate
        for (j = 0; j < SLV_AMT; j = j + 1) begin : gen_slave

            axi_slave_if #(
                .ID_WIDTH   (SLV_ID_WIDTH),
                .ADDR_WIDTH (ADDR_WIDTH),
                .DATA_WIDTH (DATA_WIDTH),
                .RAM_SIZE   (RAM_SIZE)
            ) u_slave_if (
                .ACLK_i    (ACLK_i),
                .ARESETn_i (ARESETn_i),

                //---------------- Local RAM control ----------------
                .s_address_memory (s_address_memory_i[RAM_ADDR_WIDTH*j +: RAM_ADDR_WIDTH]),
                .s_READ_EN        (s_READ_EN_i[j]),
                .s_DATA_MEMORY_i  (s_DATA_MEMORY_i_i[DATA_WIDTH*j +: DATA_WIDTH]),
                .s_WRITE_EN       (s_WRITE_EN_i[j]),
                .s_DATA_MEMORY_o  (s_DATA_MEMORY_o_o[DATA_WIDTH*j +: DATA_WIDTH]),

                //---------------- AXI4 - Write Address ---------------
                .s_AWVALID_i (w_s_AWVALID[j]),
                .s_AWID_i    (w_s_AWID[SLV_ID_WIDTH*j +: SLV_ID_WIDTH]),
                .s_AWADDR_i  (w_s_AWADDR[ADDR_WIDTH*j +: ADDR_WIDTH]),
                .s_AWLEN_i   (w_s_AWLEN[TRANS_DATA_LEN_W*j +: TRANS_DATA_LEN_W]),
                .s_AWBURST_i (w_s_AWBURST[TRANS_BURST_W*j +: TRANS_BURST_W]),
                .s_AWSIZE_i  (w_s_AWSIZE[TRANS_DATA_SIZE_W*j +: TRANS_DATA_SIZE_W]),
                .s_AWQOS_i   (w_s_AWQOS[TRANS_QOS_W*j +: TRANS_QOS_W]),
                .s_AWREADY_o (w_s_AWREADY[j]),

                //---------------- AXI4 - Write Data -------------------
                .s_WVALID_i (w_s_WVALID[j]),
                .s_WDATA_i  (w_s_WDATA[DATA_WIDTH*j +: DATA_WIDTH]),
                .s_WLAST_i  (w_s_WLAST[j]),
                .s_WREADY_o (w_s_WREADY[j]),

                //---------------- AXI4 - Write Response ---------------
                .s_BVALID_o (w_s_BVALID[j]),
                .s_BID_o    (w_s_BID[SLV_ID_WIDTH*j +: SLV_ID_WIDTH]),
                .s_BRESP_o  (w_s_BRESP[TRANS_WR_RESP_W*j +: TRANS_WR_RESP_W]),
                .s_BREADY_i (w_s_BREADY[j]),

                //---------------- AXI4 - Read Address -----------------
                .s_ARVALID_i (w_s_ARVALID[j]),
                .s_ARID_i    (w_s_ARID[SLV_ID_WIDTH*j +: SLV_ID_WIDTH]),
                .s_ARADDR_i  (w_s_ARADDR[ADDR_WIDTH*j +: ADDR_WIDTH]),
                .s_ARLEN_i   (w_s_ARLEN[TRANS_DATA_LEN_W*j +: TRANS_DATA_LEN_W]),
                .s_ARBURST_i (w_s_ARBURST[TRANS_BURST_W*j +: TRANS_BURST_W]),
                .s_ARSIZE_i  (w_s_ARSIZE[TRANS_DATA_SIZE_W*j +: TRANS_DATA_SIZE_W]),
                .s_ARQOS_i   (w_s_ARQOS[TRANS_QOS_W*j +: TRANS_QOS_W]),
                .s_ARREADY_o (w_s_ARREADY[j]),

                //---------------- AXI4 - Read Data --------------------
                .s_RVALID_o (w_s_RVALID[j]),
                .s_RLAST_o  (w_s_RLAST[j]),
                .s_RID_o    (w_s_RID[SLV_ID_WIDTH*j +: SLV_ID_WIDTH]),
                .s_RDATA_o  (w_s_RDATA[DATA_WIDTH*j +: DATA_WIDTH]),
                .s_RRESP_o  (w_s_RRESP[TRANS_WR_RESP_W*j +: TRANS_WR_RESP_W]),
                .s_RREADY_i (w_s_RREADY[j])
            );

        end
    endgenerate

endmodule