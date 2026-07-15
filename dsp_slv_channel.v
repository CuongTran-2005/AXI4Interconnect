module dsp_slv_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),
	 
	parameter                       OUTSTANDING_AMT     = 8,
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_BURST_W       = 2,
    parameter                       TRANS_DATA_LEN_W    = 3,
    parameter                       TRANS_DATA_SIZE_W   = 3,
    parameter                       TRANS_WR_RESP_W     = 2,
    parameter                       TRANS_QOS_W         =16,

	parameter                       SLV_ID_MSB_IDX      = ADDR_WIDTH - 1,
    parameter                       SLV_ID_LSB_IDX      = ADDR_WIDTH - $clog2(SLV_AMT),
    parameter                       FIFO_DEPTH          = 16
)(
	//global signal
	input                                   ACLK_i,
    input                                   ARESETn_i,
	//control signal
	input [MST_ID_W-1:0] 				  	ctl_master_id_aw_i,
    input [MST_ID_W-1:0] 				  	ctl_master_id_w_i,
    input [MST_ID_W-1:0] 				  	ctl_master_id_b_i,
	 
    input [MST_ID_W-1:0] 					ctl_master_id_ar_i,
    input [MST_ID_W-1:0] 					ctl_master_id_r_i,

    //fifo signal
    output [MST_AMT -1 : 0]                 ar_fifo_full_o,
    output [MST_AMT -1 : 0]                 ar_fifo_empty_o,
    input  [MST_AMT -1 : 0]                 ar_fifo_wr_en_i,
    input  [MST_AMT -1 : 0]                 ar_fifo_rd_en_i,

    output [MST_AMT -1 : 0]                 aw_fifo_full_o,
    output [MST_AMT -1 : 0]                 aw_fifo_empty_o,
    input  [MST_AMT -1 : 0]                 aw_fifo_wr_en_i,
    input  [MST_AMT -1 : 0]                 aw_fifo_rd_en_i,

    output [MST_AMT -1 : 0]                 w_fifo_full_o,
    output [MST_AMT -1 : 0]                 w_fifo_empty_o,
    input  [MST_AMT -1 : 0]                 w_fifo_wr_en_i,
    input  [MST_AMT -1 : 0]                 w_fifo_rd_en_i,

    //R/B ID
    // output [TRANS_MST_ID_W-1:0]                 r_trans_mst_id, //bo
    // output [TRANS_MST_ID_W-1:0]                 b_trans_mst_id,
	//fifo req
	// output [MST_AMT-1:0]                        fifo_ar_req, //bo
    // output [MST_AMT-1:0]                        fifo_aw_req,
    //-----AR dsp_slv channel------
	 //slave side fixed
	output   [TRANS_MST_ID_W-1:0]                       s_ARID_o, 
    output   [ADDR_WIDTH-1:0]                           s_ARADDR_o,
    output   [TRANS_BURST_W-1:0]             	        s_ARBURST_o,
    output   [TRANS_DATA_LEN_W-1:0]          	        s_ARLEN_o,
    output   [TRANS_DATA_SIZE_W -1:0]                   s_ARSIZE_o,
    output   [TRANS_QOS_W-1:0]                          s_ARQOS_o,
    // output                                              s_ARVALID_o,
    // input                                               s_ARREADY_i,
    // master side fixed
    input   [TRANS_MST_ID_W * MST_AMT-1:0]              ma_ARID_i,
    input   [ADDR_WIDTH * MST_AMT-1:0]                  ma_ARADDR_i,
    input   [TRANS_BURST_W * MST_AMT-1:0]               ma_ARBURST_i,
    input   [TRANS_DATA_LEN_W * MST_AMT-1:0]            ma_ARLEN_i,
    input   [TRANS_DATA_SIZE_W * MST_AMT-1:0]           ma_ARSIZE_i,
    input   [TRANS_QOS_W *MST_AMT-1:0]                  ma_ARQOS_i,
    // input   [MST_AMT -1:0]                              ma_ARVALID_i,
    // output  [MST_AMT -1:0]                              ma_ARREADY_o,
	 //-----R dsp_mst channel------
	 //slave side fixed
	input  [TRANS_MST_ID_W-1:0]    s_RID_i,
    input  [DATA_WIDTH-1:0]        s_RDATA_i,
    input  [TRANS_WR_RESP_W-1:0]   s_RRESP_i,
    input                          s_RLAST_i,
    // input                          s_RVALID_i,
    // output                           s_RREADY_o,
	// Master side fixed
    output  [TRANS_MST_ID_W*MST_AMT-1:0]      ma_RID_o,
    output  [DATA_WIDTH*MST_AMT-1:0]          ma_RDATA_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]     ma_RRESP_o,
    output  [MST_AMT-1:0]                     ma_RLAST_o,
    // output  [MST_AMT-1:0]                     ma_RVALID_o,
    // input   [MST_AMT-1:0]                     ma_RREADY_i,
	 //-----AW dsp_mst channel -------
    // Slave side fixed
    output  [TRANS_MST_ID_W-1:0]      s_AWID_o,
    output  [ADDR_WIDTH-1:0]          s_AWADDR_o,
    output  [TRANS_BURST_W-1:0]       s_AWBURST_o,
    output  [TRANS_DATA_LEN_W-1:0]    s_AWLEN_o,
    output  [TRANS_DATA_SIZE_W-1:0]   s_AWSIZE_o,
    output   [TRANS_QOS_W-1:0]        s_AWQOS_o,
    // output                            s_AWVALID_o,
    // input                             s_AWREADY_i,

    // Master side fixed
    input   [TRANS_MST_ID_W*MST_AMT-1:0]      ma_AWID_i,
    input   [ADDR_WIDTH*MST_AMT-1:0]          ma_AWADDR_i,
    input   [TRANS_BURST_W*MST_AMT-1:0]       ma_AWBURST_i,
    input   [TRANS_DATA_LEN_W*MST_AMT-1:0]    ma_AWLEN_i,
    input   [TRANS_DATA_SIZE_W*MST_AMT-1:0]   ma_AWSIZE_i,
    input   [TRANS_QOS_W *MST_AMT-1:0]        ma_AWQOS_i,
    // input   [MST_AMT-1:0]                     ma_AWVALID_i,
    // output  [MST_AMT-1:0]                     ma_AWREADY_o,
	 //-----W dsp_mst channel -------
        // Slave side fixed
    output  [DATA_WIDTH-1:0]          s_WDATA_o,
    output                            s_WLAST_o,
    // output                            s_WVALID_o,
    // input                             s_WREADY_i,

    // Master side fixed
    input   [DATA_WIDTH*MST_AMT-1:0]  ma_WDATA_i,
    input   [MST_AMT-1:0]             ma_WLAST_i,
    // input   [MST_AMT-1:0]             ma_WVALID_i,
    // output  [MST_AMT-1:0]             ma_WREADY_o,
	 //----B dsp_mst channel --------
	  // Master interface
    // Slave side fixed
    input   [TRANS_MST_ID_W-1:0]      s_BID_i,
    input   [TRANS_WR_RESP_W-1:0]     s_BRESP_i,
    // input                             s_BVALID_i,
    // output                            s_BREADY_o,

    // Master side fixed
    output  [TRANS_MST_ID_W*MST_AMT-1:0]      ma_BID_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]     ma_BRESP_o
    // output  [MST_AMT-1:0]                     ma_BVALID_o,
    // input   [MST_AMT-1:0]                     ma_BREADY_i
);

