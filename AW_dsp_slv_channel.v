module AW_dsp_slv_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,

    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),

    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_BURST_W       = 2,
    parameter                       TRANS_DATA_LEN_W    = 3,
    parameter                       TRANS_DATA_SIZE_W   = 3,
    parameter TRANS_QOS_W = 16
)
(
    //--------------------------------------------------
    // Master arbiter interface
    //--------------------------------------------------
    input   [TRANS_MST_ID_W*MST_AMT-1:0]      ma_AWID_i,
    input   [ADDR_WIDTH*MST_AMT-1:0]          ma_AWADDR_i,
    input   [TRANS_BURST_W*MST_AMT-1:0]       ma_AWBURST_i,
    input   [TRANS_DATA_LEN_W*MST_AMT-1:0]    ma_AWLEN_i,
    input   [TRANS_DATA_SIZE_W*MST_AMT-1:0]   ma_AWSIZE_i,
    input   [TRANS_QOS_W*MST_AMT-1:0]         ma_AWQOS_i,
    input   [MST_AMT-1:0]                     ma_AWVALID_i,
    output  [MST_AMT-1:0]                     ma_AWREADY_o,

    //--------------------------------------------------
    // Slave interface
    //--------------------------------------------------
    output  [TRANS_MST_ID_W-1:0]              s_AWID_o,
    output  [ADDR_WIDTH-1:0]                  s_AWADDR_o,
    output  [TRANS_BURST_W-1:0]               s_AWBURST_o,
    output  [TRANS_DATA_LEN_W-1:0]            s_AWLEN_o,
    output  [TRANS_DATA_SIZE_W-1:0]           s_AWSIZE_o,
    output  [TRANS_QOS_W-1:0]                 s_AWQOS_o,
    output                                    s_AWVALID_o,
    input                                     s_AWREADY_i,

    //--------------------------------------------------
    // Controller
    //--------------------------------------------------
    input   [MST_ID_W-1:0]                    ctl_MST_ID_i
);

    //--------------------------------------------------
    // Localparam
    //--------------------------------------------------

    localparam DATA_IN_MUX_WIDTH =
        TRANS_MST_ID_W +
        ADDR_WIDTH +
        TRANS_BURST_W +
        TRANS_DATA_LEN_W +
        TRANS_DATA_SIZE_W +
        TRANS_QOS_W+
        1;

    //--------------------------------------------------
    // MUX
    //--------------------------------------------------

    wire [DATA_IN_MUX_WIDTH*MST_AMT-1:0] mux_in;
    wire [DATA_IN_MUX_WIDTH-1:0]         mux_out;

    //--------------------------------------------------
    // Pack master inputs
    //--------------------------------------------------

    genvar idx;

    generate

        for(idx=0; idx<MST_AMT; idx=idx+1)
        begin : AW_MUX_INPUT

            assign mux_in[
                DATA_IN_MUX_WIDTH*idx +:
                DATA_IN_MUX_WIDTH
            ]
            =
            {
                ma_AWID_i[
                    TRANS_MST_ID_W*idx +:
                    TRANS_MST_ID_W
                ],

                ma_AWADDR_i[
                    ADDR_WIDTH*idx +:
                    ADDR_WIDTH
                ],

                ma_AWBURST_i[
                    TRANS_BURST_W*idx +:
                    TRANS_BURST_W
                ],

                ma_AWLEN_i[
                    TRANS_DATA_LEN_W*idx +:
                    TRANS_DATA_LEN_W
                ],

                ma_AWSIZE_i[
                    TRANS_DATA_SIZE_W*idx +:
                    TRANS_DATA_SIZE_W
                ],

                ma_AWQOS_i[
                    TRANS_QOS_W*idx +:
                    TRANS_QOS_W
                ],

                ma_AWVALID_i[idx]
            };

        end

    endgenerate

    //--------------------------------------------------
    // MUX
    //--------------------------------------------------

    common_mux #(
        .DATA_WIDTH (DATA_IN_MUX_WIDTH),
        .OUT_AMT    (MST_AMT)
    ) AW_slv_mux (
        .data_i (mux_in),
        .sel_i  (ctl_MST_ID_i),
        .data_o (mux_out)
    );

    //--------------------------------------------------
    // Unpack
    //--------------------------------------------------

    assign {
        s_AWID_o,
        s_AWADDR_o,
        s_AWBURST_o,
        s_AWLEN_o,
        s_AWSIZE_o,
        s_AWQOS_o,
        s_AWVALID_o
    } = mux_out;

    //--------------------------------------------------
    // READY DEMUX
    //--------------------------------------------------

    generate

        for(idx=0; idx<MST_AMT; idx=idx+1)
        begin : AW_READY_DEMUX

            assign ma_AWREADY_o[idx] =
                (ctl_MST_ID_i == idx)
                ? s_AWREADY_i
                : 1'b0;

        end

    endgenerate

endmodule