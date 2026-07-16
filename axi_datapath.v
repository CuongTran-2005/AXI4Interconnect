module axi_datapath #(
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),
	 
	parameter                       OUTSTANDING_AMT     = 8,
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_BURST_W       = 2,
    parameter                       TRANS_DATA_LEN_W    = 8,
    parameter                       TRANS_DATA_SIZE_W   = 3,
    parameter                       TRANS_WR_RESP_W     = 2,
    parameter                       TRANS_QOS_W         = 16,
	parameter                       SLV_ID_MSB_IDX      = ADDR_WIDTH - 1,
    parameter                       SLV_ID_LSB_IDX      = ADDR_WIDTH - $clog2(SLV_AMT),
    parameter                       FIFO_DEPTH          = 16
)(
    //global signal
    input                                   ACLK_i,
    input                                   ARESETn_i,
    //Master side
    //AR 
    input   [TRANS_MST_ID_W*MST_AMT-1:0]                        m_ARID_i,
    input   [ADDR_WIDTH * MST_AMT-1:0]                          m_ARADDR_i,
    input   [TRANS_BURST_W * MST_AMT-1:0]             	        m_ARBURST_i,
    input   [TRANS_DATA_LEN_W * MST_AMT-1:0]          	        m_ARLEN_i,
    input   [TRANS_DATA_SIZE_W  * MST_AMT-1:0]                  m_ARSIZE_i,
    input   [TRANS_QOS_W * MST_AMT -1 :0]                       m_ARQOS_i,
    input   [MST_AMT-1:0]                                       m_ARVALID_i,
    output  [MST_AMT-1:0]                                       m_ARREADY_o,
    //R
    output  [TRANS_MST_ID_W * MST_AMT -1:0]                     m_RID_o,
    output  [DATA_WIDTH * MST_AMT-1:0]                          m_RDATA_o,
    output  [TRANS_WR_RESP_W * MST_AMT-1:0]                     m_RRESP_o,
    output  [MST_AMT-1:0]                                       m_RLAST_o,
    output  [MST_AMT-1:0]                                       m_RVALID_o,
    input   [MST_AMT-1:0]                                       m_RREADY_i,
    //AW
    input   [TRANS_MST_ID_W*MST_AMT -1:0]                       m_AWID_i,
    input   [ADDR_WIDTH * MST_AMT-1:0]                          m_AWADDR_i,
    input   [TRANS_BURST_W * MST_AMT-1:0]             	        m_AWBURST_i,
    input   [TRANS_DATA_LEN_W * MST_AMT-1:0]          	        m_AWLEN_i,
    input   [TRANS_DATA_SIZE_W  * MST_AMT-1:0]                  m_AWSIZE_i,
    input   [TRANS_QOS_W * MST_AMT -1 :0]                       m_AWQOS_i,
    input   [MST_AMT-1:0]                                       m_AWVALID_i,
    output  [MST_AMT-1:0]                                       m_AWREADY_o,
    //W
    input   [DATA_WIDTH * MST_AMT-1:0]                          m_WDATA_i,
    input   [MST_AMT-1:0]                                       m_WLAST_i,
    input   [MST_AMT-1:0]                                       m_WVALID_i,
    output  [MST_AMT-1:0]                                       m_WREADY_o,
    //B
    output  [TRANS_MST_ID_W*MST_AMT -1:0]                       m_BID_o,
    output  [TRANS_WR_RESP_W * MST_AMT-1:0]                     m_BRESP_o,
    output  [MST_AMT-1:0]                                       m_BVALID_o,
    input   [MST_AMT-1:0]                                       m_BREADY_i,
    //slave side
    //AR
    output   [TRANS_MST_ID_W * SLV_AMT-1:0]                     s_ARID_o, 
    output   [ADDR_WIDTH * SLV_AMT-1:0]                         s_ARADDR_o,
    output   [TRANS_BURST_W * SLV_AMT-1:0]             	        s_ARBURST_o,
    output   [TRANS_DATA_LEN_W * SLV_AMT-1:0]          	        s_ARLEN_o,
    output   [TRANS_DATA_SIZE_W  * SLV_AMT-1:0]                 s_ARSIZE_o,
    output   [TRANS_QOS_W * SLV_AMT -1 :0]                      s_ARQOS_o,
    output  [SLV_AMT-1:0]                                       s_ARVALID_o,
    input   [SLV_AMT-1:0]                                       s_ARREADY_i,
    //R
    input  [TRANS_MST_ID_W*SLV_AMT -1:0]                        s_RID_i,
    input  [DATA_WIDTH * SLV_AMT-1:0]                           s_RDATA_i,
    input  [TRANS_WR_RESP_W * SLV_AMT-1:0]                      s_RRESP_i,
    input   [SLV_AMT-1:0]                                       s_RLAST_i,
    input   [SLV_AMT-1:0]                                       s_RVALID_i,
    output  [SLV_AMT-1:0]                                       s_RREADY_o,
    //AW
    output  [TRANS_MST_ID_W*SLV_AMT -1:0]                       s_AWID_o,
    output  [ADDR_WIDTH * SLV_AMT-1:0]                          s_AWADDR_o,
    output  [TRANS_BURST_W * SLV_AMT-1:0]                       s_AWBURST_o,
    output  [TRANS_DATA_LEN_W * SLV_AMT-1:0]                    s_AWLEN_o,
    output  [TRANS_DATA_SIZE_W * SLV_AMT-1:0]                   s_AWSIZE_o,
    output   [TRANS_QOS_W * MST_AMT -1 :0]                      s_AWQOS_o,
    output  [SLV_AMT-1:0]                                       s_AWVALID_o,
    input   [SLV_AMT-1:0]                                       s_AWREADY_i,
    //W
    output  [DATA_WIDTH * SLV_AMT-1:0]                          s_WDATA_o,
    output  [SLV_AMT-1:0]                                       s_WLAST_o,
    output  [SLV_AMT-1:0]                                       s_WVALID_o,
    input   [SLV_AMT-1:0]                                       s_WREADY_i,
    //B
    input   [TRANS_MST_ID_W * SLV_AMT -1:0]                     s_BID_i,
    input   [TRANS_WR_RESP_W * SLV_AMT-1:0]                     s_BRESP_i,
    input   [SLV_AMT-1:0]                                       s_BVALID_i,
    output  [SLV_AMT-1:0]                                       s_BREADY_o,

    //=====================================================================
    // ============================control signal==========================
    //=====================================================================

    //----------master dsp-----------
	 input [SLV_ID_W * MST_AMT-1:0] 				  	            ctl_slave_id_aw_i,
    input [SLV_ID_W * MST_AMT-1:0] 				  	            ctl_slave_id_w_i,
    input [SLV_ID_W * MST_AMT-1:0] 				  	            ctl_slave_id_b_i,
    input [SLV_ID_W * MST_AMT-1:0] 					            ctl_slave_id_ar_i,
    input [SLV_ID_W * MST_AMT-1:0] 					            ctl_slave_id_r_i,
    //----------slave dsp------------
    input [MST_ID_W * SLV_AMT-1:0] 				  	            ctl_master_id_aw_i,
    input [MST_ID_W * SLV_AMT-1:0] 				  	            ctl_master_id_w_i,
    input [MST_ID_W * SLV_AMT-1:0] 				  	            ctl_master_id_b_i, 
    input [MST_ID_W * SLV_AMT-1:0] 					            ctl_master_id_ar_i,
    input [MST_ID_W * SLV_AMT-1:0] 					            ctl_master_id_r_i,

    //========signal for controler===============
    //AW, AR info for controler 
    output [(ADDR_WIDTH + TRANS_MST_ID_W + TRANS_QOS_W) * MST_AMT-1:0]        ctl_AWINFO_o,
	 output [(ADDR_WIDTH + TRANS_MST_ID_W + TRANS_QOS_W) * MST_AMT-1:0]        ctl_ARINFO_o,
    //blast, rlast for controler
    output [MST_AMT -1:0]								        ctl_mst_wlast_o,
    output [MST_AMT -1:0]								        ctl_mst_rlast_o,
    //R/B ID
    output [TRANS_MST_ID_W *SLV_AMT-1:0]                        r_trans_mst_id_o,
    output [TRANS_MST_ID_W * SLV_AMT-1:0]                       b_trans_mst_id_o,

    //========signal for arbiter ================
    output [TRANS_MST_ID_W * MST_AMT -1:0]                      r_trans_slv_id_o,
    output [TRANS_MST_ID_W * MST_AMT -1:0]                      b_trans_slv_id_o,
    
    //========signal of fifo====================
    //fifo signal for master dsp
    output [MST_AMT * SLV_AMT -1 : 0]                 r_fifo_full_o,
    output [MST_AMT * SLV_AMT -1 : 0]                 r_fifo_empty_o,
    input  [MST_AMT * SLV_AMT -1 : 0]                 r_fifo_wr_en_i,
    input  [MST_AMT * SLV_AMT -1 : 0]                 r_fifo_rd_en_i,

    output [MST_AMT * SLV_AMT -1 : 0]                 b_fifo_full_o,
    output [MST_AMT * SLV_AMT -1 : 0]                 b_fifo_empty_o,
    input  [MST_AMT * SLV_AMT -1 : 0]                 b_fifo_wr_en_i,
    input  [MST_AMT * SLV_AMT -1 : 0]                 b_fifo_rd_en_i,
    //fifo signal for slave dsp
    output [SLV_AMT * MST_AMT -1 : 0]                 ar_fifo_full_o,
    output [SLV_AMT * MST_AMT -1 : 0]                 ar_fifo_empty_o,
    input  [SLV_AMT * MST_AMT -1 : 0]                 ar_fifo_wr_en_i,
    input  [SLV_AMT * MST_AMT -1 : 0]                 ar_fifo_rd_en_i,

    output [SLV_AMT * MST_AMT -1 : 0]                 aw_fifo_full_o,
    output [SLV_AMT * MST_AMT -1 : 0]                 aw_fifo_empty_o,
    input  [SLV_AMT * MST_AMT -1 : 0]                 aw_fifo_wr_en_i,
    input  [SLV_AMT * MST_AMT -1 : 0]                 aw_fifo_rd_en_i,

    output [SLV_AMT * MST_AMT -1 : 0]                 w_fifo_full_o,
    output [SLV_AMT * MST_AMT -1 : 0]                 w_fifo_empty_o,
    input  [SLV_AMT * MST_AMT -1 : 0]                 w_fifo_wr_en_i,
    input  [SLV_AMT * MST_AMT -1 : 0]                 w_fifo_rd_en_i,

	//---------master skid buffer------------
    //valid signal for master skid buffer
    output [MST_AMT -1:0]								ctl_mst_sk_aw_valid_o,
    output [MST_AMT -1:0]								ctl_mst_sk_ar_valid_o,
    output [MST_AMT -1:0]								ctl_mst_sk_w_valid_o,
    input  [MST_AMT -1:0]								ctl_mst_sk_r_valid_i,
    input  [MST_AMT -1:0]								ctl_mst_sk_b_valid_i,
    //ready signal for master skid buffer
    input [MST_AMT -1:0]								ctl_mst_sk_aw_ready_i,
    input [MST_AMT -1:0]								ctl_mst_sk_ar_ready_i,
    input [MST_AMT -1:0]								ctl_mst_sk_w_ready_i,
    output [MST_AMT -1:0]								ctl_mst_sk_r_ready_o,
    output [MST_AMT -1:0]								ctl_mst_sk_b_ready_o,

    // -------------slave skid buffer-----------------    
    //valid signal for slave skid buffer
    input [SLV_AMT -1:0]								ctl_slv_sk_aw_valid_i,
    input [SLV_AMT -1:0]								ctl_slv_sk_ar_valid_i,
    input [SLV_AMT -1:0]								ctl_slv_sk_w_valid_i,
    output [SLV_AMT -1:0]								ctl_slv_sk_r_valid_o,
    output  [SLV_AMT -1:0]								ctl_slv_sk_b_valid_o,
    //ready signal for slave skid buffer
    output [SLV_AMT -1:0]								ctl_slv_sk_aw_ready_o,
    output [SLV_AMT -1:0]								ctl_slv_sk_ar_ready_o,
    output [SLV_AMT -1:0]								ctl_slv_sk_w_ready_o,
    input [SLV_AMT -1:0]								ctl_slv_sk_r_ready_i,
    input [SLV_AMT -1:0]								ctl_slv_sk_b_ready_i

	//  output [SLV_AMT -1:0]								ctl_slv_wlast_o,
	//  output [SLV_AMT -1:0]								ctl_slv_rlast_o,
    
	// //------------fifo req------------
	// output [MST_AMT * SLV_AMT-1:0]                    fifo_ar_req_o,
    // output [MST_AMT * SLV_AMT-1:0]                    fifo_aw_req_o,
    //master QOS signal
    // output [TRANS_QOS_W * MST_AMT-1:0]                ctl_mst_ar_qos_o, // chuyen vo AR, AWinfo cho controler
    // output [TRANS_QOS_W * MST_AMT-1:0]                ctl_mst_aw_qos_o
);
localparam AxINFO = ADDR_WIDTH + TRANS_MST_ID_W + TRANS_QOS_W;
//signal qos
//assign ctl_mst_ar_qos_o = mst_ARQOS;
//assign ctl_mst_aw_qos_o = mst_AWQOS;
//valid and ready signal master skid buffer, master dsp, slave skidbuffer, slave dsp <-> controler and arbiter 
//master skid buffer <-> controler and arbiter
assign ctl_mst_sk_aw_valid_o = mst_sk_AWVALID;
assign ctl_mst_sk_ar_valid_o = mst_sk_ARVALID;
assign ctl_mst_sk_w_valid_o = mst_sk_WVALID;
assign mst_sk_RVALID = ctl_mst_sk_r_valid_i;
assign mst_sk_BVALID = ctl_mst_sk_b_valid_i;

