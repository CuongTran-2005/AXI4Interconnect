module AW_dsp_mst_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,
    parameter                       OUTSTANDING_AMT     = 8,
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,                            // Bus width of master transaction ID 
    parameter                       TRANS_BURST_W       = 2,                            // Width of xBURST 
    parameter                       TRANS_DATA_LEN_W    = 3,                            // Bus width of xLEN
    parameter                       TRANS_DATA_SIZE_W   = 3,                            // Bus width of xSIZE
    parameter                       TRANS_WR_RESP_W     = 2,
    parameter TRANS_QOS_W = 16,
    // Slave info configuration (address mapping mechanism) (Default: The upper bits)
    parameter                       SLV_ID_MSB_IDX      = ADDR_WIDTH - 1,
    parameter                       SLV_ID_LSB_IDX      = ADDR_WIDTH - $clog2(SLV_AMT),
    // Dispatcher DATA depth configuration
    parameter                       DSP_RDATA_DEPTH     = 16
)
(	
	// Master interface
	 input   [TRANS_MST_ID_W-1:0]                        m_AWID_i,
    input   [ADDR_WIDTH-1:0]                            m_AWADDR_i,
    input   [TRANS_BURST_W-1:0]             	        m_AWBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          	        m_AWLEN_i,
    input   [TRANS_DATA_SIZE_W -1:0]                    m_AWSIZE_i,
    input   [TRANS_QOS_W-1:0]                           m_AWQOS_i,
    //input                                               m_AWVALID_i,
    //output                                              m_AWREADY_o,
    // Slave arbiter interface
    output  [TRANS_MST_ID_W * SLV_AMT-1:0]              sa_AWID_o,
    output  [ADDR_WIDTH * SLV_AMT-1:0]                  sa_AWADDR_o,
    output  [TRANS_BURST_W * SLV_AMT-1:0]               sa_AWBURST_o,
    output  [TRANS_DATA_LEN_W * SLV_AMT-1:0]            sa_AWLEN_o,
    output  [TRANS_DATA_SIZE_W * SLV_AMT-1:0]           sa_AWSIZE_o,
    output  [TRANS_QOS_W * SLV_AMT-1:0]                 sa_AWQOS_o,
    //output  [SLV_AMT -1:0]                              sa_AWVALID_o,
    //input   [SLV_AMT -1:0]                              sa_AWREADY_i,
    //control (decoder) interface
    //output  [ADDR_WIDTH-1:0]                            ctl_ADDR_o,
    input   [SLV_ID_W -1:0]                             ctl_SLV_ID_i
);
    //local parameter cho demux
    localparam DATA_IN_MUX_WIDTH = TRANS_MST_ID_W + ADDR_WIDTH + TRANS_BURST_W + TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W + TRANS_QOS_W;
    localparam DATA_OUT_MUX_WIDTH = DATA_IN_MUX_WIDTH * SLV_AMT;
    //wire demux
    wire [DATA_IN_MUX_WIDTH -1:0] demux_in;
    wire [DATA_OUT_MUX_WIDTH -1:0] demux_out;
    //wire out
    wire  [TRANS_MST_ID_W -1:0]                     sa_AWID_o_demux [SLV_AMT -1:0];
    wire  [ADDR_WIDTH -1:0]                         sa_AWADDR_o_demux [SLV_AMT -1:0];
    wire  [TRANS_BURST_W -1:0]                      sa_AWBURST_o_demux [SLV_AMT -1:0];
    wire  [TRANS_DATA_LEN_W -1:0]                   sa_AWLEN_o_demux [SLV_AMT -1:0];
    wire  [TRANS_DATA_SIZE_W -1:0]                  sa_AWSIZE_o_demux [SLV_AMT -1:0];
    wire  [TRANS_QOS_W -1:0]                        sa_AWQOS_o_demux [SLV_AMT -1:0];
    //wire                                            sa_AWVALID_o_demux [SLV_AMT -1:0];
    common_demux #(
        .DATA_WIDTH(DATA_IN_MUX_WIDTH),
        .OUT_AMT (SLV_AMT)
    ) AW_mst_demux(
        .data_i(demux_in),
        .sel_i(ctl_SLV_ID_i),
        .data_o(demux_out)
    );
    //in out demux
    assign demux_in = {m_AWID_i, m_AWADDR_i, m_AWBURST_i, m_AWLEN_i, m_AWSIZE_i, m_AWQOS_i}; //xoa m_ARVALID_i
    genvar idx;
    generate
        //tach out cua mux thanh cac phan cho tung slave
        for (idx = 0; idx < SLV_AMT;idx = idx +1) begin : AW_DEMUX_SEPARATION
            assign {
            sa_AWID_o_demux[idx],
            sa_AWADDR_o_demux[idx],
            sa_AWBURST_o_demux[idx],
            sa_AWLEN_o_demux[idx],
            sa_AWSIZE_o_demux[idx],
            sa_AWQOS_o_demux[idx],
            //sa_AWVALID_o_demux[idx]
            } = demux_out[DATA_IN_MUX_WIDTH*idx +: DATA_IN_MUX_WIDTH];
        end
        //gop cac loai data cho ra output
        for (idx = 0; idx < SLV_AMT;idx = idx +1) begin : AW_SLV_OUT
            assign sa_AWID_o    [TRANS_MST_ID_W * idx +: TRANS_MST_ID_W]        = sa_AWID_o_demux [idx];
            assign sa_AWADDR_o  [ADDR_WIDTH * idx +: ADDR_WIDTH]                = sa_AWADDR_o_demux [idx];
            assign sa_AWBURST_o [TRANS_BURST_W * idx +: TRANS_BURST_W]          = sa_AWBURST_o_demux [idx];
            assign sa_AWLEN_o   [TRANS_DATA_LEN_W * idx +: TRANS_DATA_LEN_W]    = sa_AWLEN_o_demux [idx];
            assign sa_AWSIZE_o  [TRANS_DATA_SIZE_W * idx +: TRANS_DATA_SIZE_W]  = sa_AWSIZE_o_demux [idx];
            assign sa_AWQOS_o   [TRANS_QOS_W * idx +: TRANS_QOS_W]               = sa_AWQOS_o_demux [idx];
            //assign sa_AWVALID_o [idx +: 1]                                      = sa_AWVALID_o_demux [idx];
        end
    endgenerate
    //assign ctl_ADDR_o = m_AWADDR_i;
    //assign m_AWREADY_o = sa_AWREADY_i [ctl_SLV_ID_i];
endmodule
