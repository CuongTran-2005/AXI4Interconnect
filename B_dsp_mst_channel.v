module B_dsp_mst_channel #(
    parameter                       SLV_AMT         = 4,
    parameter                       SLV_ID_W        = $clog2(SLV_AMT),

    parameter                       TRANS_MST_ID_W  = 5,
    parameter                       TRANS_WR_RESP_W = 2
)
(
    //====================================================
    // Master interface
    //====================================================
    output  [TRANS_MST_ID_W-1:0]    m_BID_o,
    output  [TRANS_WR_RESP_W-1:0]   m_BRESP_o,
    //output                          m_BVALID_o,
    //input                           m_BREADY_i,

    //====================================================
    // Slave arbiter interface
    //====================================================
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]  sa_BID_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0] sa_BRESP_i,
    //input   [SLV_AMT-1:0]                 sa_BVALID_i,
    //output  [SLV_AMT-1:0]                 sa_BREADY_o,

    //====================================================
    // Controller interface
    //====================================================
    input   [SLV_ID_W-1:0]                ctl_SLV_ID_i
);

    //----------------------------------------------------
    // Pack slave inputs
    //----------------------------------------------------

    localparam DATA_IN_MUX_WIDTH = TRANS_MST_ID_W + TRANS_WR_RESP_W ;

    wire [DATA_IN_MUX_WIDTH*SLV_AMT-1:0] mux_in;
    wire [DATA_IN_MUX_WIDTH-1:0]         mux_out;

    genvar idx;

    generate
        for(idx=0; idx<SLV_AMT; idx=idx+1)
        begin : B_MUX_INPUT

            assign mux_in[DATA_IN_MUX_WIDTH*idx +: DATA_IN_MUX_WIDTH] =
            {
                sa_BID_i[TRANS_MST_ID_W*idx +: TRANS_MST_ID_W],
                sa_BRESP_i[TRANS_WR_RESP_W*idx +: TRANS_WR_RESP_W]
                //sa_BVALID_i[idx]
            };
        end
    endgenerate

    //----------------------------------------------------
    // MUX
    //----------------------------------------------------

    common_mux #(
        .DATA_WIDTH(DATA_IN_MUX_WIDTH),
        .OUT_AMT   (SLV_AMT)
    ) B_mst_mux (
        .data_i (mux_in),
        .sel_i  (ctl_SLV_ID_i),
        .data_o (mux_out)
    );

    //----------------------------------------------------
    // Unpack mux output
    //----------------------------------------------------

    assign {
        m_BID_o,
        m_BRESP_o
        //m_BVALID_o
    } = mux_out;

    //----------------------------------------------------
    // READY routing
    //----------------------------------------------------
    // generate
    //     for(idx=0; idx<SLV_AMT; idx=idx+1)
    //     begin : B_READY_GEN
    //         assign sa_BREADY_o[idx] =
    //                 (ctl_SLV_ID_i == idx)
    //                 ? m_BREADY_i
    //                 : 1'b0;

    //     end
    // endgenerate

endmodule