// FIFO WIDTH
localparam AR_FIFO_WIDTH =
            TRANS_MST_ID_W +
            ADDR_WIDTH +
            TRANS_BURST_W +
            TRANS_DATA_LEN_W +
            TRANS_DATA_SIZE_W +
            TRANS_QOS_W;

localparam AW_FIFO_WIDTH =
            TRANS_MST_ID_W +
            ADDR_WIDTH +
            TRANS_BURST_W +
            TRANS_DATA_LEN_W +
            TRANS_DATA_SIZE_W +
            TRANS_QOS_W;

localparam W_FIFO_WIDTH =
            DATA_WIDTH +
            1;

localparam R_FIFO_WIDTH =
            TRANS_MST_ID_W +
            DATA_WIDTH +
            TRANS_WR_RESP_W +
            1;

localparam B_FIFO_WIDTH =
            TRANS_MST_ID_W +
            TRANS_WR_RESP_W;
//wire

//AR channel

// FIFO internal signals
wire [AR_FIFO_WIDTH-1:0] ar_fifo_data_o [MST_AMT-1:0];
wire [MST_AMT-1:0] ar_fifo_empty;
wire [MST_AMT-1:0] ar_fifo_full;
wire [TRANS_MST_ID_W -1:0] s_ARID_o_mux;
// FIFO -> AR_dsp_slv_channel

