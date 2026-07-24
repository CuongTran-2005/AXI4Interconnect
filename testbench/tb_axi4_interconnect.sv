`timescale 1ns/1ps
module axi_interconnect_tb ();

// ==========================================
// SYSTEM PARAMETERS 
// ==========================================
parameter SYSTEM_CLOCK_PERIOD               = 20; // nanoseconds
// ==========================================
// INTERCONNECT PARAMETERS 
// ==========================================
parameter MASTER_NUM                        = 4;
parameter SLAVE_NUM                         = 4;
parameter TRANSACTION_MASTER_ID_WIDTH       = 4;
parameter TRANSACTION_SLAVE_ID_WIDTH        = 6;
parameter TRANSACTION_QOS_WIDTH             = 4;
parameter TRANSACTION_LEN_WIDTH             = 8;
parameter TRANSACTION_SIZE_WIDTH            = 3;
parameter TRANSACTION_BURST_WIDTH           = 2;
parameter TRANSACTION_ADDR_WIDTH            = 32;
parameter TRANSACTION_DATA_WIDTH            = 32;
parameter TRANSACTION_RESP_WIDTH            = 2;
parameter MAX_OUTSTANDING_TRANSACTION       = 8;
parameter INTERCONNECT_FIFO_DEPTH           = 16;

// Global Signals
reg ACLK_i;
reg ARESETn_i;

// ==========================================
// INTERCONNECT INPUTS DECLARATION (devices' outputs -> interconnect's inputs)
// ==========================================
// Master Interface Inputs (m_..._i)
// ar 
wire [MASTER_NUM-1:0]                               m_ARVALID_i;
wire [TRANSACTION_MASTER_ID_WIDTH*MASTER_NUM-1:0]   m_ARID_i;
wire [TRANSACTION_ADDR_WIDTH*MASTER_NUM-1:0]        m_ARADDR_i;
wire [TRANSACTION_BURST_WIDTH*MASTER_NUM-1:0]       m_ARBURST_i;
wire [TRANSACTION_LEN_WIDTH*MASTER_NUM-1:0]         m_ARLEN_i;
wire [TRANSACTION_SIZE_WIDTH*MASTER_NUM-1:0]        m_ARSIZE_i;
wire [TRANSACTION_QOS_WIDTH*MASTER_NUM-1:0]         m_ARQOS_i;
// aw
wire [MASTER_NUM-1:0]                               m_AWVALID_i;
wire [TRANSACTION_MASTER_ID_WIDTH*MASTER_NUM-1:0]   m_AWID_i;
wire [TRANSACTION_ADDR_WIDTH*MASTER_NUM-1:0]        m_AWADDR_i;
wire [TRANSACTION_BURST_WIDTH*MASTER_NUM-1:0]       m_AWBURST_i;
wire [TRANSACTION_LEN_WIDTH*MASTER_NUM-1:0]         m_AWLEN_i;
wire [TRANSACTION_SIZE_WIDTH*MASTER_NUM-1:0]        m_AWSIZE_i;
wire [TRANSACTION_QOS_WIDTH*MASTER_NUM-1:0]         m_AWQOS_i;
// b
wire [MASTER_NUM-1:0]                               m_BREADY_i;
wire [MASTER_NUM-1:0]                               m_RREADY_i;
// r
wire [MASTER_NUM-1:0]                               m_WLAST_i;
wire [MASTER_NUM-1:0]                               m_WVALID_i;
wire [TRANSACTION_DATA_WIDTH*MASTER_NUM-1:0]        m_WDATA_i;

// Slave Interface Inputs (s_..._i)
// aw
wire [SLAVE_NUM-1:0]                                s_AWREADY_i;
// ar
wire [SLAVE_NUM-1:0]                                s_ARREADY_i;
// w
wire [SLAVE_NUM-1:0]                                s_WREADY_i;
// b
wire [TRANSACTION_SLAVE_ID_WIDTH*SLAVE_NUM-1:0]     s_BID_i;
wire [TRANSACTION_RESP_WIDTH*SLAVE_NUM-1:0]         s_BRESP_i;
wire [SLAVE_NUM-1:0]                                s_BVALID_i;
// r
wire [TRANSACTION_SLAVE_ID_WIDTH*SLAVE_NUM-1:0]     s_RID_i;
wire [TRANSACTION_DATA_WIDTH*SLAVE_NUM-1:0]         s_RDATA_i;
wire [TRANSACTION_RESP_WIDTH*SLAVE_NUM-1:0]         s_RRESP_i;
wire [SLAVE_NUM-1:0]                                s_RLAST_i;
wire [SLAVE_NUM-1:0]                                s_RVALID_i;

// ==========================================
// INTERCONNECT OUTPUTS DECLARATION (interconnect's outputs -> devices' inputs)
// ==========================================
// Master Interface Outputs (m_..._o)
// aw
wire [MASTER_NUM-1:0]                                 m_AWREADY_o;
// ar
wire [MASTER_NUM-1:0]                                 m_ARREADY_o;
// w
wire [MASTER_NUM-1:0]                                 m_WREADY_o;
// b
wire [MASTER_NUM-1:0]                                 m_BVALID_o;
wire [TRANSACTION_MASTER_ID_WIDTH*MASTER_NUM-1:0]      m_BID_o;
wire [TRANSACTION_RESP_WIDTH*MASTER_NUM-1:0]          m_BRESP_o;
// r 
wire [MASTER_NUM-1:0]                                 m_RLAST_o;
wire [MASTER_NUM-1:0]                                 m_RVALID_o;
wire [TRANSACTION_MASTER_ID_WIDTH*MASTER_NUM-1:0]      m_RID_o;
wire [TRANSACTION_DATA_WIDTH*MASTER_NUM-1:0]          m_RDATA_o;
wire [TRANSACTION_RESP_WIDTH*MASTER_NUM-1:0]          m_RRESP_o;

// Slave Interface Outputs (s_..._o)
// aw
wire [TRANSACTION_SLAVE_ID_WIDTH*SLAVE_NUM-1:0]       s_AWID_o;
wire [TRANSACTION_ADDR_WIDTH*SLAVE_NUM-1:0]           s_AWADDR_o;
wire [TRANSACTION_BURST_WIDTH*SLAVE_NUM-1:0]          s_AWBURST_o;
wire [TRANSACTION_LEN_WIDTH*SLAVE_NUM-1:0]            s_AWLEN_o;
wire [TRANSACTION_SIZE_WIDTH*SLAVE_NUM-1:0]           s_AWSIZE_o;
wire [SLAVE_NUM-1:0]                                  s_AWVALID_o;
wire [TRANSACTION_QOS_WIDTH*SLAVE_NUM-1:0]            s_AWQOS_o;
// ar
wire [TRANSACTION_SLAVE_ID_WIDTH*SLAVE_NUM-1:0]       s_ARID_o;
wire [TRANSACTION_ADDR_WIDTH*SLAVE_NUM-1:0]           s_ARADDR_o;
wire [TRANSACTION_BURST_WIDTH*SLAVE_NUM-1:0]          s_ARBURST_o;
wire [TRANSACTION_LEN_WIDTH*SLAVE_NUM-1:0]            s_ARLEN_o;
wire [TRANSACTION_SIZE_WIDTH*SLAVE_NUM-1:0]           s_ARSIZE_o;
wire [SLAVE_NUM-1:0]                                  s_ARVALID_o;
wire [TRANSACTION_QOS_WIDTH*SLAVE_NUM-1:0]            s_ARQOS_o;
// w 
wire [TRANSACTION_DATA_WIDTH*SLAVE_NUM-1:0]           s_WDATA_o;
wire [SLAVE_NUM-1:0]                                  s_WLAST_o;
wire [SLAVE_NUM-1:0]                                  s_WVALID_o;
// b
wire [SLAVE_NUM-1:0]                                  s_BREADY_o;
// r
wire [SLAVE_NUM-1:0]                                  s_RREADY_o;


// ==========================================
//  MASTER DEVICE PARAMETERS 
// ==========================================
parameter MASTER_DEV_ID_WIDTH       = TRANSACTION_MASTER_ID_WIDTH;
parameter MASTER_DEV_ADDR_WIDTH     = TRANSACTION_ADDR_WIDTH;
parameter MASTER_DEV_DATA_WIDTH     = TRANSACTION_DATA_WIDTH;
parameter MASTER_DEV_BURST_WIDTH    = TRANSACTION_BURST_WIDTH;
parameter MASTER_DEV_LEN_WIDTH      = TRANSACTION_LEN_WIDTH;
parameter MASTER_DEV_SIZE_WIDTH     = TRANSACTION_SIZE_WIDTH;
parameter MASTER_DEV_RESP_WIDTH     = TRANSACTION_RESP_WIDTH;
parameter MASTER_DEV_QOS_WIDTH      = TRANSACTION_QOS_WIDTH;
parameter MASTER_DEV_RAM_SIZE       = 128;
parameter MASTER_DEV_RAM_ADDR_WIDTH = $clog2(MASTER_DEV_RAM_SIZE);

// ==========================================
//  MASTER DEVICE CONTROL SIGNALS 
// ==========================================
// master memory control signals
reg     [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     m_address_memory    [0:MASTER_NUM-1];
reg                                         m_READ_EN           [0:MASTER_NUM-1];
reg     [MASTER_DEV_DATA_WIDTH-1:0]         m_DATA_MEMORY_i     [0:MASTER_NUM-1];
reg                                         m_WRITE_EN          [0:MASTER_NUM-1];
wire    [MASTER_DEV_DATA_WIDTH-1:0]         m_DATA_MEMORY_o     [0:MASTER_NUM-1];
// master read transaction control signals 
reg                                         ReadTrans_EN_i      [0:MASTER_NUM-1];
reg     [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     r_set_addr_memory   [0:MASTER_NUM-1];
reg     [MASTER_DEV_ID_WIDTH-1:0]           set_ARID_i          [0:MASTER_NUM-1];
reg     [MASTER_DEV_ADDR_WIDTH-1:0]         set_ARADDR_i        [0:MASTER_NUM-1];
reg     [MASTER_DEV_BURST_WIDTH-1:0]        set_ARBURST_i       [0:MASTER_NUM-1];
reg     [MASTER_DEV_LEN_WIDTH-1:0]          set_ARLEN_i         [0:MASTER_NUM-1];
reg     [MASTER_DEV_SIZE_WIDTH-1:0]         set_ARSIZE_i        [0:MASTER_NUM-1];
reg     [MASTER_DEV_QOS_WIDTH-1:0]          set_ARQOS_i         [0:MASTER_NUM-1];
// master write transaction control signals
reg                                         WriteTrans_EN_i     [0:MASTER_NUM-1];
reg     [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     w_set_addr_memory   [0:MASTER_NUM-1];
reg     [MASTER_DEV_ID_WIDTH-1:0]           set_AWID_i          [0:MASTER_NUM-1];
reg     [MASTER_DEV_ADDR_WIDTH-1:0]         set_AWADDR_i        [0:MASTER_NUM-1];
reg     [MASTER_DEV_BURST_WIDTH-1:0]        set_AWBURST_i       [0:MASTER_NUM-1];
reg     [MASTER_DEV_LEN_WIDTH-1:0]          set_AWLEN_i         [0:MASTER_NUM-1];
reg     [MASTER_DEV_SIZE_WIDTH-1:0]         set_AWSIZE_i        [0:MASTER_NUM-1];
reg     [MASTER_DEV_QOS_WIDTH-1:0]          set_AWQOS_i         [0:MASTER_NUM-1];

// ==========================================
// UNFLATTENING INTERCONNECT SIGNALS (MASTER) 
// ==========================================
// master --> interconnect
wire                                        m_ARVALID           [0:MASTER_NUM-1];
wire    [MASTER_DEV_ID_WIDTH-1:0]           m_ARID              [0:MASTER_NUM-1];
wire    [MASTER_DEV_ADDR_WIDTH-1:0]         m_ARADDR            [0:MASTER_NUM-1];
wire    [MASTER_DEV_BURST_WIDTH-1:0]        m_ARBURST           [0:MASTER_NUM-1];
wire    [MASTER_DEV_LEN_WIDTH-1:0]          m_ARLEN             [0:MASTER_NUM-1];
wire    [MASTER_DEV_SIZE_WIDTH-1:0]         m_ARSIZE            [0:MASTER_NUM-1];
wire    [MASTER_DEV_QOS_WIDTH-1:0]          m_ARQOS             [0:MASTER_NUM-1];
wire                                        m_AWVALID           [0:MASTER_NUM-1];
wire    [MASTER_DEV_ID_WIDTH-1:0]           m_AWID              [0:MASTER_NUM-1];
wire    [MASTER_DEV_ADDR_WIDTH-1:0]         m_AWADDR            [0:MASTER_NUM-1];
wire    [MASTER_DEV_BURST_WIDTH-1:0]        m_AWBURST           [0:MASTER_NUM-1];
wire    [MASTER_DEV_LEN_WIDTH-1:0]          m_AWLEN             [0:MASTER_NUM-1];
wire    [MASTER_DEV_SIZE_WIDTH-1:0]         m_AWSIZE            [0:MASTER_NUM-1];
wire    [MASTER_DEV_QOS_WIDTH-1:0]          m_AWQOS             [0:MASTER_NUM-1];
wire                                        m_BREADY            [0:MASTER_NUM-1];
wire                                        m_RREADY            [0:MASTER_NUM-1];
wire                                        m_WLAST             [0:MASTER_NUM-1];
wire                                        m_WVALID            [0:MASTER_NUM-1];
wire    [MASTER_DEV_DATA_WIDTH-1:0]         m_WDATA             [0:MASTER_NUM-1];
genvar i;
generate 
    for (i = 0; i < MASTER_NUM; i = i + 1) begin : UNFLATTENING_MASTER_OUTPUT
        assign m_ARVALID_i  [i]                                                 = m_ARVALID [i];
        assign m_ARID_i     [i*MASTER_DEV_ID_WIDTH+:MASTER_DEV_ID_WIDTH]        = m_ARID    [i];
        assign m_ARADDR_i   [i*MASTER_DEV_ADDR_WIDTH+:MASTER_DEV_ADDR_WIDTH]    = m_ARADDR  [i];
        assign m_ARBURST_i  [i*MASTER_DEV_BURST_WIDTH+:MASTER_DEV_BURST_WIDTH]  = m_ARBURST [i];
        assign m_ARLEN_i    [i*MASTER_DEV_LEN_WIDTH+:MASTER_DEV_LEN_WIDTH]      = m_ARLEN   [i];
        assign m_ARSIZE_i   [i*MASTER_DEV_SIZE_WIDTH+:MASTER_DEV_SIZE_WIDTH]    = m_ARSIZE  [i];
        assign m_ARQOS_i    [i*MASTER_DEV_QOS_WIDTH+:MASTER_DEV_QOS_WIDTH]      = m_ARQOS   [i];
        assign m_AWVALID_i  [i]                                                 = m_AWVALID [i];
        assign m_AWID_i     [i*MASTER_DEV_ID_WIDTH+:MASTER_DEV_ID_WIDTH]        = m_AWID    [i];
        assign m_AWADDR_i   [i*MASTER_DEV_ADDR_WIDTH+:MASTER_DEV_ADDR_WIDTH]    = m_AWADDR  [i];
        assign m_AWBURST_i  [i*MASTER_DEV_BURST_WIDTH+:MASTER_DEV_BURST_WIDTH]  = m_AWBURST [i];
        assign m_AWLEN_i    [i*MASTER_DEV_LEN_WIDTH+:MASTER_DEV_LEN_WIDTH]      = m_AWLEN   [i];
        assign m_AWSIZE_i   [i*MASTER_DEV_SIZE_WIDTH+:MASTER_DEV_SIZE_WIDTH]    = m_AWSIZE  [i];
        assign m_AWQOS_i    [i*MASTER_DEV_QOS_WIDTH+:MASTER_DEV_QOS_WIDTH]      = m_AWQOS   [i];
        assign m_BREADY_i   [i]                                                 = m_BREADY  [i];
        assign m_RREADY_i   [i]                                                 = m_RREADY  [i];
        assign m_WLAST_i    [i]                                                 = m_WLAST   [i];
        assign m_WVALID_i   [i]                                                 = m_WVALID  [i];
        assign m_WDATA_i    [i*MASTER_DEV_DATA_WIDTH+:MASTER_DEV_DATA_WIDTH]    = m_WDATA   [i];
    end
endgenerate
// master <-- interconnect
wire                                        m_AWREADY           [0:MASTER_NUM-1];                                       
wire                                        m_ARREADY           [0:MASTER_NUM-1];
wire                                        m_WREADY            [0:MASTER_NUM-1];
wire                                        m_BVALID            [0:MASTER_NUM-1];
wire    [MASTER_DEV_ID_WIDTH-1:0]           m_BID               [0:MASTER_NUM-1];
wire    [MASTER_DEV_RESP_WIDTH-1:0]         m_BRESP             [0:MASTER_NUM-1];
wire                                        m_RLAST             [0:MASTER_NUM-1];
wire                                        m_RVALID            [0:MASTER_NUM-1];
wire    [MASTER_DEV_ID_WIDTH-1:0]           m_RID               [0:MASTER_NUM-1];
wire    [MASTER_DEV_DATA_WIDTH-1:0]         m_RDATA             [0:MASTER_NUM-1];
wire    [MASTER_DEV_RESP_WIDTH-1:0]         m_RRESP             [0:MASTER_NUM-1];
generate
    for(i = 0;i < MASTER_NUM;i = i + 1) begin : UNFLATTENING_MASTER_INPUT
        assign m_AWREADY    [i] = m_AWREADY_o   [i];
        assign m_ARREADY    [i] = m_ARREADY_o   [i];
        assign m_WREADY     [i] = m_WREADY_o    [i];
        assign m_BVALID     [i] = m_BVALID_o    [i];
        assign m_BID        [i] = m_BID_o       [i*MASTER_DEV_ID_WIDTH+:MASTER_DEV_ID_WIDTH];
        assign m_BRESP      [i] = m_BRESP_o     [i*MASTER_DEV_RESP_WIDTH+:MASTER_DEV_RESP_WIDTH];
        assign m_RLAST      [i] = m_RLAST_o     [i];
        assign m_RVALID     [i] = m_RVALID_o    [i];
        assign m_RID        [i] = m_RID_o       [i*MASTER_DEV_ID_WIDTH+:MASTER_DEV_ID_WIDTH];
        assign m_RDATA      [i] = m_RDATA_o     [i*MASTER_DEV_DATA_WIDTH+:MASTER_DEV_DATA_WIDTH];
        assign m_RRESP      [i] = m_RRESP_o     [i*MASTER_DEV_RESP_WIDTH+:MASTER_DEV_RESP_WIDTH];
    end
endgenerate

// generate master
genvar master_gen_i;
generate 
    for (master_gen_i = 0; master_gen_i < MASTER_NUM; master_gen_i = master_gen_i + 1) begin : GEN_MASTER
        axi_master_if #(
            .ID_WIDTH(MASTER_DEV_ID_WIDTH), 
            .ADDR_WIDTH(MASTER_DEV_ADDR_WIDTH), 
            .DATA_WIDTH(MASTER_DEV_DATA_WIDTH), 
            .RAM_SIZE(MASTER_DEV_RAM_SIZE), 
            .RAM_ADDR_WIDTH(MASTER_DEV_RAM_ADDR_WIDTH)
        ) u_master_dev (
        // global signals
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),

        // memory control signals
        .m_address_memory(m_address_memory[master_gen_i]),
        .m_READ_EN(m_READ_EN[master_gen_i]),
        .m_WRITE_EN(m_WRITE_EN[master_gen_i]),
        .m_DATA_MEMORY_i(m_DATA_MEMORY_i[master_gen_i]),
        .m_DATA_MEMORY_o(m_DATA_MEMORY_o[master_gen_i]),

        // read transaction control signals
        .ReadTrans_EN_i(ReadTrans_EN_i[master_gen_i]),
        .r_set_addr_memory(r_set_addr_memory[master_gen_i]),
        .set_ARID_i(set_ARID_i[master_gen_i]),
        .set_ARADDR_i(set_ARADDR_i[master_gen_i]),
        .set_ARBURST_i(set_ARBURST_i[master_gen_i]),
        .set_ARLEN_i(set_ARLEN_i[master_gen_i]),
        .set_ARSIZE_i(set_ARSIZE_i[master_gen_i]),
        .set_ARQOS_i(set_ARQOS_i[master_gen_i]),

        // write transaction control signals
        .WriteTrans_EN_i(WriteTrans_EN_i[master_gen_i]),
        .w_set_addr_memory(w_set_addr_memory[master_gen_i]),
        .set_AWID_i(set_AWID_i[master_gen_i]),
        .set_AWADDR_i(set_AWADDR_i[master_gen_i]),
        .set_AWBURST_i(set_AWBURST_i[master_gen_i]),
        .set_AWLEN_i(set_AWLEN_i[master_gen_i]),
        .set_AWSIZE_i(set_AWSIZE_i[master_gen_i]),
        .set_AWQOS_i(set_AWQOS_i[master_gen_i]),
        
        // write channel
        .m_AWVALID_o(m_AWVALID[master_gen_i]),
        .m_AWID_o(m_AWID[master_gen_i]),
        .m_AWADDR_o(m_AWADDR[master_gen_i]),
        .m_AWBURST_o(m_AWBURST[master_gen_i]),
        .m_AWLEN_o(m_AWLEN[master_gen_i]),
        .m_AWSIZE_o(m_AWSIZE[master_gen_i]),
        .m_AWQOS_o(m_AWQOS[master_gen_i]),
        .m_AWREADY_i(m_AWREADY[master_gen_i]),
        .m_WVALID_o(m_WVALID[master_gen_i]),
        .m_WDATA_o(m_WDATA[master_gen_i]),
        .m_WLAST_o(m_WLAST[master_gen_i]),
        .m_WREADY_i(m_WREADY[master_gen_i]),
        .m_BVALID_i(m_BVALID[master_gen_i]),
        .m_BID_i(m_BID[master_gen_i]),
        .m_BRESP_i(m_BRESP[master_gen_i]),
        .m_BREADY_o(m_BREADY[master_gen_i]),
        // read channel
        .m_ARVALID_o(m_ARVALID[master_gen_i]),
        .m_ARID_o(m_ARID[master_gen_i]),
        .m_ARADDR_o(m_ARADDR[master_gen_i]),
        .m_ARBURST_o(m_ARBURST[master_gen_i]),
        .m_ARLEN_o(m_ARLEN[master_gen_i]),
        .m_ARSIZE_o(m_ARSIZE[master_gen_i]),
        .m_ARQOS_o(m_ARQOS[master_gen_i]),
        .m_ARREADY_i(m_ARREADY[master_gen_i]),
        .m_RVALID_i(m_RVALID[master_gen_i]),
        .m_RLAST_i(m_RLAST[master_gen_i]),
        .m_RID_i(m_RID[master_gen_i]),
        .m_RDATA_i(m_RDATA[master_gen_i]),
        .m_RRESP_i(m_RRESP[master_gen_i]),
        .m_RREADY_o(m_RREADY[master_gen_i])
        );
    end
endgenerate

// ==========================================
//  SLAVE DEVICE PARAMETERS 
// ==========================================
parameter SLAVE_DEV_ID_WIDTH       = TRANSACTION_SLAVE_ID_WIDTH;
parameter SLAVE_DEV_ADDR_WIDTH     = TRANSACTION_ADDR_WIDTH;
parameter SLAVE_DEV_DATA_WIDTH     = TRANSACTION_DATA_WIDTH;
parameter SLAVE_DEV_BURST_WIDTH    = TRANSACTION_BURST_WIDTH;
parameter SLAVE_DEV_LEN_WIDTH      = TRANSACTION_LEN_WIDTH;
parameter SLAVE_DEV_SIZE_WIDTH     = TRANSACTION_SIZE_WIDTH;
parameter SLAVE_DEV_RESP_WIDTH     = TRANSACTION_RESP_WIDTH;
parameter SLAVE_DEV_QOS_WIDTH      = TRANSACTION_QOS_WIDTH;
parameter SLAVE_DEV_RAM_SIZE       = 128;
parameter SLAVE_DEV_RAM_ADDR_WIDTH = $clog2(MASTER_DEV_RAM_SIZE);

// ==========================================
//  SLAVE DEVICE CONTROL SIGNALS 
// ==========================================
reg     [SLAVE_DEV_RAM_ADDR_WIDTH-1:0]      s_address_memory    [0:SLAVE_NUM-1];
reg                                         s_READ_EN           [0:SLAVE_NUM-1];
reg     [SLAVE_DEV_DATA_WIDTH-1:0]          s_DATA_MEMORY_i     [0:SLAVE_NUM-1];
reg                                         s_WRITE_EN          [0:SLAVE_NUM-1];
reg     [SLAVE_DEV_DATA_WIDTH-1:0]          s_DATA_MEMORY_o     [0:SLAVE_NUM-1];

// ==========================================
// UNFLATTENING INTERCONNECT SIGNALS (SLAVE) 
// ==========================================
// interconnect --> slave
wire    [SLAVE_DEV_ID_WIDTH-1:0]        s_AWID          [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_ADDR_WIDTH-1:0]      s_AWADDR        [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_BURST_WIDTH-1:0]     s_AWBURST       [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_LEN_WIDTH-1:0]       s_AWLEN         [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_SIZE_WIDTH-1:0]      s_AWSIZE        [0:SLAVE_NUM-1];
wire                                    s_AWVALID       [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_QOS_WIDTH-1:0]       s_AWQOS         [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_ID_WIDTH-1:0]        s_ARID          [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_ADDR_WIDTH-1:0]      s_ARADDR        [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_BURST_WIDTH-1:0]     s_ARBURST       [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_LEN_WIDTH-1:0]       s_ARLEN         [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_SIZE_WIDTH-1:0]      s_ARSIZE        [0:SLAVE_NUM-1];
wire                                    s_ARVALID       [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_QOS_WIDTH-1:0]       s_ARQOS         [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_DATA_WIDTH-1:0]      s_WDATA         [0:SLAVE_NUM-1];
wire                                    s_WLAST         [0:SLAVE_NUM-1];
wire                                    s_WVALID        [0:SLAVE_NUM-1];
wire                                    s_BREADY        [0:SLAVE_NUM-1];
wire                                    s_RREADY        [0:SLAVE_NUM-1];
generate 
    for(i = 0;i < SLAVE_NUM;i = i + 1) begin : UNFLATTENING_SLAVE_INPUT
        assign s_AWID       [i] =   s_AWID_o[i*SLAVE_DEV_ID_WIDTH+:SLAVE_DEV_ID_WIDTH];
        assign s_AWADDR     [i] =   s_AWADDR_o[i*SLAVE_DEV_ADDR_WIDTH+:SLAVE_DEV_ADDR_WIDTH];
        assign s_AWBURST    [i] =   s_AWBURST_o[i*SLAVE_DEV_BURST_WIDTH+:SLAVE_DEV_BURST_WIDTH];
        assign s_AWSIZE     [i] =   s_AWSIZE_o[i*SLAVE_DEV_SIZE_WIDTH+:SLAVE_DEV_SIZE_WIDTH];
        assign s_AWLEN      [i] =   s_AWLEN_o[i*SLAVE_DEV_LEN_WIDTH+:SLAVE_DEV_LEN_WIDTH];
        assign s_AWVALID    [i] =   s_AWVALID_o[i];
        assign s_AWQOS      [i] =   s_AWQOS_o[i*SLAVE_DEV_QOS_WIDTH+:SLAVE_DEV_QOS_WIDTH];
        assign s_ARID       [i] =   s_ARID_o[i*SLAVE_DEV_ID_WIDTH+:SLAVE_DEV_ID_WIDTH];
        assign s_ARADDR     [i] =   s_ARADDR_o[i*SLAVE_DEV_ADDR_WIDTH+:SLAVE_DEV_ADDR_WIDTH];
        assign s_ARBURST    [i] =   s_ARBURST_o[i*SLAVE_DEV_BURST_WIDTH+:SLAVE_DEV_BURST_WIDTH];
        assign s_ARSIZE     [i] =   s_ARSIZE_o[i*SLAVE_DEV_SIZE_WIDTH+:SLAVE_DEV_SIZE_WIDTH];
        assign s_ARLEN      [i] =   s_ARLEN_o[i*SLAVE_DEV_LEN_WIDTH+:SLAVE_DEV_LEN_WIDTH];
        assign s_ARVALID    [i] =   s_ARVALID_o[i];
        assign s_ARQOS      [i] =   s_ARQOS_o[i*SLAVE_DEV_QOS_WIDTH+:SLAVE_DEV_QOS_WIDTH];
        assign s_WDATA      [i] =   s_WDATA_o[i*SLAVE_DEV_DATA_WIDTH+:SLAVE_DEV_DATA_WIDTH];
        assign s_WLAST      [i] =   s_WLAST_o[i];
        assign s_WVALID     [i] =   s_WVALID_o[i];
        assign s_BREADY     [i] =   s_BREADY_o[i];
        assign s_RREADY     [i] =   s_RREADY_o[i];
    end
endgenerate

// interconnect <-- slave
wire                                s_AWREADY           [0:SLAVE_NUM-1];
wire                                s_ARREADY           [0:SLAVE_NUM-1];
wire                                s_WREADY            [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_ID_WIDTH-1:0]    s_BID               [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_RESP_WIDTH-1:0]  s_BRESP             [0:SLAVE_NUM-1];
wire                                s_BVALID            [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_ID_WIDTH-1:0]    s_RID               [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_DATA_WIDTH-1:0]  s_RDATA             [0:SLAVE_NUM-1];
wire    [SLAVE_DEV_RESP_WIDTH-1:0]  s_RRESP             [0:SLAVE_NUM-1];
wire                                s_RLAST             [0:SLAVE_NUM-1];
wire                                s_RVALID            [0:SLAVE_NUM-1];
generate
    for(i = 0;i < SLAVE_NUM;i = i + 1) begin : UNFLATTENING_SLAVE_OUTPUT
        assign s_AWREADY_i  [i]                                             =   s_AWREADY   [i];
        assign s_ARREADY_i  [i]                                             =   s_ARREADY   [i];
        assign s_WREADY_i   [i]                                             =   s_WREADY    [i];
        assign s_BID_i      [i*SLAVE_DEV_ID_WIDTH+:SLAVE_DEV_ID_WIDTH]      =   s_BID       [i];
        assign s_BRESP_i    [i*SLAVE_DEV_RESP_WIDTH+:SLAVE_DEV_RESP_WIDTH]  =   s_BRESP     [i];
        assign s_BVALID_i   [i]                                             =   s_BVALID    [i];
        assign s_RID_i      [i*SLAVE_DEV_ID_WIDTH+:SLAVE_DEV_ID_WIDTH]      =   s_RID       [i];
        assign s_RDATA_i    [i*SLAVE_DEV_DATA_WIDTH+:SLAVE_DEV_DATA_WIDTH]  =   s_RDATA     [i];
        assign s_RRESP_i    [i*SLAVE_DEV_RESP_WIDTH+:SLAVE_DEV_RESP_WIDTH]  =   s_RRESP     [i];
        assign s_RLAST_i    [i]                                             =   s_RLAST     [i];
        assign s_RVALID_i   [i]                                             =   s_RVALID    [i];
    end
endgenerate
// generate slaves
genvar slave_gen_i;
generate 
    for(slave_gen_i = 0; slave_gen_i < SLAVE_NUM; slave_gen_i = slave_gen_i + 1) begin : GEN_SLAVE
        axi_slave_if #(.ID_WIDTH(SLAVE_DEV_ID_WIDTH), .ADDR_WIDTH(SLAVE_DEV_ADDR_WIDTH), .DATA_WIDTH(SLAVE_DEV_DATA_WIDTH), .RAM_SIZE(SLAVE_DEV_RAM_SIZE), .RAM_ADDR_WIDTH(SLAVE_DEV_RAM_ADDR_WIDTH))
        u_slave_dev(
        // global signals
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        // control signals
        .s_address_memory(s_address_memory[slave_gen_i]),
        .s_READ_EN(s_READ_EN[slave_gen_i]),
        .s_DATA_MEMORY_i(s_DATA_MEMORY_i[slave_gen_i]),
        .s_WRITE_EN(s_WRITE_EN[slave_gen_i]),
        .s_DATA_MEMORY_o(s_DATA_MEMORY_o[slave_gen_i]),
        // write
        .s_AWVALID_i(s_AWVALID[slave_gen_i]),
        .s_AWID_i(s_AWID[slave_gen_i]),
        .s_AWADDR_i(s_AWADDR[slave_gen_i]),
        .s_AWLEN_i(s_AWLEN[slave_gen_i]),
        .s_AWBURST_i(s_AWBURST[slave_gen_i]),
        .s_AWSIZE_i(s_AWSIZE[slave_gen_i]),
        .s_AWQOS_i(s_AWQOS[slave_gen_i]),
        .s_AWREADY_o(s_AWREADY[slave_gen_i]),
        .s_WVALID_i(s_WVALID[slave_gen_i]),
        .s_WDATA_i(s_WDATA[slave_gen_i]),
        .s_WLAST_i(s_WLAST[slave_gen_i]),
        .s_WREADY_o(s_WREADY[slave_gen_i]),
        .s_BVALID_o(s_BVALID[slave_gen_i]),
        .s_BID_o(s_BID[slave_gen_i]),
        .s_BRESP_o(s_BRESP[slave_gen_i]),
        .s_BREADY_i(s_BREADY[slave_gen_i]),
        // read
        .s_ARVALID_i(s_ARVALID[slave_gen_i]),
        .s_ARID_i(s_ARID[slave_gen_i]),
        .s_ARADDR_i(s_ARADDR[slave_gen_i]),
        .s_ARLEN_i(s_ARLEN[slave_gen_i]),
        .s_ARBURST_i(s_ARBURST[slave_gen_i]),
        .s_ARSIZE_i(s_ARSIZE[slave_gen_i]),
        .s_ARQOS_i(s_ARQOS[slave_gen_i]),
        .s_ARREADY_o(s_ARREADY[slave_gen_i]),
        .s_RVALID_o(s_RVALID[slave_gen_i]),
        .s_RLAST_o(s_RLAST[slave_gen_i]),
        .s_RID_o(s_RID[slave_gen_i]),
        .s_RDATA_o(s_RDATA[slave_gen_i]),
        .s_RRESP_o(s_RRESP[slave_gen_i]),
        .s_RREADY_i(s_RREADY[slave_gen_i])
        );
    end
endgenerate
// ==========================================
//  INSTANTIATE INTERCONNECT 
// ==========================================
axi4_interconnect #(
    .MST_AMT(MASTER_NUM),
    .SLV_AMT(SLAVE_NUM),
    .DATA_WIDTH(TRANSACTION_DATA_WIDTH),
    .ADDR_WIDTH(TRANSACTION_ADDR_WIDTH),
    .TRANS_MST_ID_W(TRANSACTION_MASTER_ID_WIDTH),
    .TRANS_BURST_W(TRANSACTION_BURST_WIDTH),
    .TRANS_DATA_LEN_W(TRANSACTION_LEN_WIDTH),
    .TRANS_DATA_SIZE_W(TRANSACTION_SIZE_WIDTH),
    .TRANS_WR_RESP_W(TRANSACTION_RESP_WIDTH),
    .TRANS_QOS_W(TRANSACTION_QOS_WIDTH),
    .OUTSTANDING_AMT(MAX_OUTSTANDING_TRANSACTION),
    .FIFO_DEPTH(INTERCONNECT_FIFO_DEPTH)
)
interconnect (
    // global signals
    .ACLK_i(ACLK_i),
    .ARESETn_i(ARESETn_i),
    /* ---master--- */
    // aw channel
    .m_AWID_i(m_AWID_i),
    .m_AWADDR_i(m_AWADDR_i),
    .m_AWLEN_i(m_AWLEN_i),
    .m_AWSIZE_i(m_AWSIZE_i),
    .m_AWBURST_i(m_AWBURST_i),
    .m_AWQOS_i(m_AWQOS_i),
    .m_AWVALID_i(m_AWVALID_i),
    .m_AWREADY_o(m_AWREADY_o),
    // w channel
    .m_WDATA_i(m_WDATA_i),
    .m_WLAST_i(m_WLAST_i),
    .m_WVALID_i(m_WVALID_i),
    .m_WREADY_o(m_WREADY_o),
    // b channel
    .m_BID_o(m_BID_o),
    .m_BRESP_o(m_BRESP_o),
    .m_BVALID_o(m_BVALID_o),
    .m_BREADY_i(m_BREADY_i),
    // ar channel
    .m_ARID_i(m_ARID_i),
    .m_ARADDR_i(m_ARADDR_i),
    .m_ARLEN_i(m_ARLEN_i),
    .m_ARSIZE_i(m_ARSIZE_i),
    .m_ARBURST_i(m_ARBURST_i),
    .m_ARQOS_i(m_ARQOS_i),
    .m_ARVALID_i(m_ARVALID_i),
    .m_ARREADY_o(m_ARREADY_o),
    // r channel 
    .m_RID_o(m_RID_o),
    .m_RDATA_o(m_RDATA_o),
    .m_RRESP_o(m_RRESP_o),
    .m_RLAST_o(m_RLAST_o),
    .m_RVALID_o(m_RVALID_o),
    .m_RREADY_i(m_RREADY_i),
    /* ---slave--- */
    // aw channel
    .s_AWID_o(s_AWID_o),
    .s_AWADDR_o(s_AWADDR_o),
    .s_AWLEN_o(s_AWLEN_o),
    .s_AWSIZE_o(s_AWSIZE_o),
    .s_AWBURST_o(s_AWBURST_o),
    .s_AWQOS_o(s_AWQOS_o),
    .s_AWVALID_o(s_AWVALID_o),
    .s_AWREADY_i(s_AWREADY_i),
    // w channel
    .s_WDATA_o(s_WDATA_o),
    .s_WLAST_o(s_WLAST_o),
    .s_WVALID_o(s_WVALID_o),
    .s_WREADY_i(s_WREADY_i),
    // b channel
    .s_BID_i(s_BID_i),
    .s_BRESP_i(s_BRESP_i),
    .s_BVALID_i(s_BVALID_i),
    .s_BREADY_o(s_BREADY_o),
    // ar channel
    .s_ARID_o(s_ARID_o),
    .s_ARADDR_o(s_ARADDR_o),
    .s_ARLEN_o(s_ARLEN_o),
    .s_ARSIZE_o(s_ARSIZE_o),
    .s_ARBURST_o(s_ARBURST_o),
    .s_ARQOS_o(s_ARQOS_o),
    .s_ARVALID_o(s_ARVALID_o),
    .s_ARREADY_i(s_ARREADY_i),
    // r channel
    .s_RID_i(s_RID_i),
    .s_RDATA_i(s_RDATA_i),
    .s_RRESP_i(s_RRESP_i),
    .s_RLAST_i(s_RLAST_i),
    .s_RVALID_i(s_RVALID_i),
    .s_RREADY_o(s_RREADY_o)
);

task automatic masterReadTransaction (
    input integer                                       masterIndex,
    input           [TRANSACTION_MASTER_ID_WIDTH-1:0]   transID,
    input           [TRANSACTION_ADDR_WIDTH-1:0]        transAddr,
    input           [TRANSACTION_LEN_WIDTH-1:0]         transLen,
    input           [TRANSACTION_SIZE_WIDTH-1:0]        transSize,
    input           [TRANSACTION_BURST_WIDTH-1:0]       transBurst,
    input           [TRANSACTION_QOS_WIDTH-1:0]         transQoS,
    input           [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     memAddr
);
begin 
    @(negedge ACLK_i);
    set_ARID_i[masterIndex]         <= transID;
    set_ARADDR_i[masterIndex]       <= transAddr;
    set_ARLEN_i[masterIndex]        <= transLen;
    set_ARSIZE_i[masterIndex]       <= transSize;
    set_ARBURST_i[masterIndex]      <= transBurst;
    set_ARQOS_i[masterIndex]        <= transQoS;
    r_set_addr_memory[masterIndex]  <= memAddr;
    ReadTrans_EN_i[masterIndex]     <= 1'b1;
    @(posedge ACLK_i);
    $display("[TB] Master %0d setup a read transaction at %0d. ARID=%0h | ARADDR=%0h | ARLEN=%0h | ARSIZE=%0h | ARBURST=%0h | ARQOS=%0h | memAddr=%0h", masterIndex, $time, transID, transAddr, transLen, transSize, transBurst, transQoS, memAddr);
    @(negedge ACLK_i);
    ReadTrans_EN_i[masterIndex]     <= 1'b0;
    set_ARID_i[masterIndex]         <= {MASTER_DEV_ID_WIDTH{1'b0}};
    set_ARADDR_i[masterIndex]       <= {MASTER_DEV_ADDR_WIDTH{1'b0}};
    set_ARLEN_i[masterIndex]        <= {MASTER_DEV_LEN_WIDTH{1'b0}};
    set_ARSIZE_i[masterIndex]       <= {MASTER_DEV_SIZE_WIDTH{1'b0}};
    set_ARBURST_i[masterIndex]      <= {MASTER_DEV_BURST_WIDTH{1'b0}};
    set_ARQOS_i[masterIndex]        <= {MASTER_DEV_QOS_WIDTH{1'b0}};
    r_set_addr_memory[masterIndex]  <= {MASTER_DEV_RAM_ADDR_WIDTH{1'b0}};
end
endtask

task automatic masterWriteTransaction (
    input integer                                       masterIndex,
    input           [TRANSACTION_MASTER_ID_WIDTH-1:0]   transID,
    input           [TRANSACTION_ADDR_WIDTH-1:0]        transAddr,
    input           [TRANSACTION_LEN_WIDTH-1:0]         transLen,
    input           [TRANSACTION_SIZE_WIDTH-1:0]        transSize,
    input           [TRANSACTION_BURST_WIDTH-1:0]       transBurst,
    input           [TRANSACTION_QOS_WIDTH-1:0]         transQoS,
    input           [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     memAddr
);
begin 
    @(negedge ACLK_i);
    set_AWID_i[masterIndex]         <= transID;
    set_AWADDR_i[masterIndex]       <= transAddr;
    set_AWLEN_i[masterIndex]        <= transLen;
    set_AWSIZE_i[masterIndex]       <= transSize;
    set_AWBURST_i[masterIndex]      <= transBurst;
    set_AWQOS_i[masterIndex]        <= transQoS;
    w_set_addr_memory[masterIndex]  <= memAddr;
    WriteTrans_EN_i[masterIndex]    <= 1'b1;
    @(posedge ACLK_i);
    $display("[TB] Master %0d setup a write transaction at %0d. AWID=%0h | AWADDR=%0h | AWLEN=%0h | AWSIZE=%0h | AWBURST=%0h | AWQOS=%0h | memAddr=%0h", masterIndex, $time, transID, transAddr, transLen, transSize, transBurst, transQoS, memAddr);
    @(negedge ACLK_i);
    // reset
    WriteTrans_EN_i[masterIndex]    <= 1'b0;
    set_AWID_i[masterIndex]         <= {MASTER_DEV_ID_WIDTH{1'b0}};
    set_AWADDR_i[masterIndex]       <= {MASTER_DEV_ADDR_WIDTH{1'b0}};
    set_AWLEN_i[masterIndex]        <= {MASTER_DEV_LEN_WIDTH{1'b0}};
    set_AWSIZE_i[masterIndex]       <= {MASTER_DEV_SIZE_WIDTH{1'b0}};
    set_AWBURST_i[masterIndex]      <= {MASTER_DEV_BURST_WIDTH{1'b0}};
    set_AWQOS_i[masterIndex]        <= {MASTER_DEV_QOS_WIDTH{1'b0}};
    w_set_addr_memory[masterIndex]  <= {MASTER_DEV_RAM_ADDR_WIDTH{1'b0}};
end
endtask

task getMasterMemory(input integer i, input [MASTER_DEV_RAM_ADDR_WIDTH-1:0] addr, output [MASTER_DEV_DATA_WIDTH-1:0] readData);
    begin
        @(negedge ACLK_i);
        m_address_memory[i] <= addr;
        m_READ_EN[i]        <= 1'b1;
        @(negedge ACLK_i);
        m_address_memory[i] <= {MASTER_DEV_RAM_ADDR_WIDTH{1'b0}};
        m_READ_EN[i]        <= 1'b0;
        readData            <= m_DATA_MEMORY_o[i];
    end
endtask

task getSlaveMemory(input integer i, input [SLAVE_DEV_RAM_ADDR_WIDTH-1:0] addr, output [SLAVE_DEV_DATA_WIDTH-1:0] readData);
    begin
        @(negedge ACLK_i);
        s_address_memory[i] <= addr;
        s_READ_EN[i]        <= 1'b1;
        @(negedge ACLK_i);
        s_address_memory[i] <= {SLAVE_DEV_RAM_ADDR_WIDTH{1'b0}};
        s_READ_EN[i]        <= 1'b0;
        readData            <= s_DATA_MEMORY_o[i];
    end
endtask

task setMasterMemory(input integer i, input [MASTER_DEV_RAM_ADDR_WIDTH-1:0] addr, input [MASTER_DEV_DATA_WIDTH-1:0] writeData);
    begin
        @(negedge ACLK_i);
        m_address_memory[i] <= addr;
        m_WRITE_EN[i]       <= 1'b1;
        m_DATA_MEMORY_i[i]  <= writeData;
        @(negedge ACLK_i);
        m_address_memory[i] <= {MASTER_DEV_RAM_ADDR_WIDTH{1'b0}};
        m_WRITE_EN[i]       <= 1'b0;
    end
endtask

task setSlaveMemory(input integer i, input [SLAVE_DEV_RAM_ADDR_WIDTH-1:0] addr, input [SLAVE_DEV_DATA_WIDTH-1:0] writeData);
    begin
        @(negedge ACLK_i);
        s_address_memory[i] <= addr;
        s_WRITE_EN[i]       <= 1'b1;
        s_DATA_MEMORY_i[i]  <= writeData;
        @(negedge ACLK_i);
        s_address_memory[i] <= {MASTER_DEV_RAM_ADDR_WIDTH{1'b0}};
        s_WRITE_EN[i]       <= 1'b0;
    end
endtask

task masterReadMemory(
    input integer                                   masterIndex,
    input       [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     memAddr,
    input integer                                   count
);
    begin : read_mem
        integer i;
        integer j;
        reg [MASTER_DEV_DATA_WIDTH-1:0] readData;
        if (memAddr + count >= MASTER_DEV_RAM_SIZE) begin
            $display("[TB] Failed to read master's memory! Address exceeded RAM limits");
            disable read_mem;
        end
        $display("[TB] Read Master %0d memory begin at address %0h, byte count %0d", masterIndex, memAddr, count);
        for (i = 0;i < count;i = i + 4) begin : read_word
            for (j = i;(j < (i+4)) & (j < count); j = j + 1) begin : read_block_mem
                getMasterMemory(masterIndex, j, readData);
                $display("%0h", readData);
            end
        end
    end
endtask

task slaveReadMemory(
    input integer                                   slaveIndex,
    input       [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     memAddr,
    input integer                                   count
);
    begin : read_mem
        integer i;
        integer j;
        reg [SLAVE_DEV_DATA_WIDTH-1:0] readData;
        if (memAddr + count >= SLAVE_DEV_RAM_SIZE) begin
            $display("[TB] Failed to read slave's memory! Address exceeded RAM limits");
            disable read_mem;
        end
        $display("[TB] Read Slave %0d memory begin at address %0h, byte count %0d", slaveIndex, memAddr, count);
        for (i = 0;i < count;i = i + 4) begin : read_word
            for (j = i;(j < (i+4)) & (j < count); j = j + 1) begin : read_block_mem
                getSlaveMemory(slaveIndex, j, readData);
                $display("%0h", readData);
            end
        end
    end
endtask

task masterWriteMemory (
    input integer                                   masterIndex,
    input       [MASTER_DEV_RAM_ADDR_WIDTH-1:0]     memAddr,
    input       [MASTER_DEV_DATA_WIDTH-1:0]         writeData
);
    begin : write_mem
        $display("[TB] Write Master %0d memory, address 0x%0h, data 0x%0h", masterIndex, memAddr, writeData);
        setMasterMemory(masterIndex, memAddr, writeData);
    end
endtask

task slaveWriteMemory (
    input integer                                   slaveIndex,
    input       [SLAVE_DEV_RAM_ADDR_WIDTH-1:0]      memAddr,
    input       [SLAVE_DEV_DATA_WIDTH-1:0]          writeData
);

    begin : write_mem
        $display("[TB] Write Slave %0d memory, address 0x%0h, data 0x%0h", slaveIndex, memAddr, writeData);
        setSlaveMemory(slaveIndex, memAddr, writeData);
    end
endtask

task systemReset;
  begin
    ACLK_i      <= 1'b0;
    ARESETn_i   <= 1'b0;
  end
endtask

task delayNs(input real ns);
    begin : delay_ns
        #ns;  
    end
endtask

// clock generator
always begin : clk_gen
    delayNs(SYSTEM_CLOCK_PERIOD/2); ACLK_i <= ~ACLK_i;
end

// monitor
initial begin : monitor
    integer m, s;
    
    // Wait for the active-low reset to be released before logging
    @(posedge ARESETn_i);
    $display("=======================================================================");
    $display("[MONITOR] AXI4 Interconnect Traffic Monitor Started at time %0t", $time);
    $display("=======================================================================");

    forever begin
        @(posedge ACLK_i);
        
        // Only monitor traffic when system is operating out of reset
        if (ARESETn_i === 1'b1) begin
            
            // ----------------------------------------------------------------
            // 1. MONITOR MASTER <-> INTERCONNECT TRAFFIC
            // ----------------------------------------------------------------
            for (m = 0; m < MASTER_NUM; m = m + 1) begin
                // Write Address Channel (AW)
                if (m_AWVALID[m] && m_AWREADY[m]) begin
                    $display("[time %0t] [MST %0d -> IC] [AW] AWID=0x%0h | AWADDR=0x%0h | AWLEN=%0d | AWSIZE=%0d | AWBURST=%0d | AWQOS=%0d",
                             $time, m, m_AWID[m], m_AWADDR[m], m_AWLEN[m], m_AWSIZE[m], m_AWBURST[m], m_AWQOS[m]);
                end
                
                // Write Data Channel (W)
                if (m_WVALID[m] && m_WREADY[m]) begin
                    $display("[time %0t] [MST %0d -> IC] [ W] WDATA=0x%0h | WLAST=%0b",
                             $time, m, m_WDATA[m], m_WLAST[m]);
                end
                
                // Write Response Channel (B)
                if (m_BVALID[m] && m_BREADY[m]) begin
                    $display("[time %0t] [IC -> MST %0d] [ B] BID=0x%0h  | BRESP=0x%0h",
                             $time, m, m_BID[m], m_BRESP[m]);
                end
                
                // Read Address Channel (AR)
                if (m_ARVALID[m] && m_ARREADY[m]) begin
                    $display("[time %0t] [MST %0d -> IC] [AR] ARID=0x%0h | ARADDR=0x%0h | ARLEN=%0d | ARSIZE=%0d | ARBURST=%0d | ARQOS=%0d",
                             $time, m, m_ARID[m], m_ARADDR[m], m_ARLEN[m], m_ARSIZE[m], m_ARBURST[m], m_ARQOS[m]);
                end
                
                // Read Data Channel (R)
                if (m_RVALID[m] && m_RREADY[m]) begin
                    $display("[time %0t] [IC -> MST %0d] [ R] RID=0x%0h  | RDATA=0x%0h | RRESP=0x%0h | RLAST=%0b",
                             $time, m, m_RID[m], m_RDATA[m], m_RRESP[m], m_RLAST[m]);
                end
            end

            // ----------------------------------------------------------------
            // 2. MONITOR INTERCONNECT <-> SLAVE TRAFFIC
            // ----------------------------------------------------------------
            for (s = 0; s < SLAVE_NUM; s = s + 1) begin
                // Write Address Channel (AW)
                if (s_AWVALID[s] && s_AWREADY[s]) begin
                    $display("[time %0t] [IC -> SLV %0d] [AW] AWID=0x%0h | AWADDR=0x%0h | AWLEN=%0d | AWSIZE=%0d | AWBURST=%0d | AWQOS=%0d",
                             $time, s, s_AWID[s], s_AWADDR[s], s_AWLEN[s], s_AWSIZE[s], s_AWBURST[s], s_AWQOS[s]);
                end
                
                // Write Data Channel (W)
                if (s_WVALID[s] && s_WREADY[s]) begin
                    $display("[time %0t] [IC -> SLV %0d] [ W] WDATA=0x%0h | WLAST=%0b",
                             $time, s, s_WDATA[s], s_WLAST[s]);
                end
                
                // Write Response Channel (B)
                if (s_BVALID[s] && s_BREADY[s]) begin
                    $display("[time %0t] [SLV %0d -> IC] [ B] BID=0x%0h  | BRESP=0x%0h",
                             $time, s, s_BID[s], s_BRESP[s]);
                end
                
                // Read Address Channel (AR)
                if (s_ARVALID[s] && s_ARREADY[s]) begin
                    $display("[time %0t] [IC -> SLV %0d] [AR] ARID=0x%0h | ARADDR=0x%0h | ARLEN=%0d | ARSIZE=%0d | ARBURST=%0d | ARQOS=%0d",
                             $time, s, s_ARID[s], s_ARADDR[s], s_ARLEN[s], s_ARSIZE[s], s_ARBURST[s], s_ARQOS[s]);
                end
                
                // Read Data Channel (R)
                if (s_RVALID[s] && s_RREADY[s]) begin
                    $display("[time %0t] [SLV %0d -> IC] [ R] RID=0x%0h  | RDATA=0x%0h | RRESP=0x%0h | RLAST=%0b",
                             $time, s, s_RID[s], s_RDATA[s], s_RRESP[s], s_RLAST[s]);
                end
            end

        end
    end
end

// watchdog timer
initial begin : watchdog
    #1000000;
    $display("TIMEOUT!. The simulation was forced to stop at %d", $time);
    $finish;
end

initial begin : main
    $dumpfile("dump.vcd");
    $dumpvars(0, axi_interconnect_tb);
    systemReset();
    delayNs(SYSTEM_CLOCK_PERIOD * 5);
    ARESETn_i <= 1'b1;
    delayNs(100);

    //TESTCASE 1: ISSUE ONE WRITE TRANSACTION AND ONE READ TRANSACTION 
    $display("TESTCASE 1: ONE WRITE TRANSACTION AND ONE READ TRANSACTION");
    // setup master 0 memory
    masterWriteMemory(1, 0, 32'hAABBCCDD);
    // issue write transaction (master[0] --> slave[0])
    masterWriteTransaction(.masterIndex(1), .transID(0), .transAddr({01, {30'd0}}), .transLen(0), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
    delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
    // issue read transaction (master[0] <-- slave[0])
    masterReadTransaction(.masterIndex(1), .transID(0), .transAddr({01, {30'd0}}), .transLen(0), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(4));

    delayNs(1000);
    /* TESTCASE 2: ISSUE TWO WRITE TRANSACTION AT THE SAME TIME */
    $display("TESTCASE 2: TWO WRITE TRANSACTION AT THE SAME TIME");
    masterWriteMemory(1, 0, 32'hAABBCCDD);
    masterWriteMemory(2, 0, 32'hCCDDEEFF);
    fork 
        begin
            // master[1] --> slave[1]
            masterWriteTransaction(.masterIndex(1), .transID(0), .transAddr({01, {30'd0}}), .transLen(0), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end
        begin 
            // master[2] --> slave[1]
            masterWriteTransaction(.masterIndex(2), .transID(0), .transAddr({01, {30'd4}}), .transLen(0), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end
    join
    delayNs(1000);

    /* TESTCASE 3: ISSUE TWO READ TRANSACTION AT THE SAME TIME */
    $display("TESTCASE 3: TWO READ TRANSACTION AT THE SAME TIME");
    fork 
        begin
            // master[1] --> slave[1]
            masterReadTransaction(.masterIndex(1), .transID(0), .transAddr({01, {30'd0}}), .transLen(0), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end
        begin 
            // master[2] --> slave[1]
            masterReadTransaction(.masterIndex(2), .transID(0), .transAddr({01, {30'd4}}), .transLen(0), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end
    join
    delayNs(1000);

    /* TESTCASE 4*/
    $display("TESTCASE 4: TWO WRITE TRANSACTION AT THE SAME TIME WITH DIFFERENT QOS");
    masterWriteMemory(2, 4, 32'h1111_1111);
    masterWriteMemory(2, 5, 32'h1111_2222);
    masterWriteMemory(2, 6, 32'h1111_3333);
    masterWriteMemory(2, 7, 32'h1111_4444);
    masterWriteMemory(3, 4, 32'h2222_1111);
    masterWriteMemory(3, 5, 32'h2222_2222);
    masterWriteMemory(3, 6, 32'h2222_3333);
    masterWriteMemory(3, 7, 32'h2222_4444);
    fork
        begin
            masterWriteTransaction(.masterIndex(2), .transID(0), .transAddr(32'h4000_0000), .transLen(3), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(4));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end
        begin 
            masterWriteTransaction(.masterIndex(3), .transID(1), .transAddr(32'h4000_0004), .transLen(3), .transSize(3'd2), .transBurst(2'd1), .transQoS(4), .memAddr(4));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end
    join
    delayNs(1000);

    /* TESTCASE 5 */
    $display("TESTCASE 5: TWO READ TRANSACTION AT THE SAME TIME WITH DIFFERENT QOS");
    slaveWriteMemory(0, 0, 32'haaaa_0001);
    slaveWriteMemory(0, 1, 32'haaaa_0002);
    slaveWriteMemory(0, 2, 32'haaaa_0003);
    slaveWriteMemory(0, 3, 32'haaaa_0004);
    slaveWriteMemory(0, 4, 32'haaaa_0005);
    slaveWriteMemory(0, 5, 32'haaaa_0006);
    slaveWriteMemory(0, 6, 32'haaaa_0007);
    slaveWriteMemory(0, 7, 32'haaaa_0008);

    slaveWriteMemory(1, 0, 32'hbbbb_0001);
    slaveWriteMemory(1, 1, 32'hbbbb_0002);
    slaveWriteMemory(1, 2, 32'hbbbb_0003);
    slaveWriteMemory(1, 3, 32'hbbbb_0004);
    slaveWriteMemory(1, 4, 32'hbbbb_0005);
    slaveWriteMemory(1, 5, 32'hbbbb_0006);
    slaveWriteMemory(1, 6, 32'hbbbb_0007);
    slaveWriteMemory(1, 7, 32'hbbbb_0008);

    slaveWriteMemory(2, 0, 32'hbbbb_0001);
    slaveWriteMemory(2, 1, 32'hbbbb_0002);
    slaveWriteMemory(2, 2, 32'hbbbb_0003);
    slaveWriteMemory(2, 3, 32'hbbbb_0004);
    slaveWriteMemory(2, 4, 32'hbbbb_0005);
    slaveWriteMemory(2, 5, 32'hbbbb_0006);
    slaveWriteMemory(2, 6, 32'hbbbb_0007);
    slaveWriteMemory(2, 7, 32'hbbbb_0008);

    slaveWriteMemory(3, 0, 32'hbbbb_0001);
    slaveWriteMemory(3, 1, 32'hbbbb_0002);
    slaveWriteMemory(3, 2, 32'hbbbb_0003);
    slaveWriteMemory(3, 3, 32'hbbbb_0004);
    slaveWriteMemory(3, 4, 32'hbbbb_0005);
    slaveWriteMemory(3, 5, 32'hbbbb_0006);
    slaveWriteMemory(3, 6, 32'hbbbb_0007);
    slaveWriteMemory(3, 7, 32'hbbbb_0008);
    fork
        begin 
            masterReadTransaction(.masterIndex(2), .transID(0), .transAddr(32'h0000_0000), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end

        begin
            masterReadTransaction(.masterIndex(3), .transID(1), .transAddr(32'hC000_0000), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(1), .memAddr(0));
            delayNs(SYSTEM_CLOCK_PERIOD/2 * 10);
        end
    join
    delayNs(10000);

    /* TESTCASE 6 */
    $display("TESTCASE 6: 4 READ TRANSACTION TO 4 DIFFRENT SLAVE FROM 2 MASTER AT SAME TIME");
    fork
        begin
            masterReadTransaction(.masterIndex(2), .transID(0), .transAddr({00,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            masterReadTransaction(.masterIndex(2), .transID(1), .transAddr({01,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            masterReadTransaction(.masterIndex(2), .transID(2), .transAddr({02,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            masterReadTransaction(.masterIndex(2), .transID(3), .transAddr({03,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
        end
        begin
            masterReadTransaction(.masterIndex(3), .transID(0), .transAddr({00,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            masterReadTransaction(.masterIndex(3), .transID(1), .transAddr({01,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            masterReadTransaction(.masterIndex(3), .transID(2), .transAddr({02,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
            masterReadTransaction(.masterIndex(3), .transID(3), .transAddr({03,{30'd0}}), .transLen(7), .transSize(3'd2), .transBurst(2'd1), .transQoS(0), .memAddr(0));
        
        end
    join
    delayNs(20000);

    $finish;


end
endmodule