assign mst_sk_AWREADY = ctl_mst_sk_aw_ready_i;
assign mst_sk_ARREADY = ctl_mst_sk_ar_ready_i;
assign mst_sk_WREADY = ctl_mst_sk_w_ready_i;
assign ctl_mst_sk_r_ready_o = mst_sk_RREADY;
assign ctl_mst_sk_b_ready_o = mst_sk_BREADY;

//slave skid buffer <-> controler and arbiter
assign slv_sk_AWVALID = ctl_slv_sk_aw_valid_i;
assign slv_sk_ARVALID = ctl_slv_sk_ar_valid_i;
assign slv_sk_WVALID = ctl_slv_sk_w_valid_i;
assign ctl_slv_sk_r_valid_o = slv_sk_RVALID;
assign ctl_slv_sk_b_valid_o = slv_sk_BVALID;

assign ctl_slv_sk_aw_ready_o = slv_sk_AWREADY;
assign ctl_slv_sk_ar_ready_o = slv_sk_ARREADY;
assign ctl_slv_sk_w_ready_o = slv_sk_WREADY;
assign slv_sk_RREADY = ctl_slv_sk_r_ready_i;
assign slv_sk_BREADY = ctl_slv_sk_b_ready_i;
//output to controler
assign ctl_mst_wlast_o = mst_WLAST;
assign ctl_mst_rlast_o = mst_RLAST;

