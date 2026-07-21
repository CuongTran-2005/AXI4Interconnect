module AR_dsp_slv_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,

    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),

    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_BURST_W       = 2,
    parameter                       TRANS_DATA_LEN_W    = 3,
    parameter                       TRANS_DATA_SIZE_W   = 3,
    parameter                       TRANS_QOS_W = 16
)
(
    //--------------------------------------------------
    // Master arbiter interface
    //--------------------------------------------------
    input   [TRANS_MST_ID_W*MST_AMT-1:0]      ma_ARID_i,
    input   [ADDR_WIDTH*MST_AMT-1:0]          ma_ARADDR_i,
    input   [TRANS_BURST_W*MST_AMT-1:0]       ma_ARBURST_i,
    input   [TRANS_DATA_LEN_W*MST_AMT-1:0]    ma_ARLEN_i,
    input   [TRANS_DATA_SIZE_W*MST_AMT-1:0]   ma_ARSIZE_i,
    input   [TRANS_QOS_W*MST_AMT-1:0]         ma_ARQOS_i,
    //input   [MST_AMT-1:0]                     ma_ARVALID_i,
    //output  [MST_AMT-1:0]                     ma_ARREADY_o,

    //--------------------------------------------------
    // Slave interface
    //--------------------------------------------------
    output  [TRANS_MST_ID_W-1:0]              s_ARID_o,
    output  [ADDR_WIDTH-1:0]                  s_ARADDR_o,
    output  [TRANS_BURST_W-1:0]               s_ARBURST_o,
    output  [TRANS_DATA_LEN_W-1:0]            s_ARLEN_o,
    output  [TRANS_DATA_SIZE_W-1:0]           s_ARSIZE_o,
    output  [TRANS_QOS_W-1:0]                 s_ARQOS_o,
    //output                                    s_ARVALID_o,
    //input                                     s_ARREADY_i,

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
        TRANS_QOS_W
        ;

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
        begin : AR_MUX_INPUT

            assign mux_in[
                DATA_IN_MUX_WIDTH*idx +:
                DATA_IN_MUX_WIDTH
            ]
            =
            {
                ma_ARID_i[
                    TRANS_MST_ID_W*idx +:
                    TRANS_MST_ID_W
                ],

                ma_ARADDR_i[
                    ADDR_WIDTH*idx +:
                    ADDR_WIDTH
                ],

                ma_ARBURST_i[
                    TRANS_BURST_W*idx +:
                    TRANS_BURST_W
                ],

                ma_ARLEN_i[
                    TRANS_DATA_LEN_W*idx +:
                    TRANS_DATA_LEN_W
                ],

                ma_ARSIZE_i[
                    TRANS_DATA_SIZE_W*idx +:
                    TRANS_DATA_SIZE_W
                ],

                ma_ARQOS_i[
                    TRANS_QOS_W*idx +:
                    TRANS_QOS_W
                ]

                //ma_ARVALID_i[idx]
            };

        end

    endgenerate

    //--------------------------------------------------
    // MUX
    //--------------------------------------------------

    common_mux #(
        .DATA_WIDTH (DATA_IN_MUX_WIDTH),
        .OUT_AMT    (MST_AMT)
    ) AR_slv_mux (
        .data_i (mux_in),
        .sel_i  (ctl_MST_ID_i),
        .data_o (mux_out)
    );

    //--------------------------------------------------
    // Unpack
    //--------------------------------------------------

    assign {
        s_ARID_o,
        s_ARADDR_o,
        s_ARBURST_o,
        s_ARLEN_o,
        s_ARSIZE_o,
        s_ARQOS_o
        //s_ARVALID_o
    } = mux_out;

    //--------------------------------------------------
    // READY DEMUX
    //--------------------------------------------------

    // generate

    //     for(idx=0; idx<MST_AMT; idx=idx+1)
    //     begin : AR_READY_DEMUX

    //         assign ma_ARREADY_o[idx] =
    //             (ctl_MST_ID_i == idx)
    //             ? s_ARREADY_i
    //             : 1'b0;

    //     end

    // endgenerate

endmodule