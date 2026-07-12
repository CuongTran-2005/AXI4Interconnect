`timescale 1ns / 1ps

module axi4_interconnect #(
    parameter MST_AMT             = 4,
    parameter SLV_AMT             = 4,
    parameter DATA_WIDTH          = 32,
    parameter ADDR_WIDTH          = 32,
    parameter TRANS_MST_ID_W      = 5,    // Bit-width of AXI ID fields
	 parameter                       TRANS_BURST_W       = 2,
    parameter                       TRANS_DATA_LEN_W    = 8,
    parameter                       TRANS_DATA_SIZE_W   = 3,
    parameter                       TRANS_WR_RESP_W     = 2,
    parameter                       TRANS_QOS_W         = 16,
    parameter MST_ID_W            = 2,    // $clog2(MST_AMT)
    parameter SLV_ID_W            = 2,    // $clog2(SLV_AMT)
    parameter FIFO_DEPTH          = 4
)(
    input wire                                      ACLK_i,
    input wire                                      ARESETn_i,

    // =========================================================================
    // Master-Side Unified Vector Interfaces (From Masters)
    // =========================================================================
    // Write Address Channel (AW)
    input  wire [TRANS_MST_ID_W*MST_AMT-1:0]        m_AWID_i,
    input  wire [ADDR_WIDTH*MST_AMT-1:0]            m_AWADDR_i,
    input  wire [TRANS_DATA_LEN_W*MST_AMT-1:0]                     m_AWLEN_i,
    input  wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]                     m_AWSIZE_i,
    input  wire [TRANS_BURST_W*MST_AMT-1:0]                     m_AWBURST_i,
	 input  wire [TRANS_QOS_W*MST_AMT-1:0]                     m_AWQOS_i,
    input  wire [MST_AMT-1:0]                       m_AWVALID_i,
    output wire [MST_AMT-1:0]                       m_AWREADY_o,

    // Write Data Channel (W)
    input  wire [DATA_WIDTH*MST_AMT-1:0]            m_WDATA_i,
    input  wire [MST_AMT-1:0]                       m_WLAST_i,
    input  wire [MST_AMT-1:0]                       m_WVALID_i,
    output wire [MST_AMT-1:0]                       m_WREADY_o,

    // Write Response Channel (B)
    output wire [TRANS_MST_ID_W*MST_AMT-1:0]        m_BID_o,
    output wire [TRANS_WR_RESP_W*MST_AMT-1:0]                     m_BRESP_o,
    output wire [MST_AMT-1:0]                       m_BVALID_o,
    input  wire [MST_AMT-1:0]                       m_BREADY_i,

    // Read Address Channel (AR)
    input  wire [TRANS_MST_ID_W*MST_AMT-1:0]        m_ARID_i,
    input  wire [ADDR_WIDTH*MST_AMT-1:0]            m_ARADDR_i,
    input  wire [TRANS_DATA_LEN_W*MST_AMT-1:0]                     m_ARLEN_i,
    input  wire [TRANS_DATA_SIZE_W*MST_AMT-1:0]                     m_ARSIZE_i,
    input  wire [TRANS_BURST_W*MST_AMT-1:0]                     m_ARBURST_i,
	 input  wire [TRANS_QOS_W*MST_AMT-1:0]                     m_ARQOS_i,
    input  wire [MST_AMT-1:0]                       m_ARVALID_i,
    output wire [MST_AMT-1:0]                       m_ARREADY_o,

    // Read Data Channel (R)
    output wire [TRANS_MST_ID_W*MST_AMT-1:0]        m_RID_o,
    output wire [DATA_WIDTH*MST_AMT-1:0]            m_RDATA_o,
    output wire [TRANS_WR_RESP_W*MST_AMT-1:0]                     m_RRESP_o,
    output wire [MST_AMT-1:0]                       m_RLAST_o,
    output wire [MST_AMT-1:0]                       m_RVALID_o,
    input  wire [MST_AMT-1:0]                       m_RREADY_i,

    // =========================================================================
    // Slave-Side Unified Vector Interfaces (To Slaves)
    // =========================================================================
    // Write Address Channel (AW)
    output wire [TRANS_MST_ID_W*SLV_AMT-1:0]        s_AWID_o,
    output wire [ADDR_WIDTH*SLV_AMT-1:0]            s_AWADDR_o,
    output wire [TRANS_BURST_W*SLV_AMT-1:0]                     s_AWBURST_o,
    output wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]                     s_AWLEN_o,
    output wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]                     s_AWSIZE_o,
	 output wire [TRANS_QOS_W*SLV_AMT-1:0]                     s_AWQOS_o,
    output wire [SLV_AMT-1:0]                       s_AWVALID_o,
    input  wire [SLV_AMT-1:0]                       s_AWREADY_i,

    // Write Data Channel (W)
    output wire [DATA_WIDTH*SLV_AMT-1:0]            s_WDATA_o,
    output wire [SLV_AMT-1:0]                       s_WLAST_o,
    output wire [SLV_AMT-1:0]                       s_WVALID_o,
    input  wire [SLV_AMT-1:0]                       s_WREADY_i,

    // Write Response Channel (B)
    input  wire [TRANS_MST_ID_W*SLV_AMT-1:0]        s_BID_i,
    input  wire [TRANS_WR_RESP_W*SLV_AMT-1:0]                     s_BRESP_i,
    input  wire [SLV_AMT-1:0]                       s_BVALID_i,
    output wire [SLV_AMT-1:0]                       s_BREADY_o,

    // Read Address Channel (AR)
    output wire [TRANS_MST_ID_W*SLV_AMT-1:0]        s_ARID_o,
    output wire [ADDR_WIDTH*SLV_AMT-1:0]            s_ARADDR_o,
    output wire [TRANS_BURST_W*SLV_AMT-1:0]                     s_ARBURST_o,
    output wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]                     s_ARLEN_o,
    output wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]                     s_ARSIZE_o,
	 output wire [TRANS_QOS_W*SLV_AMT-1:0]                     s_ARQOS_o,
    output wire [SLV_AMT-1:0]                       s_ARVALID_o,
    input  wire [SLV_AMT-1:0]                       s_ARREADY_i,

    // Read Data Channel (R)
    input  wire [TRANS_MST_ID_W*SLV_AMT-1:0]        s_RID_i,
    input  wire [DATA_WIDTH*SLV_AMT-1:0]            s_RDATA_i,
    input  wire [TRANS_WR_RESP_W*SLV_AMT-1:0]                     s_RRESP_i,
    input  wire [SLV_AMT-1:0]                       s_RLAST_i,
    input  wire [SLV_AMT-1:0]                       s_RVALID_i,
    output wire [SLV_AMT-1:0]                       s_RREADY_o
);

    // =========================================================================
    // Interconnect Internal Routing Logic & Wires
    // =========================================================================
    
    // Decoded target Slave IDs outputted by each Master's Controller
    wire [SLV_ID_W-1:0] m_slave_id_aw [0:MST_AMT-1];
    wire [SLV_ID_W-1:0] m_slave_id_w  [0:MST_AMT-1];
    wire [SLV_ID_W-1:0] m_slave_id_b  [0:MST_AMT-1];
    wire [SLV_ID_W-1:0] m_slave_id_ar [0:MST_AMT-1];
    wire [SLV_ID_W-1:0] m_slave_id_r  [0:MST_AMT-1];

    // Master Request Matrix maps targeting information to individual Slave Arbiters
    reg [MST_AMT-1:0] slv_aw_req_vector [0:SLV_AMT-1];
    reg [MST_AMT-1:0] slv_ar_req_vector [0:SLV_AMT-1];

    // Winning Master IDs outputted by each Slave's Arbiter
    wire [MST_ID_W-1:0] s_master_id_aw [0:SLV_AMT-1];
    wire [MST_ID_W-1:0] s_master_id_w  [0:SLV_AMT-1];
    wire [MST_ID_W-1:0] s_master_id_b  [0:SLV_AMT-1];
    wire [MST_ID_W-1:0] s_master_id_ar [0:SLV_AMT-1];
    wire [MST_ID_W-1:0] s_master_id_r  [0:SLV_AMT-1];

    // Global Handshake tracking wires
    wire [MST_AMT-1:0] m_aw_handshake, m_w_handshake, m_b_handshake;
    wire [MST_AMT-1:0] m_ar_handshake, m_r_handshake;
    wire [MST_AMT-1:0] m_wlast, m_rlast;
    wire [SLV_AMT-1:0] s_aw_handshake, s_w_handshake, s_b_handshake;
    wire [SLV_AMT-1:0] s_ar_handshake, s_r_handshake;
    wire [SLV_AMT-1:0] s_wlast, s_rlast;

    // =========================================================================
    // 1. GENERATE BLOCK: Controllers (One per Master)
    // =========================================================================
    //wire
//================ Master DSP =================
    wire [MST_AMT-1:0] ctl_mst_dsp_aw_valid;
    wire [MST_AMT-1:0] ctl_mst_dsp_ar_valid;
    wire [MST_AMT-1:0] ctl_mst_dsp_w_valid;
    wire [MST_AMT-1:0] ctl_mst_dsp_r_valid;
    wire [MST_AMT-1:0] ctl_mst_dsp_b_valid;

    wire [MST_AMT-1:0] ctl_mst_dsp_aw_ready;
    wire [MST_AMT-1:0] ctl_mst_dsp_ar_ready;
    wire [MST_AMT-1:0] ctl_mst_dsp_w_ready;
    wire [MST_AMT-1:0] ctl_mst_dsp_r_ready;
    wire [MST_AMT-1:0] ctl_mst_dsp_b_ready;

    //================ Master Skid Buffer =================
    wire [MST_AMT-1:0] ctl_mst_sk_aw_valid;
    wire [MST_AMT-1:0] ctl_mst_sk_ar_valid;
    wire [MST_AMT-1:0] ctl_mst_sk_w_valid;
    wire [MST_AMT-1:0] ctl_mst_sk_r_valid;
    wire [MST_AMT-1:0] ctl_mst_sk_b_valid;

    wire [MST_AMT-1:0] ctl_mst_sk_aw_ready;
    wire [MST_AMT-1:0] ctl_mst_sk_ar_ready;
    wire [MST_AMT-1:0] ctl_mst_sk_w_ready;
    wire [MST_AMT-1:0] ctl_mst_sk_r_ready;
    wire [MST_AMT-1:0] ctl_mst_sk_b_ready;
    //generate
    genvar m;
    generate
        for (m = 0; m < MST_AMT; m = m + 1) begin : master_controllers
            
            // Assign master-specific handshake flags
            // assign m_aw_handshake[m] = m_AWVALID_i[m] && m_AWREADY_o[m];
            // assign m_w_handshake[m]  = m_WVALID_i[m]  && m_WREADY_o[m];
            // assign m_b_handshake[m]  = m_BVALID_o[m]  && m_BREADY_i[m];
            // assign m_ar_handshake[m] = m_ARVALID_i[m] && m_ARREADY_o[m];
            // assign m_r_handshake[m]  = m_RVALID_o[m]  && m_RREADY_i[m];

            // controller #(
            //     .SLAVE_ID_WIDTH(SLV_ID_W),
            //     .ADDR_WIDTH(ADDR_WIDTH)
            // ) u_controller_inst (
            //     .clk            (ACLK_i),
            //     .rst_n          (ARESETn_i),

            //     // Write Flow Control
            //     .AWADDR_i       (m_AWADDR_i[m*ADDR_WIDTH +: ADDR_WIDTH]),
            //     .AW_handshake_i (m_aw_handshake[m]),
            //     .W_handshake_i  (m_w_handshake[m]),
            //     .WLAST_i        (m_wlast[m]),
            //     .B_handshake_i  (m_b_handshake[m]),
                
            //     .Slave_id_aw_o  (m_slave_id_aw[m]),
            //     .Slave_id_w_o   (m_slave_id_w[m]),
            //     .Slave_id_b_o   (m_slave_id_b[m]),
            //     .AW_full_o      (), // Optional full flag monitoring

            //     // Read Flow Control
            //     .ARADDR_i       (m_ARADDR_i[m*ADDR_WIDTH +: ADDR_WIDTH]),
            //     .AR_handshake_i (m_ar_handshake[m]),
            //     .R_handshake_i  (m_r_handshake[m]),
            //     .RLAST_i        (m_rlast[m]),
                
            //     .Slave_id_ar_o  (m_slave_id_ar[m]),
            //     .Slave_id_r_o   (m_slave_id_r[m]),
            //     .AR_full_o      ()
            // );
            controller #(
                .SLAVE_ID_WIDTH    (SLV_ID_W),
                .ADDR_WIDTH        (ADDR_WIDTH)
            )
            u_controller_inst (
                .clk                        (ACLK_i),
                .rst_n                      (ARESETn_i),

                // -------------------------------------------------------------------------
                // Write Channel
                // -------------------------------------------------------------------------
                .AWADDR_i                   (m_AWADDR_i[m*ADDR_WIDTH +: ADDR_WIDTH]),
                .WLAST_i                    (ctl_mst_wlast[m]),

                .Slave_id_aw_o              (m_slave_id_aw[m]),
                .Slave_id_w_o               (m_slave_id_w[m]),
                .Slave_id_b_o               (m_slave_id_b[m]),

                // -------------------------------------------------------------------------
                // Read Channel
                // -------------------------------------------------------------------------
                .ARADDR_i                   (m_ARADDR_i[m*ADDR_WIDTH +: ADDR_WIDTH]),
                .RLAST_i                    (ctl_mst_rlast[m]),

                .Slave_id_ar_o              (m_slave_id_ar[m]),
                .Slave_id_r_o               (m_slave_id_r[m]),

                // -------------------------------------------------------------------------
                // Master Skid Buffer Interface
                // -------------------------------------------------------------------------
                .ctl_mst_sk_aw_valid_i      (ctl_mst_sk_aw_valid[m]),
                .ctl_mst_sk_ar_valid_i      (ctl_mst_sk_ar_valid[m]),
                .ctl_mst_sk_w_valid_i       (ctl_mst_sk_w_valid[m]),

                .ctl_mst_sk_r_valid_o       (ctl_mst_sk_r_valid[m]),
                .ctl_mst_sk_b_valid_o       (ctl_mst_sk_b_valid[m]),

                .ctl_mst_sk_aw_ready_o      (ctl_mst_sk_aw_ready[m]),
                .ctl_mst_sk_ar_ready_o      (ctl_mst_sk_ar_ready[m]),
                .ctl_mst_sk_w_ready_o       (ctl_mst_sk_w_ready[m]),

                .ctl_mst_sk_r_ready_i       (ctl_mst_sk_r_ready[m]),
                .ctl_mst_sk_b_ready_i       (ctl_mst_sk_b_ready[m]),

                // -------------------------------------------------------------------------
                // Master DSP Interface
                // -------------------------------------------------------------------------
                .ctl_mst_dsp_aw_valid_o     (ctl_mst_dsp_aw_valid[m]),
                .ctl_mst_dsp_ar_valid_o     (ctl_mst_dsp_ar_valid[m]),
                .ctl_mst_dsp_w_valid_o      (ctl_mst_dsp_w_valid[m]),

                .ctl_mst_dsp_r_valid_i      (ctl_mst_dsp_r_valid[m]),
                .ctl_mst_dsp_b_valid_i      (ctl_mst_dsp_b_valid[m]),

                .ctl_mst_dsp_aw_ready_i     (ctl_mst_dsp_aw_ready[m]),
                .ctl_mst_dsp_ar_ready_i     (ctl_mst_dsp_ar_ready[m]),
                .ctl_mst_dsp_w_ready_i      (ctl_mst_dsp_w_ready[m]),

                .ctl_mst_dsp_r_ready_o      (ctl_mst_dsp_r_ready[m]),
                .ctl_mst_dsp_b_ready_o      (ctl_mst_dsp_b_ready[m])
            );
        end
    endgenerate

    // =========================================================================
    // Request Mapping Logic (Transposes Master targets to Slave request buses)
    // =========================================================================
    integer slv_idx, mst_idx;
    always @(*) begin
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            slv_aw_req_vector[slv_idx] = {MST_AMT{1'b0}};
            slv_ar_req_vector[slv_idx] = {MST_AMT{1'b0}};
            
            for (mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin
                // Map AW request bit if the Master's controller matches this Slave index
                if (m_AWVALID_i[mst_idx] && (m_slave_id_aw[mst_idx] == slv_idx)) begin
                    slv_aw_req_vector[slv_idx][mst_idx] = 1'b1;
                end
                // Map AR request bit if the Master's controller matches this Slave index
                if (m_ARVALID_i[mst_idx] && (m_slave_id_ar[mst_idx] == slv_idx)) begin
                    slv_ar_req_vector[slv_idx][mst_idx] = 1'b1;
                end
            end
        end
    end

    // =========================================================================
    // 2. GENERATE BLOCK: Arbiters (One per Slave)
    // =========================================================================
    //wire
    wire [SLV_AMT-1:0] ctl_slv_dsp_aw_valid;
    wire [SLV_AMT-1:0] ctl_slv_dsp_ar_valid;
    wire [SLV_AMT-1:0] ctl_slv_dsp_w_valid;
    wire [SLV_AMT-1:0] ctl_slv_dsp_r_valid;
    wire [SLV_AMT-1:0] ctl_slv_dsp_b_valid;

    wire [SLV_AMT-1:0] ctl_slv_dsp_aw_ready;
    wire [SLV_AMT-1:0] ctl_slv_dsp_ar_ready;
    wire [SLV_AMT-1:0] ctl_slv_dsp_w_ready;
    wire [SLV_AMT-1:0] ctl_slv_dsp_r_ready;
    wire [SLV_AMT-1:0] ctl_slv_dsp_b_ready;

    wire [SLV_AMT-1:0] ctl_slv_sk_aw_valid;
    wire [SLV_AMT-1:0] ctl_slv_sk_ar_valid;
    wire [SLV_AMT-1:0] ctl_slv_sk_w_valid;
    wire [SLV_AMT-1:0] ctl_slv_sk_r_valid;
    wire [SLV_AMT-1:0] ctl_slv_sk_b_valid;

    wire [SLV_AMT-1:0] ctl_slv_sk_aw_ready;
    wire [SLV_AMT-1:0] ctl_slv_sk_ar_ready;
    wire [SLV_AMT-1:0] ctl_slv_sk_w_ready;
    wire [SLV_AMT-1:0] ctl_slv_sk_r_ready;
    wire [SLV_AMT-1:0] ctl_slv_sk_b_ready;
    //generate
    genvar s;
    generate
        for (s = 0; s < SLV_AMT; s = s + 1) begin : slave_arbiters
            
            // Assign slave-specific handshake flags
            // assign s_aw_handshake[s] = s_AWVALID_o[s] && s_AWREADY_i[s];
            // assign s_w_handshake[s]  = s_WVALID_o[s]  && s_WREADY_i[s];
            // assign s_b_handshake[s]  = s_BVALID_i[s]  && s_BREADY_o[s];
            // assign s_ar_handshake[s] = s_ARVALID_o[s] && s_ARREADY_i[s];
            // assign s_r_handshake[s]  = s_RVALID_i[s]  && s_RREADY_o[s];

            // arbiter_top #(
            //     .NUM_MASTERS(MST_AMT),
            //     .ID_WIDTH(MST_ID_W),
            //     .AXI_ID_WIDTH(TRANS_MST_ID_W),
            //     .FIFO_DEPTH(FIFO_DEPTH)
            // ) u_arbiter_inst (
            //     .clk            (ACLK_i),
            //     .rst_n          (ARESETn_i),

            //     // AW Channel Arbitration
            //     .aw_req          (slv_aw_req_vector[s]),
            //     .aw_handshake    (s_aw_handshake[s]),
            //     .Master_id_aw    (s_master_id_aw[s]),
            //     .aw_fifo_full    (),

            //     // W Channel Tracking
            //     .w_handshake     (s_w_handshake[s]),
            //     .WLAST           (s_wlast[s]),
            //     .Master_id_w     (s_master_id_w[s]),

            //     // B Channel Routing Back Extractor
            //     .BID             (s_BID_i[s*TRANS_MST_ID_W +: TRANS_MST_ID_W]),
            //     .Master_id_b     (s_master_id_b[s]),

            //     // AR Channel Arbitration
            //     .ar_req          (slv_ar_req_vector[s]),
            //     .ar_handshake    (s_ar_handshake[s]),
            //     .Master_id_ar    (s_master_id_ar[s]),

            //     // R Channel Routing Back Extractor
            //     .RID             (s_RID_i[s*TRANS_MST_ID_W +: TRANS_MST_ID_W]),
            //     .Master_id_r     (s_master_id_r[s])
            // );
            arbiter_top #(
                .NUM_MASTERS   (MST_AMT),
                .ID_WIDTH      (MST_ID_W),
                .AXI_ID_WIDTH  (TRANS_MST_ID_W),
                .FIFO_DEPTH    (FIFO_DEPTH)
            )
            u_arbiter_inst (
                .clk                        (ACLK_i),
                .rst_n                      (ARESETn_i),

                // -------------------------------------------------------------------------
                // AW Channel
                // -------------------------------------------------------------------------
                .aw_req                     (slv_aw_req_vector[s]),
                .Master_id_aw               (s_master_id_aw[s]),
                .aw_fifo_full               (),

                // -------------------------------------------------------------------------
                // W Channel
                // -------------------------------------------------------------------------
                .WLAST                      (ctl_slv_wlast[s]),
                .Master_id_w                (s_master_id_w[s]),

                // -------------------------------------------------------------------------
                // B Channel
                // -------------------------------------------------------------------------
                .BID                        (s_BID_i[s*TRANS_MST_ID_W +: TRANS_MST_ID_W]),
                .Master_id_b                (s_master_id_b[s]),

                // -------------------------------------------------------------------------
                // AR Channel
                // -------------------------------------------------------------------------
                .ar_req                     (slv_ar_req_vector[s]),
                .Master_id_ar               (s_master_id_ar[s]),

                // -------------------------------------------------------------------------
                // R Channel
                // -------------------------------------------------------------------------
                .RID                        (s_RID_i[s*TRANS_MST_ID_W +: TRANS_MST_ID_W]),
                .Master_id_r                (s_master_id_r[s]),

                // -------------------------------------------------------------------------
                // Slave DSP Interface
                // -------------------------------------------------------------------------
                .ctl_slv_dsp_aw_valid_i     (ctl_slv_dsp_aw_valid[s]),
                .ctl_slv_dsp_ar_valid_i     (ctl_slv_dsp_ar_valid[s]),
                .ctl_slv_dsp_w_valid_i      (ctl_slv_dsp_w_valid[s]),

                .ctl_slv_dsp_r_valid_o      (ctl_slv_dsp_r_valid[s]),
                .ctl_slv_dsp_b_valid_o      (ctl_slv_dsp_b_valid[s]),

                .ctl_slv_dsp_aw_ready_o     (ctl_slv_dsp_aw_ready[s]),
                .ctl_slv_dsp_ar_ready_o     (ctl_slv_dsp_ar_ready[s]),
                .ctl_slv_dsp_w_ready_o      (ctl_slv_dsp_w_ready[s]),

                .ctl_slv_dsp_r_ready_i      (ctl_slv_dsp_r_ready[s]),
                .ctl_slv_dsp_b_ready_i      (ctl_slv_dsp_b_ready[s]),

                // -------------------------------------------------------------------------
                // Slave Skid Buffer Interface
                // -------------------------------------------------------------------------
                .ctl_slv_sk_aw_valid_o      (ctl_slv_sk_aw_valid[s]),
                .ctl_slv_sk_ar_valid_o      (ctl_slv_sk_ar_valid[s]),
                .ctl_slv_sk_w_valid_o       (ctl_slv_sk_w_valid[s]),

                .ctl_slv_sk_r_valid_i       (ctl_slv_sk_r_valid[s]),
                .ctl_slv_sk_b_valid_i       (ctl_slv_sk_b_valid[s]),

                .ctl_slv_sk_aw_ready_i      (ctl_slv_sk_aw_ready[s]),
                .ctl_slv_sk_ar_ready_i      (ctl_slv_sk_ar_ready[s]),
                .ctl_slv_sk_w_ready_i       (ctl_slv_sk_w_ready[s]),

                .ctl_slv_sk_r_ready_o       (ctl_slv_sk_r_ready[s]),
                .ctl_slv_sk_b_ready_o       (ctl_slv_sk_b_ready[s])
            );
        end
    endgenerate
	 
	 // =========================================================================
    // Pack/Unpack Vectors for Datapath Control Ports
    // =========================================================================
    wire [SLV_ID_W * MST_AMT-1:0]  flat_slave_id_aw, flat_slave_id_w, flat_slave_id_b;
    wire [SLV_ID_W * MST_AMT-1:0]  flat_slave_id_ar, flat_slave_id_r;
    
    wire [MST_ID_W * SLV_AMT-1:0]  flat_master_id_aw, flat_master_id_w, flat_master_id_b;
    wire [MST_ID_W * SLV_AMT-1:0]  flat_master_id_ar, flat_master_id_r;

    wire [ADDR_WIDTH * MST_AMT-1:0] ctl_AWADDR_out, ctl_ARADDR_out;
    wire [MST_AMT * SLV_AMT-1:0]    fifo_aw_req_out, fifo_ar_req_out;
    wire [TRANS_MST_ID_W*SLV_AMT-1:0] b_trans_mst_id_out, r_trans_mst_id_out;

    genvar i;
    generate
        // Pack Master -> Slave IDs (from Controllers to Datapath)
        for (i = 0; i < MST_AMT; i = i + 1) begin : pack_mst_to_slv
            assign flat_slave_id_aw[i*SLV_ID_W +: SLV_ID_W] = m_slave_id_aw[i];
            assign flat_slave_id_w [i*SLV_ID_W +: SLV_ID_W] = m_slave_id_w[i];
            assign flat_slave_id_b [i*SLV_ID_W +: SLV_ID_W] = m_slave_id_b[i];
            assign flat_slave_id_ar[i*SLV_ID_W +: SLV_ID_W] = m_slave_id_ar[i];
            assign flat_slave_id_r [i*SLV_ID_W +: SLV_ID_W] = m_slave_id_r[i];
            
            // Note: Update your Controller instantiations to use ctl_AWADDR_out / ctl_ARADDR_out 
            // instead of m_AWADDR_i directly:
            // .AWADDR_i (ctl_AWADDR_out[i*ADDR_WIDTH +: ADDR_WIDTH])
        end

        // Pack Slave -> Master IDs (from Arbiters to Datapath)
        for (i = 0; i < SLV_AMT; i = i + 1) begin : pack_slv_to_mst
            assign flat_master_id_aw[i*MST_ID_W +: MST_ID_W] = s_master_id_aw[i];
            assign flat_master_id_w [i*MST_ID_W +: MST_ID_W] = s_master_id_w[i];
            assign flat_master_id_b [i*MST_ID_W +: MST_ID_W] = s_master_id_b[i];
            assign flat_master_id_ar[i*MST_ID_W +: MST_ID_W] = s_master_id_ar[i];
            assign flat_master_id_r [i*MST_ID_W +: MST_ID_W] = s_master_id_r[i];
            
            // Note: Update your Arbiter instantiations to take the parsed req/id signals:
            // .aw_req (fifo_aw_req_out[i*MST_AMT +: MST_AMT])
            // .BID    (b_trans_mst_id_out[i*TRANS_MST_ID_W +: TRANS_MST_ID_W])
        end
    endgenerate

    // =========================================================================
    // 3. Structural Routing Datapath Instantiation
    // =========================================================================
    //wire
    wire [MST_AMT-1:0] ctl_mst_wlast;
    wire [MST_AMT-1:0] ctl_mst_rlast;

    wire [SLV_AMT-1:0] ctl_slv_wlast;
    wire [SLV_AMT-1:0] ctl_slv_rlast;

    // axi_datapath #(
    //     .MST_AMT(MST_AMT),
    //     .SLV_AMT(SLV_AMT),
    //     .MST_ID_W(MST_ID_W),
    //     .SLV_ID_W(SLV_ID_W),
    //     .DATA_WIDTH(DATA_WIDTH),
    //     .ADDR_WIDTH(ADDR_WIDTH),
    //     .TRANS_MST_ID_W(TRANS_MST_ID_W),
    //     .FIFO_DEPTH(FIFO_DEPTH)
    // ) u_axi_datapath (
    //     .ACLK_i             (ACLK_i),
    //     .ARESETn_i          (ARESETn_i),

    //     // ... (Keep all your standard m_AWADDR, s_AWADDR, etc. AXI connections here) ...
	// 	  // Master Side Inputs/Outputs
    //     .m_ARID_i        (m_ARID_i),
    //     .m_ARADDR_i      (m_ARADDR_i),
    //     .m_ARLEN_i       (m_ARLEN_i),
    //     .m_ARSIZE_i      (m_ARSIZE_i),
    //     .m_ARBURST_i     (m_ARBURST_i),
    //     .m_ARVALID_i     (m_ARVALID_i),
    //     .m_ARREADY_o     (m_ARREADY_o),
    //     .m_RID_o         (m_RID_o),
    //     .m_RDATA_o       (m_RDATA_o),
    //     .m_RRESP_o       (m_RRESP_o),
    //     .m_RLAST_o       (m_RLAST_o),
    //     .m_RVALID_o      (m_RVALID_o),
    //     .m_RREADY_i      (m_RREADY_i),
    //     .m_AWID_i        (m_AWID_i),
    //     .m_AWADDR_i      (m_AWADDR_i),
    //     .m_AWLEN_i       (m_AWLEN_i),
    //     .m_AWSIZE_i      (m_AWSIZE_i),
    //     .m_AWBURST_i     (m_AWBURST_i),
    //     .m_AWVALID_i     (m_AWVALID_i),
    //     .m_AWREADY_o     (m_AWREADY_o),
    //     .m_WDATA_i       (m_WDATA_i),
    //     .m_WLAST_i       (m_WLAST_i),
    //     .m_WVALID_i      (m_WVALID_i),
    //     .m_WREADY_o      (m_WREADY_o),
    //     .m_BID_o         (m_BID_o),
    //     .m_BRESP_o       (m_BRESP_o),
    //     .m_BVALID_o      (m_BVALID_o),
    //     .m_BREADY_i      (m_BREADY_i),

    //     // Slave Side Inputs/Outputs
    //     .s_AWID_o        (s_AWID_o),
    //     .s_AWADDR_o      (s_AWADDR_o),
    //     .s_AWBURST_o     (s_AWBURST_o),
    //     .s_AWLEN_o       (s_AWLEN_o),
    //     .s_AWSIZE_o      (s_AWSIZE_o),
    //     .s_AWVALID_o     (s_AWVALID_o),
    //     .s_AWREADY_i     (s_AWREADY_i),
    //     .s_WDATA_o       (s_WDATA_o),
    //     .s_WLAST_o       (s_WLAST_o),
    //     .s_WVALID_o      (s_WVALID_o),
    //     .s_WREADY_i      (s_WREADY_i),
    //     .s_BID_i         (s_BID_i),
    //     .s_BRESP_i       (s_BRESP_i),
    //     .s_BVALID_i      (s_BVALID_i),
    //     .s_BREADY_o      (s_BREADY_o),
    //     .s_ARID_o        (s_ARID_o),
    //     .s_ARADDR_o      (s_ARADDR_o),
    //     .s_ARBURST_o     (s_ARBURST_o),
    //     .s_ARLEN_o       (s_ARLEN_o),
    //     .s_ARSIZE_o      (s_ARSIZE_o),
    //     .s_ARVALID_o     (s_ARVALID_o),
    //     .s_ARREADY_i     (s_ARREADY_i),
    //     .s_RID_i         (s_RID_i),
    //     .s_RDATA_i       (s_RDATA_i),
    //     .s_RRESP_i       (s_RRESP_i),
    //     .s_RLAST_i       (s_RLAST_i),
    //     .s_RVALID_i      (s_RVALID_i),
    //     .s_RREADY_o      (s_RREADY_o),

    //     // -------------------------------------------------------------
    //     // Control routing signals from Controllers
    //     // -------------------------------------------------------------
    //     .ctl_slave_id_aw_i  (flat_slave_id_aw),
    //     .ctl_slave_id_w_i   (flat_slave_id_w),
    //     .ctl_slave_id_b_i   (flat_slave_id_b),
    //     .ctl_AWADDR_o       (ctl_AWADDR_out),    // Feed this TO the Controllers
        
    //     .ctl_slave_id_ar_i  (flat_slave_id_ar),
    //     .ctl_slave_id_r_i   (flat_slave_id_r),
    //     .ctl_ARADDR_o       (ctl_ARADDR_out),    // Feed this TO the Controllers

    //     // -------------------------------------------------------------
    //     // Control routing signals from Arbiters
    //     // -------------------------------------------------------------
    //     .ctl_master_id_aw_i (flat_master_id_aw),
    //     .ctl_master_id_w_i  (flat_master_id_w),
    //     .ctl_master_id_b_i  (flat_master_id_b),
        
    //     .ctl_master_id_ar_i (flat_master_id_ar),
    //     .ctl_master_id_r_i  (flat_master_id_r),

    //     // -------------------------------------------------------------
    //     // Feedback signals to Arbiters
    //     // -------------------------------------------------------------
    //     .r_trans_mst_id     (r_trans_mst_id_out), // Feed this TO Arbiter RID port
    //     .b_trans_mst_id     (b_trans_mst_id_out), // Feed this TO Arbiter BID port
        
    //     .fifo_ar_req        (fifo_ar_req_out),    // Feed this TO Arbiter ar_req port
    //     .fifo_aw_req        (fifo_aw_req_out),     // Feed this TO Arbiter aw_req port
    //     //handshake signals are already connected directly to the Arbiters and Controllers
    //     //slave side
    //     .ctl_slv_aw_handshake (s_aw_handshake),
    //     .ctl_slv_ar_handshake (s_ar_handshake),
    //     .ctl_slv_w_handshake (s_w_handshake),
    //     .ctl_slv_r_handshake (s_r_handshake),
    //     .ctl_slv_b_handshake (s_b_handshake),
    //     .ctl_slv_wlast (s_wlast),
    //     .ctl_slv_rlast (s_rlast),
    //     //master side
    //     .ctl_mst_aw_handshake (m_aw_handshake),
    //     .ctl_mst_ar_handshake (m_ar_handshake),
    //     .ctl_mst_w_handshake (m_w_handshake),
    //     .ctl_mst_r_handshake (m_r_handshake),
    //     .ctl_mst_b_handshake (m_b_handshake),
    //     .ctl_mst_wlast (m_wlast),
    //     .ctl_mst_rlast (m_rlast)

    // );

    axi_datapath #(
        .MST_AMT(MST_AMT),
         .SLV_AMT(SLV_AMT),
         .MST_ID_W(MST_ID_W),
         .SLV_ID_W(SLV_ID_W),
         .DATA_WIDTH(DATA_WIDTH),
         .ADDR_WIDTH(ADDR_WIDTH),
         .TRANS_MST_ID_W(TRANS_MST_ID_W),
         .FIFO_DEPTH(FIFO_DEPTH)
    )
    u_axi_datapath
    (
        //--------------------------------------------------
        // Global
        //--------------------------------------------------
        .ACLK_i                 (ACLK_i),
        .ARESETn_i              (ARESETn_i),

        //--------------------------------------------------
        // Master Side
        //--------------------------------------------------
        // AR
        .m_ARID_i               (m_ARID_i),
        .m_ARADDR_i             (m_ARADDR_i),
        .m_ARBURST_i            (m_ARBURST_i),
        .m_ARLEN_i              (m_ARLEN_i),
        .m_ARSIZE_i             (m_ARSIZE_i),
		  .m_ARQOS_i             (m_ARQOS_i),
        .m_ARVALID_i            (m_ARVALID_i),
        .m_ARREADY_o            (m_ARREADY_o),

        // R
        .m_RID_o                (m_RID_o),
        .m_RDATA_o              (m_RDATA_o),
        .m_RRESP_o              (m_RRESP_o),
        .m_RLAST_o              (m_RLAST_o),
        .m_RVALID_o             (m_RVALID_o),
        .m_RREADY_i             (m_RREADY_i),

        // AW
        .m_AWID_i               (m_AWID_i),
        .m_AWADDR_i             (m_AWADDR_i),
        .m_AWBURST_i            (m_AWBURST_i),
        .m_AWLEN_i              (m_AWLEN_i),
        .m_AWSIZE_i             (m_AWSIZE_i),
		  .m_AWQOS_i             (m_AWQOS_i),
        .m_AWVALID_i            (m_AWVALID_i),
        .m_AWREADY_o            (m_AWREADY_o),

        // W
        .m_WDATA_i              (m_WDATA_i),
        .m_WLAST_i              (m_WLAST_i),
        .m_WVALID_i             (m_WVALID_i),
        .m_WREADY_o             (m_WREADY_o),

        // B
        .m_BID_o                (m_BID_o),
        .m_BRESP_o              (m_BRESP_o),
        .m_BVALID_o             (m_BVALID_o),
        .m_BREADY_i             (m_BREADY_i),

        //--------------------------------------------------
        // Slave Side
        //--------------------------------------------------
        // AR
        .s_ARID_o               (s_ARID_o),
        .s_ARADDR_o             (s_ARADDR_o),
        .s_ARBURST_o            (s_ARBURST_o),
        .s_ARLEN_o              (s_ARLEN_o),
        .s_ARSIZE_o             (s_ARSIZE_o),
		  .s_ARQOS_o             (s_ARQOS_o),
        .s_ARVALID_o            (s_ARVALID_o),
        .s_ARREADY_i            (s_ARREADY_i),

        // R
        .s_RID_i                (s_RID_i),
        .s_RDATA_i              (s_RDATA_i),
        .s_RRESP_i              (s_RRESP_i),
        .s_RLAST_i              (s_RLAST_i),
        .s_RVALID_i             (s_RVALID_i),
        .s_RREADY_o             (s_RREADY_o),

        // AW
        .s_AWID_o               (s_AWID_o),
        .s_AWADDR_o             (s_AWADDR_o),
        .s_AWBURST_o            (s_AWBURST_o),
        .s_AWLEN_o              (s_AWLEN_o),
        .s_AWSIZE_o             (s_AWSIZE_o),
		  .s_AWQOS_o             (s_AWQOS_o),
        .s_AWVALID_o            (s_AWVALID_o),
        .s_AWREADY_i            (s_AWREADY_i),

        // W
        .s_WDATA_o              (s_WDATA_o),
        .s_WLAST_o              (s_WLAST_o),
        .s_WVALID_o             (s_WVALID_o),
        .s_WREADY_i             (s_WREADY_i),

        // B
        .s_BID_i                (s_BID_i),
        .s_BRESP_i              (s_BRESP_i),
        .s_BVALID_i             (s_BVALID_i),
        .s_BREADY_o             (s_BREADY_o),

        //--------------------------------------------------
        // Master DSP
        //--------------------------------------------------
        .ctl_slave_id_aw_i      (flat_slave_id_aw),
        .ctl_slave_id_w_i       (flat_slave_id_w),
        .ctl_slave_id_b_i       (flat_slave_id_b),
        .ctl_AWADDR_o           (ctl_AWADDR_out),

        .ctl_slave_id_ar_i      (flat_slave_id_ar),
        .ctl_slave_id_r_i       (flat_slave_id_r),
        .ctl_ARADDR_o           (ctl_ARADDR_out),

        .ctl_mst_dsp_aw_valid_i (ctl_mst_dsp_aw_valid),
        .ctl_mst_dsp_ar_valid_i (ctl_mst_dsp_ar_valid),
        .ctl_mst_dsp_w_valid_i  (ctl_mst_dsp_w_valid),
        .ctl_mst_dsp_r_valid_o  (ctl_mst_dsp_r_valid),
        .ctl_mst_dsp_b_valid_o  (ctl_mst_dsp_b_valid),

        .ctl_mst_dsp_aw_ready_o (ctl_mst_dsp_aw_ready),
        .ctl_mst_dsp_ar_ready_o (ctl_mst_dsp_ar_ready),
        .ctl_mst_dsp_w_ready_o  (ctl_mst_dsp_w_ready),
        .ctl_mst_dsp_r_ready_i  (ctl_mst_dsp_r_ready),
        .ctl_mst_dsp_b_ready_i  (ctl_mst_dsp_b_ready),

        //--------------------------------------------------
        // Master Skid Buffer
        //--------------------------------------------------
        .ctl_mst_sk_aw_valid_o  (ctl_mst_sk_aw_valid),
        .ctl_mst_sk_ar_valid_o  (ctl_mst_sk_ar_valid),
        .ctl_mst_sk_w_valid_o   (ctl_mst_sk_w_valid),
        .ctl_mst_sk_r_valid_i   (ctl_mst_sk_r_valid),
        .ctl_mst_sk_b_valid_i   (ctl_mst_sk_b_valid),

        .ctl_mst_sk_aw_ready_i  (ctl_mst_sk_aw_ready),
        .ctl_mst_sk_ar_ready_i  (ctl_mst_sk_ar_ready),
        .ctl_mst_sk_w_ready_i   (ctl_mst_sk_w_ready),
        .ctl_mst_sk_r_ready_o   (ctl_mst_sk_r_ready),
        .ctl_mst_sk_b_ready_o   (ctl_mst_sk_b_ready),

        .ctl_mst_wlast_o        (ctl_mst_wlast),
        .ctl_mst_rlast_o        (ctl_mst_rlast),

        //--------------------------------------------------
        // Slave DSP
        //--------------------------------------------------
        .ctl_master_id_aw_i     (flat_master_id_aw),
        .ctl_master_id_w_i      (flat_master_id_w),
        .ctl_master_id_b_i      (flat_master_id_b),

        .ctl_master_id_ar_i     (flat_master_id_ar),
        .ctl_master_id_r_i      (flat_master_id_r),

        .ctl_slv_dsp_aw_valid_o (ctl_slv_dsp_aw_valid),
        .ctl_slv_dsp_ar_valid_o (ctl_slv_dsp_ar_valid),
        .ctl_slv_dsp_w_valid_o  (ctl_slv_dsp_w_valid),
        .ctl_slv_dsp_r_valid_i  (ctl_slv_dsp_r_valid),
        .ctl_slv_dsp_b_valid_i  (ctl_slv_dsp_b_valid),

        .ctl_slv_dsp_aw_ready_i (ctl_slv_dsp_aw_ready),
        .ctl_slv_dsp_ar_ready_i (ctl_slv_dsp_ar_ready),
        .ctl_slv_dsp_w_ready_i  (ctl_slv_dsp_w_ready),
        .ctl_slv_dsp_r_ready_o  (ctl_slv_dsp_r_ready),
        .ctl_slv_dsp_b_ready_o  (ctl_slv_dsp_b_ready),

        //--------------------------------------------------
        // Slave Skid Buffer
        //--------------------------------------------------
        .ctl_slv_sk_aw_valid_i  (ctl_slv_sk_aw_valid),
        .ctl_slv_sk_ar_valid_i  (ctl_slv_sk_ar_valid),
        .ctl_slv_sk_w_valid_i   (ctl_slv_sk_w_valid),
        .ctl_slv_sk_r_valid_o   (ctl_slv_sk_r_valid),
        .ctl_slv_sk_b_valid_o   (ctl_slv_sk_b_valid),

        .ctl_slv_sk_aw_ready_o  (ctl_slv_sk_aw_ready),
        .ctl_slv_sk_ar_ready_o  (ctl_slv_sk_ar_ready),
        .ctl_slv_sk_w_ready_o   (ctl_slv_sk_w_ready),
        .ctl_slv_sk_r_ready_i   (ctl_slv_sk_r_ready),
        .ctl_slv_sk_b_ready_i   (ctl_slv_sk_b_ready),

        .ctl_slv_wlast_o        (ctl_slv_wlast),
        .ctl_slv_rlast_o        (ctl_slv_rlast),

        //--------------------------------------------------
        // Arbiter Feedback
        //--------------------------------------------------
        .r_trans_mst_id_o       (r_trans_mst_id_out),
        .b_trans_mst_id_o       (b_trans_mst_id_out),

        .fifo_ar_req_o          (fifo_ar_req_out),
        .fifo_aw_req_o          (fifo_aw_req_out)
    );
endmodule