assign r_trans_mst_id_o = mst_RID;
assign b_trans_mst_id_o = mst_BID;
//output to arbiter
assign r_trans_slv_id_o = slv_RID;
assign b_trans_slv_id_o = slv_BID;

//wire master side <-> skid buffer 
//==========================================================
// Master skid <-> DSP Master
//==========================================================

//--------------- AR -----------------
wire [TRANS_MST_ID_W*MST_AMT-1:0]        mst_ARID;
wire [ADDR_WIDTH*MST_AMT-1:0]            mst_ARADDR;
wire [TRANS_BURST_W*MST_AMT-1:0]         mst_ARBURST;
wire [TRANS_DATA_LEN_W*MST_AMT-1:0]      mst_ARLEN;
wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]     mst_ARSIZE;
wire [TRANS_QOS_W * MST_AMT -1:0]        mst_ARQOS;
wire [MST_AMT-1:0]                       mst_sk_ARVALID;
wire [MST_AMT-1:0]                       mst_sk_ARREADY;

//--------------- AW -----------------
wire [TRANS_MST_ID_W*MST_AMT-1:0]        mst_AWID;
wire [ADDR_WIDTH*MST_AMT-1:0]            mst_AWADDR;
wire [TRANS_BURST_W*MST_AMT-1:0]         mst_AWBURST;
wire [TRANS_DATA_LEN_W*MST_AMT-1:0]      mst_AWLEN;
wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]     mst_AWSIZE;
wire [TRANS_QOS_W * MST_AMT -1:0]        mst_AWQOS;
wire [MST_AMT-1:0]                       mst_sk_AWVALID;
wire [MST_AMT-1:0]                       mst_sk_AWREADY;

//--------------- W ------------------
wire [DATA_WIDTH*MST_AMT-1:0]            mst_WDATA;
wire [MST_AMT-1:0]                       mst_WLAST;
wire [MST_AMT-1:0]                       mst_sk_WVALID;
wire [MST_AMT-1:0]                       mst_sk_WREADY;

//--------------- R ------------------
wire [TRANS_MST_ID_W*MST_AMT-1:0]        mst_RID;
wire [DATA_WIDTH*MST_AMT-1:0]            mst_RDATA;
wire [TRANS_WR_RESP_W*MST_AMT-1:0]       mst_RRESP;
wire [MST_AMT-1:0]                       mst_RLAST;
wire [MST_AMT-1:0]                       mst_sk_RVALID;
wire [MST_AMT-1:0]                       mst_sk_RREADY;

//--------------- B ------------------
wire [TRANS_MST_ID_W*MST_AMT-1:0]        mst_BID;
wire [TRANS_WR_RESP_W*MST_AMT-1:0]       mst_BRESP;
wire [MST_AMT-1:0]                       mst_sk_BVALID;
wire [MST_AMT-1:0]                       mst_sk_BREADY;

//==========================================================
// Crossbar : DSP Master <-> DSP Slave
// (MST_AMT x SLV_AMT)
//==========================================================

//--------------- AR -----------------
wire [TRANS_MST_ID_W*MST_AMT*SLV_AMT-1:0]      xbar_ARID;
wire [ADDR_WIDTH*MST_AMT*SLV_AMT-1:0]          xbar_ARADDR;
wire [TRANS_BURST_W*MST_AMT*SLV_AMT-1:0]       xbar_ARBURST;
wire [TRANS_DATA_LEN_W*MST_AMT*SLV_AMT-1:0]    xbar_ARLEN;
wire [TRANS_DATA_SIZE_W*MST_AMT*SLV_AMT-1:0]   xbar_ARSIZE;
wire [TRANS_QOS_W * MST_AMT*SLV_AMT -1:0]      xbar_ARQOS;

//--------------- AW -----------------
wire [TRANS_MST_ID_W*MST_AMT*SLV_AMT-1:0]      xbar_AWID;
wire [ADDR_WIDTH*MST_AMT*SLV_AMT-1:0]          xbar_AWADDR;
wire [TRANS_BURST_W*MST_AMT*SLV_AMT-1:0]       xbar_AWBURST;
wire [TRANS_DATA_LEN_W*MST_AMT*SLV_AMT-1:0]    xbar_AWLEN;
wire [TRANS_DATA_SIZE_W*MST_AMT*SLV_AMT-1:0]   xbar_AWSIZE;
wire [TRANS_QOS_W * MST_AMT*SLV_AMT -1:0]      xbar_AWQOS;

//--------------- W ------------------
wire [DATA_WIDTH*MST_AMT*SLV_AMT-1:0]          xbar_WDATA;
wire [MST_AMT*SLV_AMT-1:0]                     xbar_WLAST;

//--------------- R ------------------
wire [TRANS_MST_ID_W*MST_AMT*SLV_AMT-1:0]      xbar_RID;
wire [DATA_WIDTH*MST_AMT*SLV_AMT-1:0]          xbar_RDATA;
wire [TRANS_WR_RESP_W*MST_AMT*SLV_AMT-1:0]     xbar_RRESP;
wire [MST_AMT*SLV_AMT-1:0]                     xbar_RLAST;

//--------------- B ------------------
wire [TRANS_MST_ID_W*MST_AMT*SLV_AMT-1:0]      xbar_BID;
wire [TRANS_WR_RESP_W*MST_AMT*SLV_AMT-1:0]     xbar_BRESP;

//==========================================================
// DSP Slave <-> Slave Skid
//==========================================================

//--------------- AR -----------------
wire [TRANS_MST_ID_W*SLV_AMT-1:0]        slv_ARID;
wire [ADDR_WIDTH*SLV_AMT-1:0]            slv_ARADDR;
wire [TRANS_BURST_W*SLV_AMT-1:0]         slv_ARBURST;
wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]      slv_ARLEN;
wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]     slv_ARSIZE;
wire [TRANS_QOS_W * SLV_AMT -1:0]        slv_ARQOS;
wire [SLV_AMT-1:0]                       slv_sk_ARVALID;
wire [SLV_AMT-1:0]                       slv_sk_ARREADY;

//--------------- AW -----------------
wire [TRANS_MST_ID_W*SLV_AMT-1:0]        slv_AWID;
wire [ADDR_WIDTH*SLV_AMT-1:0]            slv_AWADDR;
wire [TRANS_BURST_W*SLV_AMT-1:0]         slv_AWBURST;
wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]      slv_AWLEN;
wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]     slv_AWSIZE;
wire [TRANS_QOS_W * SLV_AMT -1:0]        slv_AWQOS;
wire [SLV_AMT-1:0]                       slv_sk_AWVALID;
wire [SLV_AMT-1:0]                       slv_sk_AWREADY;

