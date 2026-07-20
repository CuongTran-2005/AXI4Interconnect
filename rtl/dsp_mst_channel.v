module dsp_mst_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),
	 
	parameter                        OUTSTANDING_AMT     = 8,
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_BURST_W       = 2,
    parameter                       TRANS_DATA_LEN_W    = 3,
    parameter                       TRANS_DATA_SIZE_W   = 3,
    parameter                       TRANS_WR_RESP_W     = 2,
    parameter                       TRANS_QOS_W         =16,
	parameter                        SLV_ID_MSB_IDX      = ADDR_WIDTH - 1,
    parameter                       SLV_ID_LSB_IDX      = ADDR_WIDTH - $clog2(SLV_AMT),
    parameter                       FIFO_DEPTH          = 16
)(
	//global signal
	input                                   ACLK_i,
    input                                   ARESETn_i,
	//------------control signal-------------------
	input [SLV_ID_W-1:0] 				  	ctl_slave_id_aw_i,
    input [SLV_ID_W-1:0] 				  	ctl_slave_id_w_i,
    input [SLV_ID_W-1:0] 				  	ctl_slave_id_b_i,
	//output [ADDR_WIDTH-1:0]           	    ctl_AWINFO_o,
	 
    input [SLV_ID_W-1:0] 					ctl_slave_id_ar_i,
    input [SLV_ID_W-1:0] 					ctl_slave_id_r_i,
	//output [ADDR_WIDTH-1:0]                 ctl_ARINFO_o,
    //r, b last
    // output                                  r_last_o;
    // output                                  b_last_o;

    //fifo signal 
    output [SLV_AMT -1 : 0]                 r_fifo_full_o,
    output [SLV_AMT -1 : 0]                 r_fifo_empty_o,
    input  [SLV_AMT -1 : 0]                 r_fifo_wr_en_i,
    input  [SLV_AMT -1 : 0]                 r_fifo_rd_en_i,

    output [SLV_AMT -1 : 0]                 b_fifo_full_o,
    output [SLV_AMT -1 : 0]                 b_fifo_empty_o,
    input  [SLV_AMT -1 : 0]                 b_fifo_wr_en_i,
    input  [SLV_AMT -1 : 0]                 b_fifo_rd_en_i,

     
    //-----AR dsp_mst channel------
	 //master side
	input   [TRANS_MST_ID_W-1:0]                        m_ARID_i,
    input   [ADDR_WIDTH-1:0]                            m_ARADDR_i,
    input   [TRANS_BURST_W-1:0]             	        m_ARBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          	        m_ARLEN_i,
    input   [TRANS_DATA_SIZE_W -1:0]                    m_ARSIZE_i,
    input   [TRANS_QOS_W-1:0]                           m_ARQOS_i,
    // input                                               m_ARVALID_i,
    // output                                              m_ARREADY_o,
    // slave side
    output  [TRANS_MST_ID_W * SLV_AMT-1:0]              sa_ARID_o,
    output  [ADDR_WIDTH * SLV_AMT-1:0]                  sa_ARADDR_o,
    output  [TRANS_BURST_W * SLV_AMT-1:0]               sa_ARBURST_o,
    output  [TRANS_DATA_LEN_W * SLV_AMT-1:0]            sa_ARLEN_o,
    output  [TRANS_DATA_SIZE_W * SLV_AMT-1:0]           sa_ARSIZE_o,
    output  [TRANS_QOS_W*SLV_AMT -1:0]                  sa_ARQOS_o,
    // output  [SLV_AMT -1:0]                              sa_ARVALID_o,
    // input   [SLV_AMT -1:0]                              sa_ARREADY_i,
	 //-----R dsp_mst channel------
	 //master side
	output  [TRANS_MST_ID_W-1:0]                        m_RID_o,
    output  [DATA_WIDTH-1:0]                            m_RDATA_o,
    output  [TRANS_WR_RESP_W-1:0]                       m_RRESP_o,
    output                                              m_RLAST_o,
    // output                          m_RVALID_o,
    // input                           m_RREADY_i,
	 //slave side
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]                sa_RID_i,
    input   [DATA_WIDTH*SLV_AMT-1:0]                    sa_RDATA_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]               sa_RRESP_i,
    input   [SLV_AMT-1:0]                               sa_RLAST_i,
    // input   [SLV_AMT-1:0]                 sa_RVALID_i,
    // output  [SLV_AMT-1:0]                 sa_RREADY_o,
	 //-----AW dsp_mst channel -------
	 // Master side
	 input   [TRANS_MST_ID_W-1:0]                       m_AWID_i,
    input   [ADDR_WIDTH-1:0]                            m_AWADDR_i,
    input   [TRANS_BURST_W-1:0]             	        m_AWBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          	        m_AWLEN_i,
    input   [TRANS_DATA_SIZE_W -1:0]                    m_AWSIZE_i,
    input   [TRANS_QOS_W-1:0]                           m_AWQOS_i,
    // input                                               m_AWVALID_i,
    // output                                              m_AWREADY_o,
    // Slave side
    output  [TRANS_MST_ID_W * SLV_AMT-1:0]              sa_AWID_o,
    output  [ADDR_WIDTH * SLV_AMT-1:0]                  sa_AWADDR_o,
    output  [TRANS_BURST_W * SLV_AMT-1:0]               sa_AWBURST_o,
    output  [TRANS_DATA_LEN_W * SLV_AMT-1:0]            sa_AWLEN_o,
    output  [TRANS_DATA_SIZE_W * SLV_AMT-1:0]           sa_AWSIZE_o,
    output  [TRANS_QOS_W*SLV_AMT -1:0]                  sa_AWQOS_o,
    // output  [SLV_AMT -1:0]                              sa_AWVALID_o,
    // input   [SLV_AMT -1:0]                              sa_AWREADY_i,
	 //-----W dsp_mst channel -------
	 // Master interface
	input   [DATA_WIDTH-1:0]                            m_WDATA_i,
    input                                               m_WLAST_i,
    // input                                               m_WVALID_i,
    // output                                              m_WREADY_o,
    // Slave arbiter interface
	output   [DATA_WIDTH * SLV_AMT-1:0]                 sa_WDATA_o,
    output   [SLV_AMT -1:0]                             sa_WLAST_o,
    // output   [SLV_AMT-1:0]                              sa_WVALID_o,
    // input    [SLV_AMT -1:0]                             sa_WREADY_i,
	 //----B dsp_mst channel --------
	  // Master interface
    output  [TRANS_MST_ID_W-1:0]                        m_BID_o,
    output  [TRANS_WR_RESP_W-1:0]                       m_BRESP_o,
    // output                          m_BVALID_o,
    // input                           m_BREADY_i,
    // Slave arbiter interface
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]                sa_BID_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]               sa_BRESP_i
    // input   [SLV_AMT-1:0]                 sa_BVALID_i,
    // output  [SLV_AMT-1:0]                 sa_BREADY_o
);

