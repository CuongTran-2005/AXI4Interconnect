module R_dsp_slv_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       MST_ID_W            = $clog2(MST_AMT),

    parameter                       DATA_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_WR_RESP_W     = 2
)
(
    //--------------------------------------------------
    // Slave interface
    //--------------------------------------------------
    input   [TRANS_MST_ID_W-1:0]                    s_RID_i,
    input   [DATA_WIDTH-1:0]                        s_RDATA_i,
    input   [TRANS_WR_RESP_W-1:0]                   s_RRESP_i,
    input                                           s_RLAST_i,
    input                                           s_RVALID_i,
    output                                          s_RREADY_o,

    //--------------------------------------------------
    // Master arbiter interface
    //--------------------------------------------------
    output  [TRANS_MST_ID_W*MST_AMT-1:0]            ma_RID_o,
    output  [DATA_WIDTH*MST_AMT-1:0]                ma_RDATA_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]           ma_RRESP_o,
    output  [MST_AMT-1:0]                           ma_RLAST_o,
    output  [MST_AMT-1:0]                           ma_RVALID_o,
    input   [MST_AMT-1:0]                           ma_RREADY_i,

    //--------------------------------------------------
    // Controller
    //--------------------------------------------------
    input   [MST_ID_W-1:0]                          ctl_MST_ID_i
);

    //--------------------------------------------------
    // Localparam
    //--------------------------------------------------

    localparam DATA_IN_DEMUX_WIDTH =
            TRANS_MST_ID_W +
            DATA_WIDTH +
            TRANS_WR_RESP_W +
            1 +     // RLAST
            1;      // RVALID

    //--------------------------------------------------
    // DEMUX signals
    //--------------------------------------------------

    wire [DATA_IN_DEMUX_WIDTH-1:0]           demux_in;
    wire [DATA_IN_DEMUX_WIDTH*MST_AMT-1:0]   demux_out;

    //--------------------------------------------------
    // Pack slave signals
    //--------------------------------------------------

    assign demux_in =
    {
        s_RID_i,
        s_RDATA_i,
        s_RRESP_i,
        s_RLAST_i,
        s_RVALID_i
    };

    //--------------------------------------------------
    // DEMUX
    //--------------------------------------------------

    common_demux #(
        .DATA_WIDTH (DATA_IN_DEMUX_WIDTH),
        .OUT_AMT    (MST_AMT)
    ) R_slv_demux (
        .data_i (demux_in),
        .sel_i  (ctl_MST_ID_i),
        .data_o (demux_out)
    );

    //--------------------------------------------------
    // Unpack outputs
    //--------------------------------------------------

    genvar idx;

    generate

        for(idx=0; idx<MST_AMT; idx=idx+1)
        begin : R_DEMUX_OUTPUT

            assign {
                ma_RID_o[
                    TRANS_MST_ID_W*idx +:
                    TRANS_MST_ID_W
                ],

                ma_RDATA_o[
                    DATA_WIDTH*idx +:
                    DATA_WIDTH
                ],

                ma_RRESP_o[
                    TRANS_WR_RESP_W*idx +:
                    TRANS_WR_RESP_W
                ],

                ma_RLAST_o[idx],

                ma_RVALID_o[idx]

            } = demux_out[
                    DATA_IN_DEMUX_WIDTH*idx +:
                    DATA_IN_DEMUX_WIDTH
                ];

        end

    endgenerate

    //--------------------------------------------------
    // READY mux
    //--------------------------------------------------

    assign s_RREADY_o =
        ma_RREADY_i[ctl_MST_ID_i];

endmodule