wire [TRANS_MST_ID_W*MST_AMT-1:0]      fifo_ARID_o;
wire [ADDR_WIDTH*MST_AMT-1:0]          fifo_ARADDR_o;
wire [TRANS_BURST_W*MST_AMT-1:0]       fifo_ARBURST_o;
wire [TRANS_DATA_LEN_W*MST_AMT-1:0]    fifo_ARLEN_o;
wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]   fifo_ARSIZE_o;
wire [TRANS_QOS_W*MST_AMT-1:0]          fifo_ARQOS_o;


// wire [MST_AMT-1:0] fifo_ARVALID_o;
// wire [MST_AMT-1:0] fifo_ARREADY_i;
// FIFO control
wire [MST_AMT-1:0] ar_fifo_wr_en;
wire [MST_AMT-1:0] ar_fifo_rd_en;

genvar ar_idx;
// Generate one FIFO per master
generate
for(ar_idx = 0; ar_idx < MST_AMT; ar_idx = ar_idx + 1)
begin : AR_FIFO_GEN

    fifo #(
        .DATA_WIDTH(AR_FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_AR_fifo (
        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        // Push từ Master
        .data_i(
            {
                ma_ARID_i[ar_idx*TRANS_MST_ID_W +: TRANS_MST_ID_W],
                ma_ARADDR_i[ar_idx*ADDR_WIDTH +:ADDR_WIDTH],
                ma_ARBURST_i[ar_idx*TRANS_BURST_W +: TRANS_BURST_W],
                ma_ARLEN_i[ar_idx*TRANS_DATA_LEN_W +:TRANS_DATA_LEN_W],
                ma_ARSIZE_i[ar_idx*TRANS_DATA_SIZE_W +:TRANS_DATA_SIZE_W],
                ma_ARQOS_i[ar_idx*TRANS_QOS_W +:TRANS_QOS_W]
            }
        ),
        .wr_valid_i(
            ar_fifo_wr_en[ar_idx]
        ),
        // Pop bởi AR_dsp_slv_channel
        .rd_valid_i(
            ar_fifo_rd_en[ar_idx]
        ),
        .data_o(
            ar_fifo_data_o[ar_idx]
        ),
        .empty_o          (ar_fifo_empty[ar_idx]),
        .full_o           (ar_fifo_full[ar_idx]),
        .almost_empty_o   (),
        .almost_full_o    (),
        .counter          ()
    );

end
endgenerate
// FIFO handshake
assign ar_fifo_wr_en = ar_fifo_wr_en_i;
assign ar_fifo_rd_en = ar_fifo_rd_en_i;
assign ar_fifo_full_o = ar_fifo_full;
assign ar_fifo_empty_o = ar_fifo_empty;

// FIFO unpack
generate
for(ar_idx = 0; ar_idx < MST_AMT; ar_idx = ar_idx + 1)
begin : AR_FIFO_UNPACK
    assign {
        fifo_ARID_o[ar_idx*TRANS_MST_ID_W +: TRANS_MST_ID_W],
        fifo_ARADDR_o[ar_idx*ADDR_WIDTH +: ADDR_WIDTH],
        fifo_ARBURST_o[ar_idx*TRANS_BURST_W +: TRANS_BURST_W],
        fifo_ARLEN_o[ar_idx*TRANS_DATA_LEN_W +: TRANS_DATA_LEN_W],
        fifo_ARSIZE_o[ar_idx*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W],
        fifo_ARQOS_o[ar_idx*TRANS_QOS_W +: TRANS_QOS_W]
        
    } = ar_fifo_data_o[ar_idx];
end
endgenerate

// AR channel mux

AR_dsp_slv_channel #(
    .MST_AMT            (MST_AMT),

    .ADDR_WIDTH         (ADDR_WIDTH),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_BURST_W      (TRANS_BURST_W),
    .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
    .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
    .TRANS_QOS_W        (TRANS_QOS_W)
)
u_AR_dsp_slv_channel (
    
    // Slave side
    .s_ARID_o       (s_ARID_o_mux),
    .s_ARADDR_o     (s_ARADDR_o),
    .s_ARBURST_o    (s_ARBURST_o),
    .s_ARLEN_o      (s_ARLEN_o),
    .s_ARSIZE_o     (s_ARSIZE_o),
    .s_ARQOS_o      (s_ARQOS_o),
    // .s_ARVALID_o    (s_ARVALID_o),
    // .s_ARREADY_i    (s_ARREADY_i),
    // Input từ FIFO
    .ma_ARID_i      (fifo_ARID_o),
    .ma_ARADDR_i    (fifo_ARADDR_o),
    .ma_ARBURST_i   (fifo_ARBURST_o),
    .ma_ARLEN_i     (fifo_ARLEN_o),
    .ma_ARSIZE_i    (fifo_ARSIZE_o),
    .ma_ARQOS_i    (fifo_ARQOS_o),
    // .ma_ARVALID_i   (fifo_ARVALID_o),
    // Read enable FIFO
    // .ma_ARREADY_o   (fifo_ARREADY_i),
    // Chọn master
    .ctl_MST_ID_i   (ctl_master_id_ar_i)
);
//append ARID
assign s_ARID_o = {ctl_master_id_ar_i, s_ARID_o_mux[TRANS_MST_ID_W - MST_ID_W -1:0]};