//--------------- W ------------------
wire [DATA_WIDTH*SLV_AMT-1:0]            slv_WDATA;
wire [SLV_AMT-1:0]                       slv_WLAST;
wire [SLV_AMT-1:0]                       slv_sk_WVALID;
wire [SLV_AMT-1:0]                       slv_sk_WREADY;

//--------------- R ------------------
wire [TRANS_MST_ID_W*SLV_AMT-1:0]        slv_RID;
wire [DATA_WIDTH*SLV_AMT-1:0]            slv_RDATA;
wire [TRANS_WR_RESP_W*SLV_AMT-1:0]       slv_RRESP;
wire [SLV_AMT-1:0]                       slv_RLAST;
wire [SLV_AMT-1:0]                       slv_sk_RVALID;
wire [SLV_AMT-1:0]                       slv_sk_RREADY;

//--------------- B ------------------
wire [TRANS_MST_ID_W*SLV_AMT-1:0]        slv_BID;
wire [TRANS_WR_RESP_W*SLV_AMT-1:0]       slv_BRESP;
wire [SLV_AMT-1:0]                       slv_sk_BVALID;
wire [SLV_AMT-1:0]                       slv_sk_BREADY;

//==========================================================
// Master Side Skid Buffer
//==========================================================

genvar mst,slv;

