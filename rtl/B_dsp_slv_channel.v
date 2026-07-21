module B_dsp_slv_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       MST_ID_W            = $clog2(MST_AMT),

    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_WR_RESP_W     = 2
)
(
    //--------------------------------------------------
    // Slave interface
    //--------------------------------------------------
    input   [TRANS_MST_ID_W-1:0]                    s_BID_i,
    input   [TRANS_WR_RESP_W-1:0]                   s_BRESP_i,
    // input                                           s_BVALID_i,
    // output                                          s_BREADY_o,

    //--------------------------------------------------
    // Master arbiter interface
    //--------------------------------------------------
    output  [TRANS_MST_ID_W*MST_AMT-1:0]            ma_BID_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]           ma_BRESP_o,
    // output  [MST_AMT-1:0]                           ma_BVALID_o,
    // input   [MST_AMT-1:0]                           ma_BREADY_i,

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
            TRANS_WR_RESP_W ;      // BVALID

    //--------------------------------------------------
    // DEMUX signals
    //--------------------------------------------------

    wire [DATA_IN_DEMUX_WIDTH-1:0]          demux_in;
    wire [DATA_IN_DEMUX_WIDTH*MST_AMT-1:0]  demux_out;

    //--------------------------------------------------
    // Pack slave signals
    //--------------------------------------------------

    assign demux_in =
    {
        s_BID_i,
        s_BRESP_i
        //s_BVALID_i
    };

    //--------------------------------------------------
    // DEMUX
    //--------------------------------------------------

    common_demux #(
        .DATA_WIDTH (DATA_IN_DEMUX_WIDTH),
        .OUT_AMT    (MST_AMT)
    ) B_slv_demux (
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
        begin : B_DEMUX_OUTPUT

            assign {
                ma_BID_o[
                    TRANS_MST_ID_W*idx +:
                    TRANS_MST_ID_W
                ],

                ma_BRESP_o[
                    TRANS_WR_RESP_W*idx +:
                    TRANS_WR_RESP_W
                ]

                //ma_BVALID_o[idx]

            } = demux_out[
                    DATA_IN_DEMUX_WIDTH*idx +:
                    DATA_IN_DEMUX_WIDTH
                ];

        end

    endgenerate

    //--------------------------------------------------
    // READY mux
    //--------------------------------------------------

    // assign s_BREADY_o =
    //     ma_BREADY_i[ctl_MST_ID_i];

endmodule