//AW channel

// FIFO internal signals
wire [AW_FIFO_WIDTH-1:0] aw_fifo_data_o [MST_AMT-1:0];
wire [MST_AMT-1:0] aw_fifo_empty;
wire [MST_AMT-1:0] aw_fifo_full;
wire [TRANS_MST_ID_W -1:0] s_AWID_o_mux;
// FIFO -> AW_dsp_slv_channel

wire [TRANS_MST_ID_W*MST_AMT-1:0]      fifo_AWID_o;
wire [ADDR_WIDTH*MST_AMT-1:0]          fifo_AWADDR_o;
wire [TRANS_BURST_W*MST_AMT-1:0]       fifo_AWBURST_o;
wire [TRANS_DATA_LEN_W*MST_AMT-1:0]    fifo_AWLEN_o;
wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]   fifo_AWSIZE_o;
wire [TRANS_QOS_W*MST_AMT-1:0]   fifo_AWQOS_o;

// FIFO control
wire [MST_AMT-1:0] aw_fifo_wr_en;
wire [MST_AMT-1:0] aw_fifo_rd_en;

genvar aw_idx;
// Generate one FIFO per master
generate
for(aw_idx = 0; aw_idx < MST_AMT; aw_idx = aw_idx + 1)
begin : AW_FIFO_GEN

    fifo #(
        .DATA_WIDTH(AW_FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_AW_fifo (

        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        // Push từ Master
        .data_i(
            {
                ma_AWID_i[aw_idx*TRANS_MST_ID_W +: TRANS_MST_ID_W],
                ma_AWADDR_i[aw_idx*ADDR_WIDTH +:ADDR_WIDTH],
                ma_AWBURST_i[aw_idx*TRANS_BURST_W +: TRANS_BURST_W],
                ma_AWLEN_i[aw_idx*TRANS_DATA_LEN_W +:TRANS_DATA_LEN_W],
                ma_AWSIZE_i[aw_idx*TRANS_DATA_SIZE_W +:TRANS_DATA_SIZE_W],
                ma_AWQOS_i[aw_idx*TRANS_QOS_W +:TRANS_QOS_W]
            }
        ),
        .wr_valid_i(aw_fifo_wr_en[aw_idx]),
        // Pop bởi AR_dsp_slv_channel
        .rd_valid_i(aw_fifo_rd_en[aw_idx]),
        .data_o(aw_fifo_data_o[aw_idx]),
        .empty_o          (aw_fifo_empty[aw_idx]),
        .full_o           (aw_fifo_full[aw_idx]),
        .almost_empty_o   (),
        .almost_full_o    (),
        .counter          ()
    );

end
endgenerate
// FIFO handshake
assign aw_fifo_wr_en = aw_fifo_wr_en_i;
assign aw_fifo_rd_en = aw_fifo_rd_en_i;
assign aw_fifo_full_o = aw_fifo_full;
assign aw_fifo_empty_o = aw_fifo_empty;

// FIFO unpack

generate
for(aw_idx = 0; aw_idx < MST_AMT; aw_idx = aw_idx + 1)
begin : AW_FIFO_UNPACK
    assign {
        fifo_AWID_o[aw_idx*TRANS_MST_ID_W +: TRANS_MST_ID_W],
        fifo_AWADDR_o[aw_idx*ADDR_WIDTH +: ADDR_WIDTH],
        fifo_AWBURST_o[aw_idx*TRANS_BURST_W +: TRANS_BURST_W],
        fifo_AWLEN_o[aw_idx*TRANS_DATA_LEN_W +: TRANS_DATA_LEN_W],
        fifo_AWSIZE_o[aw_idx*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W],
        fifo_AWQOS_o[aw_idx*TRANS_QOS_W +: TRANS_QOS_W]
    } = aw_fifo_data_o[aw_idx];

end
endgenerate
// AW channel mux
AW_dsp_slv_channel #(
    .MST_AMT            (MST_AMT),

    .ADDR_WIDTH         (ADDR_WIDTH),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_BURST_W      (TRANS_BURST_W),
    .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
    .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
    .TRANS_QOS_W        (TRANS_QOS_W)
)
u_AW_dsp_slv_channel (
    // Slave side
    .s_AWID_o       (s_AWID_o_mux),
    .s_AWADDR_o     (s_AWADDR_o),
    .s_AWBURST_o    (s_AWBURST_o),
    .s_AWLEN_o      (s_AWLEN_o),
    .s_AWSIZE_o     (s_AWSIZE_o),
    .s_AWQOS_o     (s_AWQOS_o),
    // .s_AWVALID_o    (s_AWVALID_o),
    // .s_AWREADY_i    (s_AWREADY_i),
    // Input từ FIFO
    .ma_AWID_i      (fifo_AWID_o),
    .ma_AWADDR_i    (fifo_AWADDR_o),
    .ma_AWBURST_i   (fifo_AWBURST_o),
    .ma_AWLEN_i     (fifo_AWLEN_o),
    .ma_AWSIZE_i    (fifo_AWSIZE_o),
    .ma_AWQOS_i    (fifo_AWQOS_o),
    // .ma_AWVALID_i   (fifo_AWVALID_o),
    // Read enable FIFO
    // .ma_AWREADY_o   (fifo_AWREADY_i),
    // Chọn master
    .ctl_MST_ID_i   (ctl_master_id_aw_i)
);
//append awid
assign s_AWID_o = {ctl_master_id_aw_i, s_AWID_o_mux[TRANS_MST_ID_W - MST_ID_W -1:0]};

