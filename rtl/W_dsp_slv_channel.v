module W_dsp_slv_channel #(
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,

    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),

    parameter                       ADDR_WIDTH          = 32,
	 parameter								DATA_WIDTH			  = 32,
    parameter                       TRANS_MST_ID_W      = 5,
    parameter                       TRANS_BURST_W       = 2,
    parameter                       TRANS_DATA_LEN_W    = 3,
    parameter                       TRANS_DATA_SIZE_W   = 3

)
(
//--------------------------------------------------
// Master arbiter interface
//--------------------------------------------------
input   [DATA_WIDTH*MST_AMT-1:0]    ma_WDATA_i,
input   [MST_AMT-1:0]               ma_WLAST_i,
// input   [MST_AMT-1:0]               ma_WVALID_i,
// output  [MST_AMT-1:0]               ma_WREADY_o,

//--------------------------------------------------
// Slave interface
//--------------------------------------------------
output  [DATA_WIDTH-1:0]            s_WDATA_o,
output                              s_WLAST_o,
// output                              s_WVALID_o,
// input                               s_WREADY_i,

//--------------------------------------------------
// Controller
//--------------------------------------------------
input   [MST_ID_W-1:0]              ctl_MST_ID_i

);

//--------------------------------------------------
// Localparam
//--------------------------------------------------

localparam DATA_IN_MUX_WIDTH =
    DATA_WIDTH +
    1    // WLAST
    ;      // WVALID

//--------------------------------------------------
// MUX signals
//--------------------------------------------------

wire [DATA_IN_MUX_WIDTH*MST_AMT-1:0] mux_in;
wire [DATA_IN_MUX_WIDTH-1:0]         mux_out;

//--------------------------------------------------
// Pack master inputs
//--------------------------------------------------

genvar idx;

generate

    for(idx=0; idx<MST_AMT; idx=idx+1)
    begin : W_MUX_INPUT

        assign mux_in[
            DATA_IN_MUX_WIDTH*idx +:
            DATA_IN_MUX_WIDTH
        ]
        =
        {
            ma_WDATA_i[
                DATA_WIDTH*idx +:
                DATA_WIDTH
            ],

            ma_WLAST_i[idx]

            //ma_WVALID_i[idx]
        };

    end

endgenerate

//--------------------------------------------------
// MUX
//--------------------------------------------------

common_mux #(
    .DATA_WIDTH (DATA_IN_MUX_WIDTH),
    .OUT_AMT    (MST_AMT)
) W_slv_mux (
    .data_i (mux_in),
    .sel_i  (ctl_MST_ID_i),
    .data_o (mux_out)
);

//--------------------------------------------------
// Unpack
//--------------------------------------------------

assign {
    s_WDATA_o,
    s_WLAST_o
    //s_WVALID_o
} = mux_out;

//--------------------------------------------------
// READY demux
//--------------------------------------------------

// generate

//     for(idx=0; idx<MST_AMT; idx=idx+1)
//     begin : W_READY_DEMUX

//         assign ma_WREADY_o[idx] =
//             (ctl_MST_ID_i == idx)
//             ? s_WREADY_i
//             : 1'b0;

//     end

// endgenerate

endmodule