generate
for (mst = 0; mst < MST_AMT; mst = mst + 1)
begin : GEN_MST_SIDE_SKID
    mst_side_skid_buffer #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .TRANS_MST_ID_W     (TRANS_MST_ID_W),
        .TRANS_BURST_W      (TRANS_BURST_W),
        .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
        .TRANS_QOS_W        (TRANS_QOS_W)
    )
    u_mst_side_skid_buffer
    (
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),
        //--------------------------------------------------
        // MASTER SIDE
        //--------------------------------------------------

        //==================== AR ====================
        .m_ARID_i    (m_ARID_i[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_ARADDR_i  (m_ARADDR_i[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .m_ARBURST_i (m_ARBURST_i[(mst+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .m_ARLEN_i   (m_ARLEN_i[(mst+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .m_ARSIZE_i  (m_ARSIZE_i[(mst+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .m_ARQOS_i   (m_ARQOS_i[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .m_ARVALID_i (m_ARVALID_i[mst]),
        .m_ARREADY_o (m_ARREADY_o[mst]),

        //==================== AW ====================
        .m_AWID_i    (m_AWID_i[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_AWADDR_i  (m_AWADDR_i[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .m_AWBURST_i (m_AWBURST_i[(mst+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .m_AWLEN_i   (m_AWLEN_i[(mst+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .m_AWSIZE_i  (m_AWSIZE_i[(mst+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .m_AWQOS_i   (m_AWQOS_i[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .m_AWVALID_i (m_AWVALID_i[mst]),
        .m_AWREADY_o (m_AWREADY_o[mst]),

        //==================== W ====================
        .m_WDATA_i   (m_WDATA_i[(mst+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .m_WLAST_i   (m_WLAST_i[mst]),
        .m_WVALID_i  (m_WVALID_i[mst]),
        .m_WREADY_o  (m_WREADY_o[mst]),

        //==================== R ====================
        .m_RID_o     (m_RID_o[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_RDATA_o   (m_RDATA_o[(mst+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .m_RRESP_o   (m_RRESP_o[(mst+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .m_RLAST_o   (m_RLAST_o[mst]),
        .m_RVALID_o  (m_RVALID_o[mst]),
        .m_RREADY_i  (m_RREADY_i[mst]),

        //==================== B ====================
        .m_BID_o     (m_BID_o[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_BRESP_o   (m_BRESP_o[(mst+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .m_BVALID_o  (m_BVALID_o[mst]),
        .m_BREADY_i  (m_BREADY_i[mst]),

        //--------------------------------------------------
        // DSP SIDE
        //--------------------------------------------------

        //==================== AR ====================
        .dsp_ARID_o    (mst_ARID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_ARADDR_o  (mst_ARADDR[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .dsp_ARBURST_o (mst_ARBURST[(mst+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .dsp_ARLEN_o   (mst_ARLEN[(mst+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .dsp_ARSIZE_o  (mst_ARSIZE[(mst+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .dsp_ARQOS_o   (mst_ARQOS[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .dsp_ARVALID_o (mst_sk_ARVALID[mst]),
        .dsp_ARREADY_i (mst_sk_ARREADY[mst]),

        //==================== AW ====================
        .dsp_AWID_o    (mst_AWID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_AWADDR_o  (mst_AWADDR[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .dsp_AWBURST_o (mst_AWBURST[(mst+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .dsp_AWLEN_o   (mst_AWLEN[(mst+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .dsp_AWSIZE_o  (mst_AWSIZE[(mst+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .dsp_AWQOS_o   (mst_AWQOS[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .dsp_AWVALID_o (mst_sk_AWVALID[mst]),
        .dsp_AWREADY_i (mst_sk_AWREADY[mst]),

        //==================== W ====================
        .dsp_WDATA_o   (mst_WDATA[(mst+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .dsp_WLAST_o   (mst_WLAST[mst]),
        .dsp_WVALID_o  (mst_sk_WVALID[mst]),
        .dsp_WREADY_i  (mst_sk_WREADY[mst]),

        //==================== R ====================
        .dsp_RID_i     (mst_RID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_RDATA_i   (mst_RDATA[(mst+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .dsp_RRESP_i   (mst_RRESP[(mst+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .dsp_RLAST_i   (mst_RLAST[mst]),
        .dsp_RVALID_i  (mst_sk_RVALID[mst]),
        .dsp_RREADY_o  (mst_sk_RREADY[mst]),

        //==================== B ====================
        .dsp_BID_i     (mst_BID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_BRESP_i   (mst_BRESP[(mst+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .dsp_BVALID_i  (mst_sk_BVALID[mst]),
        .dsp_BREADY_o  (mst_sk_BREADY[mst])
    );
    assign ctl_AWINFO_o[(mst+1)*AxINFO-1 -: AxINFO]=   
            {mst_AWADDR[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH],
            mst_AWID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W], 
            mst_AWQOS[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]};
    assign ctl_ARINFO_o[(mst+1)*AxINFO-1 -: AxINFO]=   
            {mst_ARADDR[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH],
            mst_ARID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W], 
            mst_ARQOS[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]};
end
endgenerate
//==========================================================
// DSP Master Channel
//==========================================================

generate
for (mst = 0; mst < MST_AMT; mst = mst + 1)
begin : GEN_DSP_MST

    dsp_mst_channel #(
        .MST_AMT            (MST_AMT),
        .SLV_AMT            (SLV_AMT),
        .MST_ID_W           (MST_ID_W),
        .SLV_ID_W           (SLV_ID_W),
        .OUTSTANDING_AMT    (OUTSTANDING_AMT),
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .TRANS_MST_ID_W     (TRANS_MST_ID_W),
        .TRANS_BURST_W      (TRANS_BURST_W),
        .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
        .TRANS_QOS_W        (TRANS_QOS_W),
        .SLV_ID_MSB_IDX     (SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX     (SLV_ID_LSB_IDX),
        .FIFO_DEPTH         (FIFO_DEPTH)
    )
    u_dsp_mst_channel
    (
        //--------------------------------------------------
        // Global
        //--------------------------------------------------
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),

        //--------------------------------------------------
        // Controller
        //--------------------------------------------------
        .ctl_slave_id_aw_i  (ctl_slave_id_aw_i[(mst+1)*SLV_ID_W-1 -: SLV_ID_W]),
        .ctl_slave_id_w_i   (ctl_slave_id_w_i [(mst+1)*SLV_ID_W-1 -: SLV_ID_W]),
        .ctl_slave_id_b_i   (ctl_slave_id_b_i [(mst+1)*SLV_ID_W-1 -: SLV_ID_W]),
        .ctl_slave_id_ar_i  (ctl_slave_id_ar_i[(mst+1)*SLV_ID_W-1 -: SLV_ID_W]),
        .ctl_slave_id_r_i   (ctl_slave_id_r_i [(mst+1)*SLV_ID_W-1 -: SLV_ID_W]),

        .r_fifo_full_o      (r_fifo_full_o[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        .r_fifo_empty_o     (r_fifo_empty_o[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        .r_fifo_wr_en_i     (r_fifo_wr_en_i[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        .r_fifo_rd_en_i     (r_fifo_rd_en_i[(mst+1)*SLV_AMT-1 -: SLV_AMT]),

        .b_fifo_full_o      (b_fifo_full_o[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        .b_fifo_empty_o     (b_fifo_empty_o[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        .b_fifo_wr_en_i     (b_fifo_wr_en_i[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        .b_fifo_rd_en_i     (b_fifo_rd_en_i[(mst+1)*SLV_AMT-1 -: SLV_AMT]),

        //--------------------------------------------------
        // AR Master Side
        //--------------------------------------------------
        .m_ARID_i       (mst_ARID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_ARADDR_i     (mst_ARADDR[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .m_ARBURST_i    (mst_ARBURST[(mst+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .m_ARLEN_i      (mst_ARLEN[(mst+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .m_ARSIZE_i     (mst_ARSIZE[(mst+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .m_ARQOS_i      (mst_ARQOS[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
       
        //--------------------------------------------------
        // AR Slave Side
        //--------------------------------------------------
        .sa_ARID_o      (xbar_ARID[(mst+1)*TRANS_MST_ID_W*SLV_AMT-1 -: TRANS_MST_ID_W*SLV_AMT]),
        .sa_ARADDR_o    (xbar_ARADDR[(mst+1)*ADDR_WIDTH*SLV_AMT-1 -: ADDR_WIDTH*SLV_AMT]),
        .sa_ARBURST_o   (xbar_ARBURST[(mst+1)*TRANS_BURST_W*SLV_AMT-1 -: TRANS_BURST_W*SLV_AMT]),
        .sa_ARLEN_o     (xbar_ARLEN[(mst+1)*TRANS_DATA_LEN_W*SLV_AMT-1 -: TRANS_DATA_LEN_W*SLV_AMT]),
        .sa_ARSIZE_o    (xbar_ARSIZE[(mst+1)*TRANS_DATA_SIZE_W*SLV_AMT-1 -: TRANS_DATA_SIZE_W*SLV_AMT]),
        .sa_ARQOS_o      (xbar_ARQOS[(mst+1)*TRANS_QOS_W *SLV_AMT-1 -: TRANS_QOS_W *SLV_AMT]),

        //--------------------------------------------------
        // R Master Side
        //--------------------------------------------------
        .m_RID_o        (mst_RID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_RDATA_o      (mst_RDATA[(mst+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .m_RRESP_o      (mst_RRESP[(mst+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .m_RLAST_o      (mst_RLAST[mst]),
    
        //--------------------------------------------------
        // R Slave Side
        //--------------------------------------------------
        .sa_RID_i       (xbar_RID[(mst+1)*TRANS_MST_ID_W*SLV_AMT-1 -: TRANS_MST_ID_W*SLV_AMT]),
        .sa_RDATA_i     (xbar_RDATA[(mst+1)*DATA_WIDTH*SLV_AMT-1 -: DATA_WIDTH*SLV_AMT]),
        .sa_RRESP_i     (xbar_RRESP[(mst+1)*TRANS_WR_RESP_W*SLV_AMT-1 -: TRANS_WR_RESP_W*SLV_AMT]),
        .sa_RLAST_i     (xbar_RLAST[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        
        //--------------------------------------------------
        // AW Master Side
        //--------------------------------------------------
        .m_AWID_i       (mst_AWID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_AWADDR_i     (mst_AWADDR[(mst+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .m_AWBURST_i    (mst_AWBURST[(mst+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .m_AWLEN_i      (mst_AWLEN[(mst+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .m_AWSIZE_i     (mst_AWSIZE[(mst+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .m_AWQOS_i      (mst_AWQOS[(mst+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        
        //--------------------------------------------------
        // AW Slave Side
        //--------------------------------------------------
        .sa_AWID_o      (xbar_AWID[(mst+1)*TRANS_MST_ID_W*SLV_AMT-1 -: TRANS_MST_ID_W*SLV_AMT]),
        .sa_AWADDR_o    (xbar_AWADDR[(mst+1)*ADDR_WIDTH*SLV_AMT-1 -: ADDR_WIDTH*SLV_AMT]),
        .sa_AWBURST_o   (xbar_AWBURST[(mst+1)*TRANS_BURST_W*SLV_AMT-1 -: TRANS_BURST_W*SLV_AMT]),
        .sa_AWLEN_o     (xbar_AWLEN[(mst+1)*TRANS_DATA_LEN_W*SLV_AMT-1 -: TRANS_DATA_LEN_W*SLV_AMT]),
        .sa_AWSIZE_o    (xbar_AWSIZE[(mst+1)*TRANS_DATA_SIZE_W*SLV_AMT-1 -: TRANS_DATA_SIZE_W*SLV_AMT]),
        .sa_AWQOS_o      (xbar_AWQOS[(mst+1)*TRANS_QOS_W *SLV_AMT-1 -: TRANS_QOS_W *SLV_AMT]),
       
        //--------------------------------------------------
        // W
        //--------------------------------------------------
        .m_WDATA_i      (mst_WDATA[(mst+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .m_WLAST_i      (mst_WLAST[mst]),
        
        .sa_WDATA_o     (xbar_WDATA[(mst+1)*DATA_WIDTH*SLV_AMT-1 -: DATA_WIDTH*SLV_AMT]),
        .sa_WLAST_o     (xbar_WLAST[(mst+1)*SLV_AMT-1 -: SLV_AMT]),
        
        //--------------------------------------------------
        // B
        //--------------------------------------------------
        .m_BID_o        (mst_BID[(mst+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .m_BRESP_o      (mst_BRESP[(mst+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        
        .sa_BID_i       (xbar_BID[(mst+1)*TRANS_MST_ID_W*SLV_AMT-1 -: TRANS_MST_ID_W*SLV_AMT]),
        .sa_BRESP_i     (xbar_BRESP[(mst+1)*TRANS_WR_RESP_W*SLV_AMT-1 -: TRANS_WR_RESP_W*SLV_AMT])
        
    );

end
endgenerate

//==========================================================
// Crossbar Transpose : To DSP Slave
// Format : [SLV][MST]
//==========================================================

//--------------- AR -----------------
wire [TRANS_MST_ID_W*SLV_AMT*MST_AMT-1:0]      xbar_to_slv_ARID;
wire [ADDR_WIDTH*SLV_AMT*MST_AMT-1:0]          xbar_to_slv_ARADDR;
wire [TRANS_BURST_W*SLV_AMT*MST_AMT-1:0]       xbar_to_slv_ARBURST;
wire [TRANS_DATA_LEN_W*SLV_AMT*MST_AMT-1:0]    xbar_to_slv_ARLEN;
wire [TRANS_DATA_SIZE_W*SLV_AMT*MST_AMT-1:0]   xbar_to_slv_ARSIZE;
wire [TRANS_QOS_W *SLV_AMT*MST_AMT -1:0]       xbar_to_slv_ARQOS; 

//--------------- AW -----------------
wire [TRANS_MST_ID_W*SLV_AMT*MST_AMT-1:0]      xbar_to_slv_AWID;
wire [ADDR_WIDTH*SLV_AMT*MST_AMT-1:0]          xbar_to_slv_AWADDR;
wire [TRANS_BURST_W*SLV_AMT*MST_AMT-1:0]       xbar_to_slv_AWBURST;
wire [TRANS_DATA_LEN_W*SLV_AMT*MST_AMT-1:0]    xbar_to_slv_AWLEN;
wire [TRANS_DATA_SIZE_W*SLV_AMT*MST_AMT-1:0]   xbar_to_slv_AWSIZE;
wire [TRANS_QOS_W *SLV_AMT*MST_AMT -1:0]       xbar_to_slv_AWQOS;

//--------------- W ------------------
wire [DATA_WIDTH*SLV_AMT*MST_AMT-1:0]          xbar_to_slv_WDATA;
wire [SLV_AMT*MST_AMT-1:0]                     xbar_to_slv_WLAST;

//--------------- R ------------------
wire [TRANS_MST_ID_W*SLV_AMT*MST_AMT-1:0]      xbar_to_slv_RID;
wire [DATA_WIDTH*SLV_AMT*MST_AMT-1:0]          xbar_to_slv_RDATA;
wire [TRANS_WR_RESP_W*SLV_AMT*MST_AMT-1:0]     xbar_to_slv_RRESP;
wire [SLV_AMT*MST_AMT-1:0]                     xbar_to_slv_RLAST;

//--------------- B ------------------
wire [TRANS_MST_ID_W*SLV_AMT*MST_AMT-1:0]      xbar_to_slv_BID;
wire [TRANS_WR_RESP_W*SLV_AMT*MST_AMT-1:0]     xbar_to_slv_BRESP;

//transpose crossbar master-major order -> slave-major order

//==========================================================
// Crossbar Transpose
// xbar        : [Master][Slave]
// xbar_to_slv: [Slave][Master]
//==========================================================

generate
for (slv = 0; slv < SLV_AMT; slv = slv + 1) begin : GEN_XBAR_TO_SLV
    for (mst = 0; mst < MST_AMT; mst = mst + 1) begin : GEN_XBAR_TO_MST

        //---------------- AR ----------------
        assign xbar_to_slv_ARID[((slv*MST_AMT + mst)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W] =
               xbar_ARID[((mst*SLV_AMT + slv)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W];

        assign xbar_to_slv_ARADDR[((slv*MST_AMT + mst)+1)*ADDR_WIDTH-1 -: ADDR_WIDTH] =
               xbar_ARADDR[((mst*SLV_AMT + slv)+1)*ADDR_WIDTH-1 -: ADDR_WIDTH];

        assign xbar_to_slv_ARBURST[((slv*MST_AMT + mst)+1)*TRANS_BURST_W-1 -: TRANS_BURST_W] =
               xbar_ARBURST[((mst*SLV_AMT + slv)+1)*TRANS_BURST_W-1 -: TRANS_BURST_W];

        assign xbar_to_slv_ARLEN[((slv*MST_AMT + mst)+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W] =
               xbar_ARLEN[((mst*SLV_AMT + slv)+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W];

        assign xbar_to_slv_ARSIZE[((slv*MST_AMT + mst)+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W] =
               xbar_ARSIZE[((mst*SLV_AMT + slv)+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W];

        assign xbar_to_slv_ARQOS[((slv*MST_AMT + mst)+1)*TRANS_QOS_W-1 -: TRANS_QOS_W] =
               xbar_ARQOS[((mst*SLV_AMT + slv)+1)*TRANS_QOS_W-1 -: TRANS_QOS_W];

        //---------------- AW ----------------
        assign xbar_to_slv_AWID[((slv*MST_AMT + mst)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W] =
               xbar_AWID[((mst*SLV_AMT + slv)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W];

        assign xbar_to_slv_AWADDR[((slv*MST_AMT + mst)+1)*ADDR_WIDTH-1 -: ADDR_WIDTH] =
               xbar_AWADDR[((mst*SLV_AMT + slv)+1)*ADDR_WIDTH-1 -: ADDR_WIDTH];

        assign xbar_to_slv_AWBURST[((slv*MST_AMT + mst)+1)*TRANS_BURST_W-1 -: TRANS_BURST_W] =
               xbar_AWBURST[((mst*SLV_AMT + slv)+1)*TRANS_BURST_W-1 -: TRANS_BURST_W];

        assign xbar_to_slv_AWLEN[((slv*MST_AMT + mst)+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W] =
               xbar_AWLEN[((mst*SLV_AMT + slv)+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W];

        assign xbar_to_slv_AWSIZE[((slv*MST_AMT + mst)+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W] =
               xbar_AWSIZE[((mst*SLV_AMT + slv)+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W];

        assign xbar_to_slv_AWQOS[((slv*MST_AMT + mst)+1)*TRANS_QOS_W-1 -: TRANS_QOS_W] =
               xbar_AWQOS[((mst*SLV_AMT + slv)+1)*TRANS_QOS_W-1 -: TRANS_QOS_W];

        //---------------- W ----------------
        assign xbar_to_slv_WDATA[((slv*MST_AMT + mst)+1)*DATA_WIDTH-1 -: DATA_WIDTH] =
               xbar_WDATA[((mst*SLV_AMT + slv)+1)*DATA_WIDTH-1 -: DATA_WIDTH];

        assign xbar_to_slv_WLAST[slv*MST_AMT+mst] =
               xbar_WLAST[mst*SLV_AMT+slv];

        //---------------- R ----------------
        assign xbar_RID[((mst*SLV_AMT + slv)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W] =
               xbar_to_slv_RID[((slv*MST_AMT + mst)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W];

        assign xbar_RDATA[((mst*SLV_AMT + slv)+1)*DATA_WIDTH-1 -: DATA_WIDTH] =
               xbar_to_slv_RDATA[((slv*MST_AMT + mst)+1)*DATA_WIDTH-1 -: DATA_WIDTH];

        assign xbar_RRESP[((mst*SLV_AMT + slv)+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W] =
               xbar_to_slv_RRESP[((slv*MST_AMT + mst)+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W];

        assign xbar_RLAST[mst*SLV_AMT+slv] = xbar_to_slv_RLAST[slv*MST_AMT+mst];
        
        //---------------- B ----------------
        assign xbar_BID[((mst*SLV_AMT + slv)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W] =
               xbar_to_slv_BID[((slv*MST_AMT + mst)+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W];

        assign xbar_BRESP[((mst*SLV_AMT + slv)+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W] =
               xbar_to_slv_BRESP[((slv*MST_AMT + mst)+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W];

    end
end
endgenerate

//==========================================================
// DSP Slave Channel
//==========================================================


generate
for (slv = 0; slv < SLV_AMT; slv = slv + 1)
begin : GEN_DSP_SLV

    dsp_slv_channel #(
        .MST_AMT            (MST_AMT),
        .SLV_AMT            (SLV_AMT),
        .MST_ID_W           (MST_ID_W),
        .SLV_ID_W           (SLV_ID_W),
        .OUTSTANDING_AMT    (OUTSTANDING_AMT),
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .TRANS_MST_ID_W     (TRANS_MST_ID_W),
        .TRANS_BURST_W      (TRANS_BURST_W),
        .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
        .TRANS_QOS_W        (TRANS_QOS_W),
        .SLV_ID_MSB_IDX     (SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX     (SLV_ID_LSB_IDX),
        .FIFO_DEPTH         (FIFO_DEPTH)
    )
    u_dsp_slv_channel
    (
        //--------------------------------------------------
        // Global
        //--------------------------------------------------
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),

        //--------------------------------------------------
        // Controller
        //--------------------------------------------------
        .ctl_master_id_aw_i (ctl_master_id_aw_i [(slv +1) * MST_ID_W-1 -: MST_ID_W]),
        .ctl_master_id_w_i  (ctl_master_id_w_i [(slv +1) * MST_ID_W-1 -: MST_ID_W]),
        .ctl_master_id_b_i  (ctl_master_id_b_i [(slv +1) * MST_ID_W-1 -: MST_ID_W]),

        .ctl_master_id_ar_i (ctl_master_id_ar_i [(slv +1) * MST_ID_W-1 -: MST_ID_W]),
        .ctl_master_id_r_i  (ctl_master_id_r_i [(slv +1) * MST_ID_W-1 -: MST_ID_W]),

        .ar_fifo_full_o      (ar_fifo_full_o[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .ar_fifo_empty_o     (ar_fifo_empty_o[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .ar_fifo_wr_en_i     (ar_fifo_wr_en_i[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .ar_fifo_rd_en_i     (ar_fifo_rd_en_i[(slv+1)*MST_AMT-1 -: MST_AMT]),

        .aw_fifo_full_o      (aw_fifo_full_o[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .aw_fifo_empty_o     (aw_fifo_empty_o[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .aw_fifo_wr_en_i     (aw_fifo_wr_en_i[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .aw_fifo_rd_en_i     (aw_fifo_rd_en_i[(slv+1)*MST_AMT-1 -: MST_AMT]),

        .w_fifo_full_o      (w_fifo_full_o[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .w_fifo_empty_o     (w_fifo_empty_o[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .w_fifo_wr_en_i     (w_fifo_wr_en_i[(slv+1)*MST_AMT-1 -: MST_AMT]),
        .w_fifo_rd_en_i     (w_fifo_rd_en_i[(slv+1)*MST_AMT-1 -: MST_AMT]),        
        //--------------------------------------------------
        // AR Slave Side
        //--------------------------------------------------
        .s_ARID_o       (slv_ARID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_ARADDR_o     (slv_ARADDR[(slv+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .s_ARBURST_o    (slv_ARBURST[(slv+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .s_ARLEN_o      (slv_ARLEN[(slv+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .s_ARSIZE_o     (slv_ARSIZE[(slv+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .s_ARQOS_o      (slv_ARQOS[(slv+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),

        //--------------------------------------------------
        // AR Master Side
        //--------------------------------------------------
        .ma_ARID_i      (xbar_to_slv_ARID[(slv+1)*TRANS_MST_ID_W*MST_AMT-1 -: TRANS_MST_ID_W*MST_AMT]),
        .ma_ARADDR_i    (xbar_to_slv_ARADDR[(slv+1)*ADDR_WIDTH*MST_AMT-1 -: ADDR_WIDTH*MST_AMT]),
        .ma_ARBURST_i   (xbar_to_slv_ARBURST[(slv+1)*TRANS_BURST_W*MST_AMT-1 -: TRANS_BURST_W*MST_AMT]),
        .ma_ARLEN_i     (xbar_to_slv_ARLEN[(slv+1)*TRANS_DATA_LEN_W*MST_AMT-1 -: TRANS_DATA_LEN_W*MST_AMT]),
        .ma_ARSIZE_i    (xbar_to_slv_ARSIZE[(slv+1)*TRANS_DATA_SIZE_W*MST_AMT-1 -: TRANS_DATA_SIZE_W*MST_AMT]),
        .ma_ARQOS_i     (xbar_to_slv_ARQOS[(slv+1)*TRANS_QOS_W *MST_AMT-1 -: TRANS_QOS_W*MST_AMT]),
        
        //--------------------------------------------------
        // R Slave Side
        //--------------------------------------------------
        .s_RID_i        (slv_RID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_RDATA_i      (slv_RDATA[(slv+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .s_RRESP_i      (slv_RRESP[(slv+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .s_RLAST_i      (slv_RLAST[slv]),
        
        //--------------------------------------------------
        // R Master Side
        //--------------------------------------------------
        .ma_RID_o       (xbar_to_slv_RID[(slv+1)*TRANS_MST_ID_W*MST_AMT-1 -: TRANS_MST_ID_W*MST_AMT]),
        .ma_RDATA_o     (xbar_to_slv_RDATA[(slv+1)*DATA_WIDTH*MST_AMT-1 -: DATA_WIDTH*MST_AMT]),
        .ma_RRESP_o     (xbar_to_slv_RRESP[(slv+1)*TRANS_WR_RESP_W*MST_AMT-1 -: TRANS_WR_RESP_W*MST_AMT]),
        .ma_RLAST_o     (xbar_to_slv_RLAST[(slv+1)*MST_AMT-1 -: MST_AMT]),

        //--------------------------------------------------
        // AW Slave Side
        //--------------------------------------------------
        .s_AWID_o       (slv_AWID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_AWADDR_o     (slv_AWADDR[(slv+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .s_AWBURST_o    (slv_AWBURST[(slv+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .s_AWLEN_o      (slv_AWLEN[(slv+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .s_AWSIZE_o     (slv_AWSIZE[(slv+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .s_AWQOS_o      (slv_AWQOS[(slv+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),

        //--------------------------------------------------
        // AW Master Side
        //--------------------------------------------------
        .ma_AWID_i      (xbar_to_slv_AWID[(slv+1)*TRANS_MST_ID_W*MST_AMT-1 -: TRANS_MST_ID_W*MST_AMT]),
        .ma_AWADDR_i    (xbar_to_slv_AWADDR[(slv+1)*ADDR_WIDTH*MST_AMT-1 -: ADDR_WIDTH*MST_AMT]),
        .ma_AWBURST_i   (xbar_to_slv_AWBURST[(slv+1)*TRANS_BURST_W*MST_AMT-1 -: TRANS_BURST_W*MST_AMT]),
        .ma_AWLEN_i     (xbar_to_slv_AWLEN[(slv+1)*TRANS_DATA_LEN_W*MST_AMT-1 -: TRANS_DATA_LEN_W*MST_AMT]),
        .ma_AWSIZE_i    (xbar_to_slv_AWSIZE[(slv+1)*TRANS_DATA_SIZE_W*MST_AMT-1 -: TRANS_DATA_SIZE_W*MST_AMT]),
        .ma_AWQOS_i     (xbar_to_slv_AWQOS[(slv+1)*TRANS_QOS_W *MST_AMT-1 -: TRANS_QOS_W*MST_AMT]),

        //--------------------------------------------------
        // W Slave Side
        //--------------------------------------------------
        .s_WDATA_o      (slv_WDATA[(slv+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .s_WLAST_o      (slv_WLAST[slv]),

        //--------------------------------------------------
        // W Master Side
        //--------------------------------------------------
        .ma_WDATA_i     (xbar_to_slv_WDATA[(slv+1)*DATA_WIDTH*MST_AMT-1 -: DATA_WIDTH*MST_AMT]),
        .ma_WLAST_i     (xbar_to_slv_WLAST[(slv+1)*MST_AMT-1 -: MST_AMT]),

        //--------------------------------------------------
        // B Slave Side
        //--------------------------------------------------
        .s_BID_i        (slv_BID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_BRESP_i      (slv_BRESP[(slv+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        
        //--------------------------------------------------
        // B Master Side
        //--------------------------------------------------
        .ma_BID_o       (xbar_to_slv_BID[(slv+1)*TRANS_MST_ID_W*MST_AMT-1 -: TRANS_MST_ID_W*MST_AMT]),
        .ma_BRESP_o     (xbar_to_slv_BRESP[(slv+1)*TRANS_WR_RESP_W*MST_AMT-1 -: TRANS_WR_RESP_W*MST_AMT])
        
    );

end
endgenerate

//==========================================================
// Slave Side Skid Buffer
//==========================================================

generate
for (slv = 0; slv < SLV_AMT; slv = slv + 1)
begin : GEN_SLV_SKID

    slv_side_skid_buffer #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .TRANS_MST_ID_W     (TRANS_MST_ID_W),
        .TRANS_BURST_W      (TRANS_BURST_W),
        .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
        .TRANS_QOS_W        (TRANS_QOS_W)
    )
    u_slv_side_skid_buffer
    (
        //--------------------------------------------------
        // Global
        //--------------------------------------------------
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),

        //--------------------------------------------------
        // DSP SIDE
        //--------------------------------------------------

        //--------------- AR ----------------
        .dsp_ARID_i         (slv_ARID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_ARADDR_i       (slv_ARADDR[(slv+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .dsp_ARBURST_i      (slv_ARBURST[(slv+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .dsp_ARLEN_i        (slv_ARLEN[(slv+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .dsp_ARSIZE_i       (slv_ARSIZE[(slv+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .dsp_ARQOS_i        (slv_ARQOS[(slv+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .dsp_ARVALID_i      (slv_sk_ARVALID[slv]),
        .dsp_ARREADY_o      (slv_sk_ARREADY[slv]),

        //--------------- AW ----------------
        .dsp_AWID_i         (slv_AWID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_AWADDR_i       (slv_AWADDR[(slv+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .dsp_AWBURST_i      (slv_AWBURST[(slv+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .dsp_AWLEN_i        (slv_AWLEN[(slv+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .dsp_AWSIZE_i       (slv_AWSIZE[(slv+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .dsp_AWQOS_i        (slv_AWQOS[(slv+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .dsp_AWVALID_i      (slv_sk_AWVALID[slv]),
        .dsp_AWREADY_o      (slv_sk_AWREADY[slv]),

        //--------------- W -----------------
        .dsp_WDATA_i        (slv_WDATA[(slv+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .dsp_WLAST_i        (slv_WLAST[slv]),
        .dsp_WVALID_i       (slv_sk_WVALID[slv]),
        .dsp_WREADY_o       (slv_sk_WREADY[slv]),

        //--------------- R -----------------
        .dsp_RID_o          (slv_RID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_RDATA_o        (slv_RDATA[(slv+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .dsp_RRESP_o        (slv_RRESP[(slv+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .dsp_RLAST_o        (slv_RLAST[slv]),
        .dsp_RVALID_o       (slv_sk_RVALID[slv]),
        .dsp_RREADY_i       (slv_sk_RREADY[slv]),

        //--------------- B -----------------
        .dsp_BID_o          (slv_BID[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .dsp_BRESP_o        (slv_BRESP[(slv+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .dsp_BVALID_o       (slv_sk_BVALID[slv]),
        .dsp_BREADY_i       (slv_sk_BREADY[slv]),

        //--------------------------------------------------
        // SLAVE SIDE (External Slave)
        //--------------------------------------------------

        //--------------- AR ----------------
        .s_ARID_o           (s_ARID_o[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_ARADDR_o         (s_ARADDR_o[(slv+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .s_ARBURST_o        (s_ARBURST_o[(slv+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .s_ARLEN_o          (s_ARLEN_o[(slv+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .s_ARSIZE_o         (s_ARSIZE_o[(slv+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .s_ARQOS_o          (s_ARQOS_o[(slv+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .s_ARVALID_o        (s_ARVALID_o[slv]),
        .s_ARREADY_i        (s_ARREADY_i[slv]),

        //--------------- AW ----------------
        .s_AWID_o           (s_AWID_o[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_AWADDR_o         (s_AWADDR_o[(slv+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
        .s_AWBURST_o        (s_AWBURST_o[(slv+1)*TRANS_BURST_W-1 -: TRANS_BURST_W]),
        .s_AWLEN_o          (s_AWLEN_o[(slv+1)*TRANS_DATA_LEN_W-1 -: TRANS_DATA_LEN_W]),
        .s_AWSIZE_o         (s_AWSIZE_o[(slv+1)*TRANS_DATA_SIZE_W-1 -: TRANS_DATA_SIZE_W]),
        .s_AWQOS_o          (s_AWQOS_o[(slv+1)*TRANS_QOS_W-1 -: TRANS_QOS_W]),
        .s_AWVALID_o        (s_AWVALID_o[slv]),
        .s_AWREADY_i        (s_AWREADY_i[slv]),

        //--------------- W -----------------
        .s_WDATA_o          (s_WDATA_o[(slv+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .s_WLAST_o          (s_WLAST_o[slv]),
        .s_WVALID_o         (s_WVALID_o[slv]),
        .s_WREADY_i         (s_WREADY_i[slv]),

        //--------------- R -----------------
        .s_RID_i            (s_RID_i[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_RDATA_i          (s_RDATA_i[(slv+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
        .s_RRESP_i          (s_RRESP_i[(slv+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .s_RLAST_i          (s_RLAST_i[slv]),
        .s_RVALID_i         (s_RVALID_i[slv]),
        .s_RREADY_o         (s_RREADY_o[slv]),

        //--------------- B -----------------
        .s_BID_i            (s_BID_i[(slv+1)*TRANS_MST_ID_W-1 -: TRANS_MST_ID_W]),
        .s_BRESP_i          (s_BRESP_i[(slv+1)*TRANS_WR_RESP_W-1 -: TRANS_WR_RESP_W]),
        .s_BVALID_i         (s_BVALID_i[slv]),
        .s_BREADY_o         (s_BREADY_o[slv])
    );

end
endgenerate
endmodule