//W channel
//==========================================================
// W CHANNEL
//==========================================================
// FIFO internal signals
wire [W_FIFO_WIDTH-1:0] w_fifo_data_o [MST_AMT-1:0];

wire [MST_AMT-1:0] w_fifo_empty;
wire [MST_AMT-1:0] w_fifo_full;
// FIFO -> W_dsp_slv_channel

wire [DATA_WIDTH*MST_AMT-1:0] fifo_WDATA_o;
wire [MST_AMT-1:0]            fifo_WLAST_o;

// FIFO control
wire [MST_AMT-1:0] w_fifo_wr_en;
wire [MST_AMT-1:0] w_fifo_rd_en;

genvar w_idx;
// Generate one FIFO per master
generate
for(w_idx = 0; w_idx < MST_AMT; w_idx = w_idx + 1)
begin : W_FIFO_GEN

    fifo #(
        .DATA_WIDTH(W_FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_W_fifo (

        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),

        // Push từ Master

        .data_i(
            {
                ma_WDATA_i[
                    w_idx*DATA_WIDTH +:
                    DATA_WIDTH
                ],

                ma_WLAST_i[w_idx]
            }
        ),
        .wr_valid_i(w_fifo_wr_en[w_idx]),
        // Pop bởi W_dsp_slv_channel
        .rd_valid_i(w_fifo_rd_en[w_idx]),

        .data_o(w_fifo_data_o[w_idx]),

        .empty_o          (w_fifo_empty[w_idx]),
        .full_o           (w_fifo_full[w_idx]),
        .almost_empty_o   (),
        .almost_full_o    (),
        .counter          ()
    );