//localparam
localparam R_FIFO_WIDTH =
            TRANS_MST_ID_W +
            DATA_WIDTH +
            TRANS_WR_RESP_W +
            1;
				
localparam B_FIFO_WIDTH =
            TRANS_MST_ID_W +
            TRANS_WR_RESP_W;

//rlast, blast to controler
// assign r_last_o = m_RLAST_o;
// assign b_last_o = m_BLAST_o;
//AR channel
AR_dsp_mst_channel #(
    .MST_AMT            (MST_AMT),
    .SLV_AMT            (SLV_AMT),
    .OUTSTANDING_AMT    (OUTSTANDING_AMT),
    .MST_ID_W           (MST_ID_W),
    .SLV_ID_W           (SLV_ID_W),

    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_BURST_W      (TRANS_BURST_W),
    .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
    .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
    .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
    .TRANS_QOS_W        (TRANS_QOS_W),

    .SLV_ID_MSB_IDX     (SLV_ID_MSB_IDX),
    .SLV_ID_LSB_IDX     (SLV_ID_LSB_IDX)

)
u_AR_dsp_mst_channel (
    // Master interface
    .m_ARID_i       (m_ARID_i),
    .m_ARADDR_i     (m_ARADDR_i),
    .m_ARBURST_i    (m_ARBURST_i),
    .m_ARLEN_i      (m_ARLEN_i),
    .m_ARSIZE_i     (m_ARSIZE_i),
    .m_ARQOS_i      (m_ARQOS_i),
    //.m_ARVALID_i    (m_ARVALID_i),
    //.m_ARREADY_o    (m_ARREADY_o),

    // Slave interface
    .sa_ARID_o      (sa_ARID_o),
    .sa_ARADDR_o    (sa_ARADDR_o),
    .sa_ARBURST_o   (sa_ARBURST_o),
    .sa_ARLEN_o     (sa_ARLEN_o),
    .sa_ARSIZE_o    (sa_ARSIZE_o),
    .sa_ARQOS_o     (sa_ARQOS_o),
    //.sa_ARVALID_o   (sa_ARVALID_o),
    //.sa_ARREADY_i   (sa_ARREADY_i),

    // Decoder interface
    //.ctl_ADDR_o     (ctl_ARINFO_o),
    .ctl_SLV_ID_i   (ctl_slave_id_ar_i)
);

