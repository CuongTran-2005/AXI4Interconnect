module R_dsp_mst_channel #(
    parameter                       SLV_AMT         = 4,
    parameter                       SLV_ID_W        = $clog2(SLV_AMT),

    parameter                       DATA_WIDTH      = 32,
    parameter                       TRANS_MST_ID_W  = 5,
    parameter                       TRANS_WR_RESP_W = 2
)
(
    //====================================================
    // Master interface
    //====================================================
    output  [TRANS_MST_ID_W-1:0]    m_RID_o,
    output  [DATA_WIDTH-1:0]        m_RDATA_o,
    output  [TRANS_WR_RESP_W-1:0]   m_RRESP_o,
    output                          m_RLAST_o,
    //output                          m_RVALID_o,
    //input                           m_RREADY_i,

    //====================================================
    // Slave arbiter interface
    //====================================================
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]  sa_RID_i,
    input   [DATA_WIDTH*SLV_AMT-1:0]      sa_RDATA_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0] sa_RRESP_i,
    input   [SLV_AMT-1:0]                 sa_RLAST_i,
    //input   [SLV_AMT-1:0]                 sa_RVALID_i,
    //output  [SLV_AMT-1:0]                 sa_RREADY_o,

    //====================================================
    // Controller interface
    //====================================================
    input   [SLV_ID_W-1:0]                ctl_SLV_ID_i
);

    //----------------------------------------------------
    // MUX configuration
    //----------------------------------------------------

    localparam DATA_IN_MUX_WIDTH =
            TRANS_MST_ID_W +
            DATA_WIDTH +
            TRANS_WR_RESP_W +
            1      // RLAST
            ;      // RVALID

    wire [DATA_IN_MUX_WIDTH*SLV_AMT-1:0] mux_in;
    wire [DATA_IN_MUX_WIDTH-1:0]         mux_out;

    //----------------------------------------------------
    // Pack slave signals
    //----------------------------------------------------

    genvar idx;

    generate
        for(idx=0; idx<SLV_AMT; idx=idx+1)
        begin : R_MUX_INPUT

            assign mux_in[
                DATA_IN_MUX_WIDTH*idx +:
                DATA_IN_MUX_WIDTH
            ] =
            {
                sa_RID_i[
                    TRANS_MST_ID_W*idx +:
                    TRANS_MST_ID_W
                ],

                sa_RDATA_i[
                    DATA_WIDTH*idx +:
                    DATA_WIDTH
                ],

                sa_RRESP_i[
                    TRANS_WR_RESP_W*idx +:
                    TRANS_WR_RESP_W
                ],

                sa_RLAST_i[idx]

                //sa_RVALID_i[idx]
            };

        end
    endgenerate

    //----------------------------------------------------
    // MUX
    //----------------------------------------------------

    common_mux #(
        .DATA_WIDTH(DATA_IN_MUX_WIDTH),
        .OUT_AMT   (SLV_AMT)
    ) R_mst_mux (
        .data_i (mux_in),
        .sel_i  (ctl_SLV_ID_i),
        .data_o (mux_out)
    );

    //----------------------------------------------------
    // Unpack mux output
    //----------------------------------------------------

    assign {
        m_RID_o,
        m_RDATA_o,
        m_RRESP_o,
        m_RLAST_o
        //m_RVALID_o
    } = mux_out;

    //----------------------------------------------------
    // RREADY routing
    //----------------------------------------------------

    // generate
    //     for(idx=0; idx<SLV_AMT; idx=idx+1)
    //     begin : R_READY_GEN

    //         assign sa_RREADY_o[idx] =
    //                 (ctl_SLV_ID_i == idx)
    //                 ? m_RREADY_i
    //                 : 1'b0;

    //     end
    // endgenerate

endmodule