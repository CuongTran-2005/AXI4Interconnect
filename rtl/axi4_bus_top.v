`timescale 1ns / 1ps

module axi4_bus_top #(
    parameter MST_AMT             = 4,
    parameter SLV_AMT             = 4,

    parameter DATA_WIDTH          = 32,
    parameter ADDR_WIDTH          = 32,

    parameter TRANS_MST_ID_W      = 5,
    parameter TRANS_BURST_W       = 2,
    parameter TRANS_DATA_LEN_W    = 8,
    parameter TRANS_DATA_SIZE_W   = 3,
    parameter TRANS_WR_RESP_W     = 2,
    parameter TRANS_QOS_W         = 4,

    parameter MST_ID_W            = $clog2(MST_AMT),
    parameter SLV_ID_W            = $clog2(SLV_AMT),

    parameter OUTSTANDING_AMT     = 8,
    parameter FIFO_DEPTH          = 16,

    // Kích thước ID thực tế tại Slave (bao gồm ID của Master + ID transaction)
    parameter S_ID_W              = MST_ID_W + TRANS_MST_ID_W
)(
    input  wire                   ACLK_i,
    input  wire                   ARESETn_i,

    // Tín hiệu chọn cổng bên trong Interconnect
    input  wire [MST_ID_W-1:0]    top_mst_sel_i,
    input  wire [SLV_ID_W-1:0]    top_slv_sel_i,

    //======================================================================
    // SINGLE MASTER INTERFACE (Top Level) -> Nối vào m_* của Interconnect
    //======================================================================
    // AW Channel
    input  wire [TRANS_MST_ID_W-1:0]    top_m_AWID_i,
    input  wire [ADDR_WIDTH-1:0]        top_m_AWADDR_i,
    input  wire [TRANS_DATA_LEN_W-1:0]  top_m_AWLEN_i,
    input  wire [TRANS_DATA_SIZE_W-1:0] top_m_AWSIZE_i,
    input  wire [TRANS_BURST_W-1:0]     top_m_AWBURST_i,
    input  wire [TRANS_QOS_W-1:0]       top_m_AWQOS_i,
    input  wire                         top_m_AWVALID_i,
    output wire                         top_m_AWREADY_o,

    // W Channel
    input  wire [DATA_WIDTH-1:0]        top_m_WDATA_i,
    input  wire                         top_m_WLAST_i,
    input  wire                         top_m_WVALID_i,
    output wire                         top_m_WREADY_o,

    // B Channel
    output wire [TRANS_MST_ID_W-1:0]    top_m_BID_o,
    output wire [TRANS_WR_RESP_W-1:0]   top_m_BRESP_o,
    output wire                         top_m_BVALID_o,
    input  wire                         top_m_BREADY_i,

    // AR Channel
    input  wire [TRANS_MST_ID_W-1:0]    top_m_ARID_i,
    input  wire [ADDR_WIDTH-1:0]        top_m_ARADDR_i,
    input  wire [TRANS_DATA_LEN_W-1:0]  top_m_ARLEN_i,
    input  wire [TRANS_DATA_SIZE_W-1:0] top_m_ARSIZE_i,
    input  wire [TRANS_BURST_W-1:0]     top_m_ARBURST_i,
    input  wire [TRANS_QOS_W-1:0]       top_m_ARQOS_i,
    input  wire                         top_m_ARVALID_i,
    output wire                         top_m_ARREADY_o,

    // R Channel
    output wire [TRANS_MST_ID_W-1:0]    top_m_RID_o,
    output wire [DATA_WIDTH-1:0]        top_m_RDATA_o,
    output wire [TRANS_WR_RESP_W-1:0]   top_m_RRESP_o,
    output wire                         top_m_RLAST_o,
    output wire                         top_m_RVALID_o,
    input  wire                         top_m_RREADY_i,

    //======================================================================
    // SINGLE SLAVE INTERFACE (Top Level) -> Nối vào s_* của Interconnect
    //======================================================================
    // AW Channel
    output wire [S_ID_W-1:0]            top_s_AWID_o,
    output wire [ADDR_WIDTH-1:0]        top_s_AWADDR_o,
    output wire [TRANS_DATA_LEN_W-1:0]  top_s_AWLEN_o,
    output wire [TRANS_DATA_SIZE_W-1:0] top_s_AWSIZE_o,
    output wire [TRANS_BURST_W-1:0]     top_s_AWBURST_o,
    output wire [TRANS_QOS_W-1:0]       top_s_AWQOS_o,
    output wire                         top_s_AWVALID_o,
    input  wire                         top_s_AWREADY_i,

    // W Channel
    output wire [DATA_WIDTH-1:0]        top_s_WDATA_o,
    output wire                         top_s_WLAST_o,
    output wire                         top_s_WVALID_o,
    input  wire                         top_s_WREADY_i,

    // B Channel
    input  wire [S_ID_W-1:0]            top_s_BID_i,
    input  wire [TRANS_WR_RESP_W-1:0]   top_s_BRESP_i,
    input  wire                         top_s_BVALID_i,
    output wire                         top_s_BREADY_o,

    // AR Channel
    output wire [S_ID_W-1:0]            top_s_ARID_o,
    output wire [ADDR_WIDTH-1:0]        top_s_ARADDR_o,
    output wire [TRANS_DATA_LEN_W-1:0]  top_s_ARLEN_o,
    output wire [TRANS_DATA_SIZE_W-1:0] top_s_ARSIZE_o,
    output wire [TRANS_BURST_W-1:0]     top_s_ARBURST_o,
    output wire [TRANS_QOS_W-1:0]       top_s_ARQOS_o,
    output wire                         top_s_ARVALID_o,
    input  wire                         top_s_ARREADY_i,

    // R Channel
    input  wire [S_ID_W-1:0]            top_s_RID_i,
    input  wire [DATA_WIDTH-1:0]        top_s_RDATA_i,
    input  wire [TRANS_WR_RESP_W-1:0]   top_s_RRESP_i,
    input  wire                         top_s_RLAST_i,
    input  wire                         top_s_RVALID_i,
    output wire                         top_s_RREADY_o
);

    //======================================================================
    // INTERNAL WIRES (Kết nối trực tiếp vào axi4_interconnect)
    //======================================================================
    // Master side wires
    reg  [TRANS_MST_ID_W*MST_AMT-1:0]    intf_m_AWID_i;
    reg  [ADDR_WIDTH*MST_AMT-1:0]        intf_m_AWADDR_i;
    reg  [TRANS_DATA_LEN_W*MST_AMT-1:0]  intf_m_AWLEN_i;
    reg  [TRANS_DATA_SIZE_W*MST_AMT-1:0] intf_m_AWSIZE_i;
    reg  [TRANS_BURST_W*MST_AMT-1:0]     intf_m_AWBURST_i;
    reg  [TRANS_QOS_W*MST_AMT-1:0]       intf_m_AWQOS_i;
    reg  [MST_AMT-1:0]                   intf_m_AWVALID_i;
    wire [MST_AMT-1:0]                   intf_m_AWREADY_o;

    reg  [DATA_WIDTH*MST_AMT-1:0]        intf_m_WDATA_i;
    reg  [MST_AMT-1:0]                   intf_m_WLAST_i;
    reg  [MST_AMT-1:0]                   intf_m_WVALID_i;
    wire [MST_AMT-1:0]                   intf_m_WREADY_o;

    wire [TRANS_MST_ID_W*MST_AMT-1:0]    intf_m_BID_o;
    wire [TRANS_WR_RESP_W*MST_AMT-1:0]   intf_m_BRESP_o;
    wire [MST_AMT-1:0]                   intf_m_BVALID_o;
    reg  [MST_AMT-1:0]                   intf_m_BREADY_i;

    reg  [TRANS_MST_ID_W*MST_AMT-1:0]    intf_m_ARID_i;
    reg  [ADDR_WIDTH*MST_AMT-1:0]        intf_m_ARADDR_i;
    reg  [TRANS_DATA_LEN_W*MST_AMT-1:0]  intf_m_ARLEN_i;
    reg  [TRANS_DATA_SIZE_W*MST_AMT-1:0] intf_m_ARSIZE_i;
    reg  [TRANS_BURST_W*MST_AMT-1:0]     intf_m_ARBURST_i;
    reg  [TRANS_QOS_W*MST_AMT-1:0]       intf_m_ARQOS_i;
    reg  [MST_AMT-1:0]                   intf_m_ARVALID_i;
    wire [MST_AMT-1:0]                   intf_m_ARREADY_o;

    wire [TRANS_MST_ID_W*MST_AMT-1:0]    intf_m_RID_o;
    wire [DATA_WIDTH*MST_AMT-1:0]        intf_m_RDATA_o;
    wire [TRANS_WR_RESP_W*MST_AMT-1:0]   intf_m_RRESP_o;
    wire [MST_AMT-1:0]                   intf_m_RLAST_o;
    wire [MST_AMT-1:0]                   intf_m_RVALID_o;
    reg  [MST_AMT-1:0]                   intf_m_RREADY_i;

    // Slave side wires
    wire [S_ID_W*SLV_AMT-1:0]            intf_s_AWID_o;
    wire [ADDR_WIDTH*SLV_AMT-1:0]        intf_s_AWADDR_o;
    wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]  intf_s_AWLEN_o;
    wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0] intf_s_AWSIZE_o;
    wire [TRANS_BURST_W*SLV_AMT-1:0]     intf_s_AWBURST_o;
    wire [TRANS_QOS_W*SLV_AMT-1:0]       intf_s_AWQOS_o;
    wire [SLV_AMT-1:0]                   intf_s_AWVALID_o;
    reg  [SLV_AMT-1:0]                   intf_s_AWREADY_i;

    wire [DATA_WIDTH*SLV_AMT-1:0]        intf_s_WDATA_o;
    wire [SLV_AMT-1:0]                   intf_s_WLAST_o;
    wire [SLV_AMT-1:0]                   intf_s_WVALID_o;
    reg  [SLV_AMT-1:0]                   intf_s_WREADY_i;

    reg  [S_ID_W*SLV_AMT-1:0]            intf_s_BID_i;
    reg  [TRANS_WR_RESP_W*SLV_AMT-1:0]   intf_s_BRESP_i;
    reg  [SLV_AMT-1:0]                   intf_s_BVALID_i;
    wire [SLV_AMT-1:0]                   intf_s_BREADY_o;

    wire [S_ID_W*SLV_AMT-1:0]            intf_s_ARID_o;
    wire [ADDR_WIDTH*SLV_AMT-1:0]        intf_s_ARADDR_o;
    wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]  intf_s_ARLEN_o;
    wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0] intf_s_ARSIZE_o;
    wire [TRANS_BURST_W*SLV_AMT-1:0]     intf_s_ARBURST_o;
    wire [TRANS_QOS_W*SLV_AMT-1:0]       intf_s_ARQOS_o;
    wire [SLV_AMT-1:0]                   intf_s_ARVALID_o;
    reg  [SLV_AMT-1:0]                   intf_s_ARREADY_i;

    reg  [S_ID_W*SLV_AMT-1:0]            intf_s_RID_i;
    reg  [DATA_WIDTH*SLV_AMT-1:0]        intf_s_RDATA_i;
    reg  [TRANS_WR_RESP_W*SLV_AMT-1:0]   intf_s_RRESP_i;
    reg  [SLV_AMT-1:0]                   intf_s_RLAST_i;
    reg  [SLV_AMT-1:0]                   intf_s_RVALID_i;
    wire [SLV_AMT-1:0]                   intf_s_RREADY_o;

    //======================================================================
    // MUX / DEMUX LOGIC CHO MASTER INTERFACE
    //======================================================================
    integer i;
    always @(*) begin
        for (i = 0; i < MST_AMT; i = i + 1) begin
            if (i == top_mst_sel_i) begin
                // Nếu được chọn, cấp dữ liệu từ Top Port
                intf_m_AWID_i   [i*TRANS_MST_ID_W    +: TRANS_MST_ID_W]    = top_m_AWID_i;
                intf_m_AWADDR_i [i*ADDR_WIDTH        +: ADDR_WIDTH]        = top_m_AWADDR_i;
                intf_m_AWLEN_i  [i*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W]  = top_m_AWLEN_i;
                intf_m_AWSIZE_i [i*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W] = top_m_AWSIZE_i;
                intf_m_AWBURST_i[i*TRANS_BURST_W     +: TRANS_BURST_W]     = top_m_AWBURST_i;
                intf_m_AWQOS_i  [i*TRANS_QOS_W       +: TRANS_QOS_W]       = top_m_AWQOS_i;
                intf_m_AWVALID_i[i]                                        = top_m_AWVALID_i;
                
                intf_m_WDATA_i  [i*DATA_WIDTH        +: DATA_WIDTH]        = top_m_WDATA_i;
                intf_m_WLAST_i  [i]                                        = top_m_WLAST_i;
                intf_m_WVALID_i [i]                                        = top_m_WVALID_i;
                
                intf_m_BREADY_i [i]                                        = top_m_BREADY_i;
                
                intf_m_ARID_i   [i*TRANS_MST_ID_W    +: TRANS_MST_ID_W]    = top_m_ARID_i;
                intf_m_ARADDR_i [i*ADDR_WIDTH        +: ADDR_WIDTH]        = top_m_ARADDR_i;
                intf_m_ARLEN_i  [i*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W]  = top_m_ARLEN_i;
                intf_m_ARSIZE_i [i*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W] = top_m_ARSIZE_i;
                intf_m_ARBURST_i[i*TRANS_BURST_W     +: TRANS_BURST_W]     = top_m_ARBURST_i;
                intf_m_ARQOS_i  [i*TRANS_QOS_W       +: TRANS_QOS_W]       = top_m_ARQOS_i;
                intf_m_ARVALID_i[i]                                        = top_m_ARVALID_i;
                
                intf_m_RREADY_i [i]                                        = top_m_RREADY_i;
            end else begin
                // Kênh không được chọn, dìm Valid về 0 để Interconnect không hiểu nhầm
                intf_m_AWID_i   [i*TRANS_MST_ID_W    +: TRANS_MST_ID_W]    = 0;
                intf_m_AWADDR_i [i*ADDR_WIDTH        +: ADDR_WIDTH]        = 0;
                intf_m_AWLEN_i  [i*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W]  = 0;
                intf_m_AWSIZE_i [i*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W] = 0;
                intf_m_AWBURST_i[i*TRANS_BURST_W     +: TRANS_BURST_W]     = 0;
                intf_m_AWQOS_i  [i*TRANS_QOS_W       +: TRANS_QOS_W]       = 0;
                intf_m_AWVALID_i[i]                                        = 1'b0;
                
                intf_m_WDATA_i  [i*DATA_WIDTH        +: DATA_WIDTH]        = 0;
                intf_m_WLAST_i  [i]                                        = 1'b0;
                intf_m_WVALID_i [i]                                        = 1'b0;
                
                intf_m_BREADY_i [i]                                        = 1'b0;
                
                intf_m_ARID_i   [i*TRANS_MST_ID_W    +: TRANS_MST_ID_W]    = 0;
                intf_m_ARADDR_i [i*ADDR_WIDTH        +: ADDR_WIDTH]        = 0;
                intf_m_ARLEN_i  [i*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W]  = 0;
                intf_m_ARSIZE_i [i*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W] = 0;
                intf_m_ARBURST_i[i*TRANS_BURST_W     +: TRANS_BURST_W]     = 0;
                intf_m_ARQOS_i  [i*TRANS_QOS_W       +: TRANS_QOS_W]       = 0;
                intf_m_ARVALID_i[i]                                        = 1'b0;
                
                intf_m_RREADY_i [i]                                        = 1'b0;
            end
        end
    end

    // Đưa kết quả từ kênh Master được chọn ra Top Port
    assign top_m_AWREADY_o = intf_m_AWREADY_o[top_mst_sel_i];
    assign top_m_WREADY_o  = intf_m_WREADY_o [top_mst_sel_i];
    
    assign top_m_BID_o     = intf_m_BID_o    [top_mst_sel_i*TRANS_MST_ID_W  +: TRANS_MST_ID_W];
    assign top_m_BRESP_o   = intf_m_BRESP_o  [top_mst_sel_i*TRANS_WR_RESP_W +: TRANS_WR_RESP_W];
    assign top_m_BVALID_o  = intf_m_BVALID_o [top_mst_sel_i];
    
    assign top_m_ARREADY_o = intf_m_ARREADY_o[top_mst_sel_i];
    
    assign top_m_RID_o     = intf_m_RID_o    [top_mst_sel_i*TRANS_MST_ID_W  +: TRANS_MST_ID_W];
    assign top_m_RDATA_o   = intf_m_RDATA_o  [top_mst_sel_i*DATA_WIDTH      +: DATA_WIDTH];
    assign top_m_RRESP_o   = intf_m_RRESP_o  [top_mst_sel_i*TRANS_WR_RESP_W +: TRANS_WR_RESP_W];
    assign top_m_RLAST_o   = intf_m_RLAST_o  [top_mst_sel_i];
    assign top_m_RVALID_o  = intf_m_RVALID_o [top_mst_sel_i];


    //======================================================================
    // MUX / DEMUX LOGIC CHO SLAVE INTERFACE
    //======================================================================
    integer j;
    always @(*) begin
        for (j = 0; j < SLV_AMT; j = j + 1) begin
            if (j == top_slv_sel_i) begin
                // Input từ Top Slave đưa vào Interconnect
                intf_s_AWREADY_i[j]                                     = top_s_AWREADY_i;
                intf_s_WREADY_i [j]                                     = top_s_WREADY_i;
                
                intf_s_BID_i    [j*S_ID_W          +: S_ID_W]           = top_s_BID_i;
                intf_s_BRESP_i  [j*TRANS_WR_RESP_W +: TRANS_WR_RESP_W]  = top_s_BRESP_i;
                intf_s_BVALID_i [j]                                     = top_s_BVALID_i;
                
                intf_s_ARREADY_i[j]                                     = top_s_ARREADY_i;
                
                intf_s_RID_i    [j*S_ID_W          +: S_ID_W]           = top_s_RID_i;
                intf_s_RDATA_i  [j*DATA_WIDTH      +: DATA_WIDTH]       = top_s_RDATA_i;
                intf_s_RRESP_i  [j*TRANS_WR_RESP_W +: TRANS_WR_RESP_W]  = top_s_RRESP_i;
                intf_s_RLAST_i  [j]                                     = top_s_RLAST_i;
                intf_s_RVALID_i [j]                                     = top_s_RVALID_i;
            end else begin
                // Cổng không được chọn, dìm READY/VALID về 0 
                intf_s_AWREADY_i[j]                                     = 1'b0;
                intf_s_WREADY_i [j]                                     = 1'b0;
                
                intf_s_BID_i    [j*S_ID_W          +: S_ID_W]           = 0;
                intf_s_BRESP_i  [j*TRANS_WR_RESP_W +: TRANS_WR_RESP_W]  = 0;
                intf_s_BVALID_i [j]                                     = 1'b0;
                
                intf_s_ARREADY_i[j]                                     = 1'b0;
                
                intf_s_RID_i    [j*S_ID_W          +: S_ID_W]           = 0;
                intf_s_RDATA_i  [j*DATA_WIDTH      +: DATA_WIDTH]       = 0;
                intf_s_RRESP_i  [j*TRANS_WR_RESP_W +: TRANS_WR_RESP_W]  = 0;
                intf_s_RLAST_i  [j]                                     = 1'b0;
                intf_s_RVALID_i [j]                                     = 1'b0;
            end
        end
    end

    // Đưa request từ Interconnect ra Top Slave
    assign top_s_AWID_o    = intf_s_AWID_o   [top_slv_sel_i*S_ID_W            +: S_ID_W];
    assign top_s_AWADDR_o  = intf_s_AWADDR_o [top_slv_sel_i*ADDR_WIDTH        +: ADDR_WIDTH];
    assign top_s_AWLEN_o   = intf_s_AWLEN_o  [top_slv_sel_i*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W];
    assign top_s_AWSIZE_o  = intf_s_AWSIZE_o [top_slv_sel_i*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W];
    assign top_s_AWBURST_o = intf_s_AWBURST_o[top_slv_sel_i*TRANS_BURST_W     +: TRANS_BURST_W];
    assign top_s_AWQOS_o   = intf_s_AWQOS_o  [top_slv_sel_i*TRANS_QOS_W       +: TRANS_QOS_W];
    assign top_s_AWVALID_o = intf_s_AWVALID_o[top_slv_sel_i];
    
    assign top_s_WDATA_o   = intf_s_WDATA_o  [top_slv_sel_i*DATA_WIDTH        +: DATA_WIDTH];
    assign top_s_WLAST_o   = intf_s_WLAST_o  [top_slv_sel_i];
    assign top_s_WVALID_o  = intf_s_WVALID_o [top_slv_sel_i];
    
    assign top_s_BREADY_o  = intf_s_BREADY_o [top_slv_sel_i];
    
    assign top_s_ARID_o    = intf_s_ARID_o   [top_slv_sel_i*S_ID_W            +: S_ID_W];
    assign top_s_ARADDR_o  = intf_s_ARADDR_o [top_slv_sel_i*ADDR_WIDTH        +: ADDR_WIDTH];
    assign top_s_ARLEN_o   = intf_s_ARLEN_o  [top_slv_sel_i*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W];
    assign top_s_ARSIZE_o  = intf_s_ARSIZE_o [top_slv_sel_i*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W];
    assign top_s_ARBURST_o = intf_s_ARBURST_o[top_slv_sel_i*TRANS_BURST_W     +: TRANS_BURST_W];
    assign top_s_ARQOS_o   = intf_s_ARQOS_o  [top_slv_sel_i*TRANS_QOS_W       +: TRANS_QOS_W];
    assign top_s_ARVALID_o = intf_s_ARVALID_o[top_slv_sel_i];
    
    assign top_s_RREADY_o  = intf_s_RREADY_o [top_slv_sel_i];

    //======================================================================
    // KHỞI TẠO INSTANCE AXI4 INTERCONNECT BÊN TRONG
    //======================================================================
    axi4_interconnect #(
        .MST_AMT             (MST_AMT),
        .SLV_AMT             (SLV_AMT),
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .TRANS_MST_ID_W      (TRANS_MST_ID_W),
        .TRANS_BURST_W       (TRANS_BURST_W),
        .TRANS_DATA_LEN_W    (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W   (TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W     (TRANS_WR_RESP_W),
        .TRANS_QOS_W         (TRANS_QOS_W),
        .MST_ID_W            (MST_ID_W),
        .SLV_ID_W            (SLV_ID_W),
        .OUTSTANDING_AMT     (OUTSTANDING_AMT),
        .FIFO_DEPTH          (FIFO_DEPTH)
    ) u_axi4_interconnect (
        .ACLK_i              (ACLK_i),
        .ARESETn_i           (ARESETn_i),
        
        // Master Interface (Tới m_*)
        .m_AWID_i            (intf_m_AWID_i),
        .m_AWADDR_i          (intf_m_AWADDR_i),
        .m_AWLEN_i           (intf_m_AWLEN_i),
        .m_AWSIZE_i          (intf_m_AWSIZE_i),
        .m_AWBURST_i         (intf_m_AWBURST_i),
        .m_AWQOS_i           (intf_m_AWQOS_i),
        .m_AWVALID_i         (intf_m_AWVALID_i),
        .m_AWREADY_o         (intf_m_AWREADY_o),
        
        .m_WDATA_i           (intf_m_WDATA_i),
        .m_WLAST_i           (intf_m_WLAST_i),
        .m_WVALID_i          (intf_m_WVALID_i),
        .m_WREADY_o          (intf_m_WREADY_o),
        
        .m_BID_o             (intf_m_BID_o),
        .m_BRESP_o           (intf_m_BRESP_o),
        .m_BVALID_o          (intf_m_BVALID_o),
        .m_BREADY_i          (intf_m_BREADY_i),
        
        .m_ARID_i            (intf_m_ARID_i),
        .m_ARADDR_i          (intf_m_ARADDR_i),
        .m_ARLEN_i           (intf_m_ARLEN_i),
        .m_ARSIZE_i          (intf_m_ARSIZE_i),
        .m_ARBURST_i         (intf_m_ARBURST_i),
        .m_ARQOS_i           (intf_m_ARQOS_i),
        .m_ARVALID_i         (intf_m_ARVALID_i),
        .m_ARREADY_o         (intf_m_ARREADY_o),
        
        .m_RID_o             (intf_m_RID_o),
        .m_RDATA_o           (intf_m_RDATA_o),
        .m_RRESP_o           (intf_m_RRESP_o),
        .m_RLAST_o           (intf_m_RLAST_o),
        .m_RVALID_o          (intf_m_RVALID_o),
        .m_RREADY_i          (intf_m_RREADY_i),
        
        // Slave Interface (Tới s_*)
        .s_AWID_o            (intf_s_AWID_o),
        .s_AWADDR_o          (intf_s_AWADDR_o),
        .s_AWLEN_o           (intf_s_AWLEN_o),
        .s_AWSIZE_o          (intf_s_AWSIZE_o),
        .s_AWBURST_o         (intf_s_AWBURST_o),
        .s_AWQOS_o           (intf_s_AWQOS_o),
        .s_AWVALID_o         (intf_s_AWVALID_o),
        .s_AWREADY_i         (intf_s_AWREADY_i),
        
        .s_WDATA_o           (intf_s_WDATA_o),
        .s_WLAST_o           (intf_s_WLAST_o),
        .s_WVALID_o          (intf_s_WVALID_o),
        .s_WREADY_i          (intf_s_WREADY_i),
        
        .s_BID_i             (intf_s_BID_i),
        .s_BRESP_i           (intf_s_BRESP_i),
        .s_BVALID_i          (intf_s_BVALID_i),
        .s_BREADY_o          (intf_s_BREADY_o),
        
        .s_ARID_o            (intf_s_ARID_o),
        .s_ARADDR_o          (intf_s_ARADDR_o),
        .s_ARLEN_o           (intf_s_ARLEN_o),
        .s_ARSIZE_o          (intf_s_ARSIZE_o),
        .s_ARBURST_o         (intf_s_ARBURST_o),
        .s_ARQOS_o           (intf_s_ARQOS_o),
        .s_ARVALID_o         (intf_s_ARVALID_o),
        .s_ARREADY_i         (intf_s_ARREADY_i),
        
        .s_RID_i             (intf_s_RID_i),
        .s_RDATA_i           (intf_s_RDATA_i),
        .s_RRESP_i           (intf_s_RRESP_i),
        .s_RLAST_i           (intf_s_RLAST_i),
        .s_RVALID_i          (intf_s_RVALID_i),
        .s_RREADY_o          (intf_s_RREADY_o)
    );

endmodule