module W_dsp_mst_channel #(
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
    // Slave info configuration (address mapping mechanism) (Default: The upper bits)
    parameter                       SLV_ID_MSB_IDX      = ADDR_WIDTH - 1,
    parameter                       SLV_ID_LSB_IDX      = ADDR_WIDTH - $clog2(SLV_AMT),
    // Dispatcher DATA depth configuration
    parameter                       DSP_RDATA_DEPTH     = 16
)
(	
	// Master interface
	 input   [DATA_WIDTH-1:0]                            m_WDATA_i,
    input                                               m_WLAST_i,
    input                                               m_WVALID_i,
    output                                              m_WREADY_o,
    // Slave arbiter interface
	 output   [DATA_WIDTH * SLV_AMT-1:0]                 sa_WDATA_o,
    output   [SLV_AMT -1:0]                             sa_WLAST_o,
    output   [SLV_AMT-1:0]                              sa_WVALID_o,
    input    [SLV_AMT -1:0]                             sa_WREADY_i,
    //control (decoder) interface
    input   [SLV_ID_W -1:0]                             ctl_SLV_ID_i
);
    //local parameter cho demux
    localparam DATA_IN_MUX_WIDTH = DATA_WIDTH + 2;
    localparam DATA_OUT_MUX_WIDTH = DATA_IN_MUX_WIDTH * SLV_AMT;
    //wire demux
    wire [DATA_IN_MUX_WIDTH -1:0] demux_in;
    wire [DATA_OUT_MUX_WIDTH -1:0] demux_out;
    //wire out
    wire   [DATA_WIDTH -1:0]                 sa_WDATA_o_demux [SLV_AMT -1 : 0];
    wire                                     sa_WLAST_o_demux [SLV_AMT -1: 0];
    wire                                     sa_WVALID_o_demux [SLV_AMT -1: 0];
    common_demux #(
        .DATA_WIDTH(DATA_IN_MUX_WIDTH),
        .OUT_AMT (SLV_AMT)
    ) W_mst_demux(
        .data_i(demux_in),
        .sel_i(ctl_SLV_ID_i),
        .data_o(demux_out)
    );
    //in out demux
    assign demux_in = {m_WDATA_i, m_WLAST_i, m_WVALID_i};
    genvar idx;
    generate
        //tach out cua mux thanh cac phan cho tung slave
        for (idx = 0; idx < SLV_AMT;idx = idx +1) begin : W_DEMUX_SEPARATION
            assign {
            sa_WDATA_o_demux[idx],
            sa_WLAST_o_demux[idx],
            sa_WVALID_o_demux[idx]
            } = demux_out[DATA_IN_MUX_WIDTH*idx +: DATA_IN_MUX_WIDTH];
        end
        //gop cac loai data cho ra output
        for (idx = 0; idx < SLV_AMT;idx = idx +1) begin : W_SLV_OUT
            assign sa_WDATA_o   [DATA_WIDTH * idx +: DATA_WIDTH]        = sa_WDATA_o_demux [idx];
            assign sa_WLAST_o   [idx]                                   = sa_WLAST_o_demux [idx];
            assign sa_WVALID_o  [idx]                                   = sa_WVALID_o_demux [idx];
        end
    endgenerate
    assign m_WREADY_o = sa_WREADY_i [ctl_SLV_ID_i];
endmodule