//AW channel
AW_dsp_mst_channel #(
    .MST_AMT            (MST_AMT),
    .SLV_AMT            (SLV_AMT),
    .OUTSTANDING_AMT    (OUTSTANDING_AMT),
    .MST_ID_W           (MST_ID_W),
    .SLV_ID_W           (SLV_ID_W),

    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_BURST_W      (TRANS_BURST_W),
    .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
    .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
    .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
    .TRANS_QOS_W        (TRANS_QOS_W),

    .SLV_ID_MSB_IDX     (SLV_ID_MSB_IDX),
    .SLV_ID_LSB_IDX     (SLV_ID_LSB_IDX)

)
u_AW_dsp_mst_channel (
    // Master interface
    .m_AWID_i       (m_AWID_i),
    .m_AWADDR_i     (m_AWADDR_i),
    .m_AWBURST_i    (m_AWBURST_i),
    .m_AWLEN_i      (m_AWLEN_i),
    .m_AWSIZE_i     (m_AWSIZE_i),
    .m_AWQOS_i      (m_AWQOS_i),
    // .m_AWVALID_i    (m_AWVALID_i),
    // .m_AWREADY_o    (m_AWREADY_o),
    // Slave interface
    .sa_AWID_o      (sa_AWID_o),
    .sa_AWADDR_o    (sa_AWADDR_o),
    .sa_AWBURST_o   (sa_AWBURST_o),
    .sa_AWLEN_o     (sa_AWLEN_o),
    .sa_AWSIZE_o    (sa_AWSIZE_o),
    .sa_AWQOS_o     (sa_AWQOS_o),
    // .sa_AWVALID_o   (sa_AWVALID_o),
    // .sa_AWREADY_i   (sa_AWREADY_i),

    // Decoder interface
    //.ctl_ADDR_o     (ctl_AWINFO_o),
    .ctl_SLV_ID_i   (ctl_slave_id_aw_i)
);

//W channel

W_dsp_mst_channel #(
    .MST_AMT            (MST_AMT),
    .SLV_AMT            (SLV_AMT),
    .OUTSTANDING_AMT    (OUTSTANDING_AMT),
    .MST_ID_W           (MST_ID_W),
    .SLV_ID_W           (SLV_ID_W),

    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_BURST_W      (TRANS_BURST_W),
    .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
    .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
    .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),

    .SLV_ID_MSB_IDX     (SLV_ID_MSB_IDX),
    .SLV_ID_LSB_IDX     (SLV_ID_LSB_IDX)

)
u_W_dsp_mst_channel (
    // Master interface
    .m_WDATA_i      (m_WDATA_i),
    .m_WLAST_i      (m_WLAST_i),
    // .m_WVALID_i     (m_WVALID_i),
    // .m_WREADY_o     (m_WREADY_o),

    // Slave interface
    .sa_WDATA_o     (sa_WDATA_o),
    .sa_WLAST_o     (sa_WLAST_o),
    // .sa_WVALID_o    (sa_WVALID_o),
    // .sa_WREADY_i    (sa_WREADY_i),

    // Control interface
    .ctl_SLV_ID_i   (ctl_slave_id_w_i)
);