end
endgenerate
// FIFO handshake
assign w_fifo_wr_en = w_fifo_wr_en_i;
assign w_fifo_rd_en = w_fifo_rd_en_i;
assign w_fifo_full_o = w_fifo_full;
assign w_fifo_empty_o = w_fifo_empty;

// FIFO unpack
generate
for(w_idx = 0; w_idx < MST_AMT; w_idx = w_idx + 1)
begin : W_FIFO_UNPACK

    assign {
        fifo_WDATA_o[
            w_idx*DATA_WIDTH +:
            DATA_WIDTH
        ],

        fifo_WLAST_o[w_idx]

    } = w_fifo_data_o[w_idx];

end
endgenerate
// W channel mux
W_dsp_slv_channel #(
    .MST_AMT            (MST_AMT),

    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_BURST_W      (TRANS_BURST_W),
    .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
    .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W)
)
u_W_dsp_slv_channel (
    // Slave side
    .s_WDATA_o      (s_WDATA_o),
    .s_WLAST_o      (s_WLAST_o),
    //.s_WVALID_o     (s_WVALID_o),
    //.s_WREADY_i     (s_WREADY_i),
    // Input từ FIFO
    .ma_WDATA_i     (fifo_WDATA_o),
    .ma_WLAST_i     (fifo_WLAST_o),
    //.ma_WVALID_i    (fifo_WVALID_o),
    // Read enable FIFO
    //.ma_WREADY_o    (fifo_WREADY_i),
    // Chọn master
    .ctl_MST_ID_i   (ctl_master_id_w_i)
);


//R channel
//----------------------------------------------------------
// R channel demux
//----------------------------------------------------------

R_dsp_slv_channel #(
    .MST_AMT            (MST_AMT),
    .MST_ID_W           (MST_ID_W),

    .DATA_WIDTH         (DATA_WIDTH),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_WR_RESP_W    (TRANS_WR_RESP_W)

)
u_R_dsp_slv_channel (

    //-------------------------------------
    // Slave interface
    //-------------------------------------

    .s_RID_i        (s_RID_i),
    .s_RDATA_i      (s_RDATA_i),
    .s_RRESP_i      (s_RRESP_i),
    .s_RLAST_i      (s_RLAST_i),
    // .s_RVALID_i     (s_RVALID_i),
    // .s_RREADY_o     (s_RREADY_o),

    //-------------------------------------
    // Master interface
    //-------------------------------------

    .ma_RID_o       (ma_RID_o),
    .ma_RDATA_o     (ma_RDATA_o),
    .ma_RRESP_o     (ma_RRESP_o),
    .ma_RLAST_o     (ma_RLAST_o),
    // .ma_RVALID_o    (ma_RVALID_o),
    // .ma_RREADY_i    (ma_RREADY_i),

    //-------------------------------------
    // Controller
    //-------------------------------------

    .ctl_MST_ID_i   (ctl_master_id_r_i)
);
//assign r_trans_mst_id = s_RID_i;
// B channel demux
//----------------------------------------------------------

B_dsp_slv_channel #(
    .MST_AMT            (MST_AMT),
    .MST_ID_W           (MST_ID_W),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_WR_RESP_W    (TRANS_WR_RESP_W)

)
u_B_dsp_slv_channel (

    //-------------------------------------
    // Slave interface
    //-------------------------------------

    .s_BID_i        (s_BID_i),
    .s_BRESP_i      (s_BRESP_i),
    // .s_BVALID_i     (s_BVALID_i),
    // .s_BREADY_o     (s_BREADY_o),

    //-------------------------------------
    // Master interface
    //-------------------------------------

    .ma_BID_o       (ma_BID_o),
    .ma_BRESP_o     (ma_BRESP_o),
    // .ma_BVALID_o    (ma_BVALID_o),
    // .ma_BREADY_i    (ma_BREADY_i),

    //-------------------------------------
    // Controller
    //-------------------------------------

    .ctl_MST_ID_i   (ctl_master_id_b_i)
);
//assign b_trans_mst_id = s_BID_i;
endmodule