//R channel
//wire fifo R channel
wire [R_FIFO_WIDTH-1:0] r_fifo_data_o [SLV_AMT-1:0];
//wire [R_FIFO_WIDTH-1:0] r_fifo_data_i [SLV_AMT-1:0];
wire [SLV_AMT-1:0] r_fifo_empty;
wire [SLV_AMT-1:0] r_fifo_full;
//wire R
wire [TRANS_MST_ID_W*SLV_AMT-1:0]  fifo_RID_o;
wire [DATA_WIDTH*SLV_AMT-1:0]      fifo_RDATA_o;
wire [TRANS_WR_RESP_W*SLV_AMT-1:0] fifo_RRESP_o;
wire [SLV_AMT-1:0] fifo_RLAST_o;

// wire [SLV_AMT-1:0] fifo_RVALID_o;
// wire [SLV_AMT-1:0] fifo_RREADY_i;
//generate slave -> fifo
genvar r_idx;
//wire fifo
wire [SLV_AMT -1:0] r_fifo_rd_en;
wire [SLV_AMT -1:0] r_fifo_wr_en;

generate
for(r_idx = 0; r_idx < SLV_AMT; r_idx = r_idx + 1)
begin : R_FIFO_GEN
    fifo #(
        .DATA_WIDTH(R_FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_R_fifo (
        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        //---------------------------------
        // Push từ Slave
        //---------------------------------
        .data_i(
            {
				sa_RID_i  [r_idx * TRANS_MST_ID_W +: TRANS_MST_ID_W],
                sa_RDATA_i[r_idx * DATA_WIDTH +:DATA_WIDTH],
                sa_RRESP_i[r_idx * TRANS_WR_RESP_W +: TRANS_WR_RESP_W],
                sa_RLAST_i[r_idx]
            }
        ),
        .wr_valid_i(
				//sa_RVALID_i[r_idx] & sa_RREADY_o [r_idx] //~r_fifo_full[r_idx] //check lai wr va rd
				r_fifo_wr_en[r_idx]
        ),

        //---------------------------------
        // Pop bởi R_dsp_mst_channel
        //---------------------------------
        .rd_valid_i(
            //fifo_RVALID_o [r_idx] & fifo_RREADY_i [r_idx]
				r_fifo_rd_en[r_idx] 
        ),
        .data_o(
            r_fifo_data_o[r_idx]
        ),
        .empty_o          (r_fifo_empty[r_idx]),
        .full_o           (r_fifo_full[r_idx]),
        .almost_empty_o   (),
        .almost_full_o    (),
        .counter          ()
    );

end
endgenerate
// signal fifo
assign r_fifo_wr_en = r_fifo_wr_en_i;
assign r_fifo_rd_en = r_fifo_rd_en_i;
assign r_fifo_full_o = r_fifo_full;
assign r_fifo_empty_o = r_fifo_empty;

// tach fifo ra bus cho R_dsp_mst_channel
generate
for(r_idx = 0; r_idx < SLV_AMT; r_idx = r_idx + 1)
begin : R_FIFO_UNPACK
    assign {
        fifo_RID_o[r_idx*TRANS_MST_ID_W +: TRANS_MST_ID_W],
        fifo_RDATA_o[r_idx*DATA_WIDTH +: DATA_WIDTH],
        fifo_RRESP_o[r_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W],
        fifo_RLAST_o[r_idx]
    }
    = r_fifo_data_o[r_idx];

    //assign fifo_RVALID_o[r_idx] = ~r_fifo_empty[r_idx];

end
endgenerate
//instance
R_dsp_mst_channel #(
    .SLV_AMT            (SLV_AMT),
	 
    .DATA_WIDTH         (DATA_WIDTH),
   
    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_WR_RESP_W    (TRANS_WR_RESP_W)
)
u_R_dsp_mst_channel (

    // Master interface
    .m_RID_o       (m_RID_o),
    .m_RDATA_o     (m_RDATA_o),
    .m_RRESP_o     (m_RRESP_o),
    .m_RLAST_o     (m_RLAST_o),
    //.m_RVALID_o    (m_RVALID_o),
    //.m_RREADY_i    (m_RREADY_i),

    // Input từ FIFO
    .sa_RID_i      (fifo_RID_o),
    .sa_RDATA_i    (fifo_RDATA_o),
    .sa_RRESP_i    (fifo_RRESP_o),
    .sa_RLAST_i    (fifo_RLAST_o),

    //.sa_RVALID_i   (fifo_RVALID_o),
    // Read enable FIFO
    //.sa_RREADY_o   (fifo_RREADY_i),

    // Chọn slave
    .ctl_SLV_ID_i  (ctl_slave_id_r_i)
);



//==========================================================
// B CHANNEL FIFO
//==========================================================
// FIFO internal signals
wire [B_FIFO_WIDTH-1:0] b_fifo_data_o [SLV_AMT-1:0];

wire [SLV_AMT-1:0] b_fifo_empty;
wire [SLV_AMT-1:0] b_fifo_full;

wire [SLV_AMT-1:0] b_fifo_wr_en;
wire [SLV_AMT-1:0] b_fifo_rd_en;
// FIFO -> B_dsp_mst_channel
wire [TRANS_MST_ID_W*SLV_AMT-1:0]  fifo_BID_o;
wire [TRANS_WR_RESP_W*SLV_AMT-1:0] fifo_BRESP_o;

// wire [SLV_AMT-1:0] fifo_BVALID_o;
// // B_dsp_mst_channel -> FIFO
// wire [SLV_AMT-1:0] fifo_BREADY_i;
// Generate FIFO
genvar b_idx;

generate
for(b_idx = 0; b_idx < SLV_AMT; b_idx = b_idx + 1)
begin : B_FIFO_GEN

    fifo #(
        .DATA_WIDTH(B_FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_B_fifo (

        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),

        //--------------------------------------------------
        // Push from Slave
        //--------------------------------------------------

        .data_i(
            {
                sa_BID_i[
                    b_idx*TRANS_MST_ID_W +:
                    TRANS_MST_ID_W
                ],

                sa_BRESP_i[
                    b_idx*TRANS_WR_RESP_W +:
                    TRANS_WR_RESP_W
                ]
            }
        ),

        .wr_valid_i(
            b_fifo_wr_en[b_idx]
        ),

        //--------------------------------------------------
        // Pop by B_dsp_mst_channel
        //--------------------------------------------------

        .rd_valid_i(
            b_fifo_rd_en[b_idx]
        ),

        .data_o(
            b_fifo_data_o[b_idx]
        ),

        .empty_o          (b_fifo_empty[b_idx]),
        .full_o           (b_fifo_full[b_idx]),
        .almost_empty_o   (),
        .almost_full_o    (),
        .counter          ()
    );

end
endgenerate


//----------------------------------------------------------
// FIFO handshake
//----------------------------------------------------------
assign b_fifo_wr_en = b_fifo_wr_en_i;
assign b_fifo_rd_en = b_fifo_rd_en_i;
assign b_fifo_full_o = b_fifo_full;
assign b_fifo_empty_o = b_fifo_empty;

// Unpack FIFO output
generate
for(b_idx = 0; b_idx < SLV_AMT; b_idx = b_idx + 1)
begin : B_FIFO_UNPACK

    assign {
        fifo_BID_o[
            b_idx*TRANS_MST_ID_W +:
            TRANS_MST_ID_W
        ],

        fifo_BRESP_o[
            b_idx*TRANS_WR_RESP_W +:
            TRANS_WR_RESP_W
        ]

    } = b_fifo_data_o[b_idx];

end
endgenerate

//----------------------------------------------------------
// B Channel MUX
//
// Select one slave response and return to master
//
// sa_BREADY_o -> FIFO read enable
//----------------------------------------------------------

B_dsp_mst_channel #(

    .SLV_AMT            (SLV_AMT),    

    .TRANS_MST_ID_W     (TRANS_MST_ID_W),
    .TRANS_WR_RESP_W    (TRANS_WR_RESP_W)
)
u_B_dsp_mst_channel (
    // Master Interface
    .m_BID_o        (m_BID_o),
    .m_BRESP_o      (m_BRESP_o),
    //.m_BVALID_o     (m_BVALID_o),
    //.m_BREADY_i     (m_BREADY_i),
    // FIFO Outputs
    .sa_BID_i       (fifo_BID_o),
    .sa_BRESP_i     (fifo_BRESP_o),
    //.sa_BVALID_i    (fifo_BVALID_o),
    // FIFO Read Request
    //.sa_BREADY_o    (fifo_BREADY_i),
    // Slave Select
    .ctl_SLV_ID_i   (ctl_slave_id_b_i)
);

endmodule