//=====================================================================
// axi_master_if.v
// Master device: tao AXI4 write/read transaction gui vao axi_interconnect
//
// AW/AR/W/R/B hoat dong doc lap (moi channel 1 FSM rieng), nhung:
//   - W channel CHI bat dau sau khi AW handshake xong (aw_done_pulse)
//   - R channel CHI bat dau nhan sau khi AR handshake xong (ar_done_pulse)
// Moi loai giao dich (write / read) xu ly tuan tu tung cai mot,
// khong ho tro outstanding song song trong ban thiet ke nay.
//=====================================================================
module axi_master_if #(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,    // Toi da tuy vao so luong device va memory
    parameter DATA_WIDTH = 32,    // Toi da 1024
    parameter RAM_SIZE = 128,

    parameter RAM_ADDR_WIDTH = $clog2(RAM_SIZE)
)(
    input                       ACLK_i,
    input                       ARESETn_i,

    //================ Control ======================//
    // Tin hieu doc va ghi vao RAM noi
    input  [RAM_ADDR_WIDTH-1:0] m_address_memory,
    input                       m_READ_EN,
    input  [DATA_WIDTH-1:0]     m_DATA_MEMORY_i,
    input                       m_WRITE_EN,
    output [DATA_WIDTH-1:0]     m_DATA_MEMORY_o,

    // Transaction READ
    input                       ReadTrans_EN_i,
    input  [RAM_ADDR_WIDTH-1:0] r_set_addr_memory,
    input  [ID_WIDTH-1:0]       set_ARID_i,
    input  [ADDR_WIDTH-1:0]     set_ARADDR_i,
    input  [1:0]                set_ARBURST_i,
    input  [7:0]                set_ARLEN_i,
    input  [2:0]                set_ARSIZE_i,
    input  [3:0]                set_ARQOS_i,

    // Transaction WRITE
    input                       WriteTrans_EN_i,
    input  [RAM_ADDR_WIDTH-1:0] w_set_addr_memory,
    input  [ID_WIDTH-1:0]       set_AWID_i,
    input  [ADDR_WIDTH-1:0]     set_AWADDR_i,
    input  [1:0]                set_AWBURST_i,
    input  [7:0]                set_AWLEN_i,
    input  [2:0]                set_AWSIZE_i,
    input  [3:0]                set_AWQOS_i,

    //================ WRITE ADDRESS =================//
    output                      m_AWVALID_o,
    output [ID_WIDTH-1:0]       m_AWID_o,
    output [ADDR_WIDTH-1:0]     m_AWADDR_o,
    output [1:0]                m_AWBURST_o,
    output [7:0]                m_AWLEN_o,
    output [2:0]                m_AWSIZE_o,
    output [3:0]                m_AWQOS_o,
    input                       m_AWREADY_i,

    //================ WRITE DATA ====================//
    output                      m_WVALID_o,
    output [DATA_WIDTH-1:0]     m_WDATA_o,
    output                      m_WLAST_o,
    input                       m_WREADY_i,

    //================ WRITE RESP ====================//
    input                       m_BVALID_i,
    input  [ID_WIDTH-1:0]       m_BID_i,
    input  [1:0]                m_BRESP_i,
    output                      m_BREADY_o,

    //================ READ ADDRESS ==================//
    output                      m_ARVALID_o,
    output [ID_WIDTH-1:0]       m_ARID_o,
    output [ADDR_WIDTH-1:0]     m_ARADDR_o,
    output [1:0]                m_ARBURST_o,
    output [7:0]                m_ARLEN_o,
    output [2:0]                m_ARSIZE_o,
    output [3:0]                m_ARQOS_o,
    input                       m_ARREADY_i,

    //================ READ DATA =====================//
    input                       m_RVALID_i,
    input                       m_RLAST_i,
    input  [ID_WIDTH-1:0]       m_RID_i,
    input  [DATA_WIDTH-1:0]     m_RDATA_i,
    input  [1:0]                m_RRESP_i,
    output                      m_RREADY_o
);

    //-----------------------------------------------------------------
    // RAM noi bo cua Master
    //   - Cong ngoai : m_address_memory / READ_EN / WRITE_EN
    //   - Cong AXI   : W channel doc ra de gui, R channel ghi vao khi nhan
    //-----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] ram_mem [0:RAM_SIZE-1];

    //================================================================
    // AW FSM
    //================================================================
    localparam AW_IDLE = 1'b0, AW_SEND = 1'b1;
    reg                      aw_state;
    reg                      m_AWVALID_r;
    reg [ID_WIDTH-1:0]       aw_id_r;
    reg [ADDR_WIDTH-1:0]     aw_addr_r;
    reg [7:0]                aw_len_r;
    reg [2:0]                aw_size_r;
    reg [1:0]                aw_burst_r;
    reg [3:0]                aw_qos_r;
    reg [RAM_ADDR_WIDTH-1:0] w_ptr_latch;
    reg                      aw_done_pulse;

    wire w_idle; // W FSM dang ranh -> AW moi duoc phep phat giao dich moi

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            aw_state      <= AW_IDLE;
            m_AWVALID_r   <= 1'b0;
            aw_done_pulse <= 1'b0;
        end else begin
            aw_done_pulse <= 1'b0;
            case (aw_state)
                AW_IDLE: begin
                    if (WriteTrans_EN_i && w_idle) begin
                        aw_id_r     <= set_AWID_i;
                        aw_addr_r   <= set_AWADDR_i;
                        aw_len_r    <= set_AWLEN_i;
                        aw_size_r   <= set_AWSIZE_i;
                        aw_burst_r  <= set_AWBURST_i;
                        aw_qos_r    <= set_AWQOS_i;
                        w_ptr_latch <= w_set_addr_memory;
                        m_AWVALID_r <= 1'b1;
                        aw_state    <= AW_SEND;
                    end
                end
                AW_SEND: begin
                    if (m_AWREADY_i) begin
                        m_AWVALID_r   <= 1'b0;
                        aw_done_pulse <= 1'b1; // bao cho W FSM biet AW da xong
                        aw_state      <= AW_IDLE;
                    end
                end
                default: aw_state <= AW_IDLE;
            endcase
        end
    end

    assign m_AWVALID_o = m_AWVALID_r;
    assign m_AWID_o    = aw_id_r;
    assign m_AWADDR_o  = aw_addr_r;
    assign m_AWLEN_o   = aw_len_r;
    assign m_AWSIZE_o  = aw_size_r;
    assign m_AWBURST_o = aw_burst_r;
    assign m_AWQOS_o   = aw_qos_r;

    //================================================================
    // W FSM - CHI bat dau SAU KHI AW handshake xong (aw_done_pulse)
    //================================================================
    localparam W_IDLE = 1'b0, W_SEND = 1'b1;
    reg                      w_state;
    reg                      m_WVALID_r;
    reg [RAM_ADDR_WIDTH-1:0] w_ptr;
    reg [7:0]                w_beat_cnt;
    reg [7:0]                w_len_r;

    assign w_idle = (w_state == W_IDLE);

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            w_state    <= W_IDLE;
            m_WVALID_r <= 1'b0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    if (aw_done_pulse) begin
                        w_ptr      <= w_ptr_latch;
                        w_len_r    <= aw_len_r;
                        w_beat_cnt <= 8'd0;
                        m_WVALID_r <= 1'b1;
                        w_state    <= W_SEND;
                    end
                end
                W_SEND: begin
                    if (m_WREADY_i) begin
                        if (w_beat_cnt == w_len_r) begin
                            m_WVALID_r <= 1'b0;
                            w_state    <= W_IDLE;
                        end else begin
                            w_beat_cnt <= w_beat_cnt + 8'd1;
                            w_ptr      <= w_ptr + 1'b1;
                        end
                    end
                end
                default: w_state <= W_IDLE;
            endcase
        end
    end

    assign m_WVALID_o = m_WVALID_r;
    assign m_WDATA_o  = ram_mem[w_ptr];
    assign m_WLAST_o  = m_WVALID_r && (w_beat_cnt == w_len_r);

    //================================================================
    // B channel - luon san sang nhan response
    // (co the mo rong: luu m_BID_i / m_BRESP_i vao thanh ghi bao loi neu can)
    //================================================================
    assign m_BREADY_o = 1'b1;

    //================================================================
    // AR FSM
    //================================================================
    localparam AR_IDLE = 1'b0, AR_SEND = 1'b1;
    reg                      ar_state;
    reg                      m_ARVALID_r;
    reg [ID_WIDTH-1:0]       ar_id_r;
    reg [ADDR_WIDTH-1:0]     ar_addr_r;
    reg [7:0]                ar_len_r;
    reg [2:0]                ar_size_r;
    reg [1:0]                ar_burst_r;
    reg [3:0]                ar_qos_r;
    reg [RAM_ADDR_WIDTH-1:0] r_ptr_latch;
    reg                      ar_done_pulse;

    wire r_idle; // R FSM dang ranh -> AR moi duoc phep phat giao dich moi

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            ar_state      <= AR_IDLE;
            m_ARVALID_r   <= 1'b0;
            ar_done_pulse <= 1'b0;
        end else begin
            ar_done_pulse <= 1'b0;
            case (ar_state)
                AR_IDLE: begin
                    if (ReadTrans_EN_i && r_idle) begin
                        ar_id_r     <= set_ARID_i;
                        ar_addr_r   <= set_ARADDR_i;
                        ar_len_r    <= set_ARLEN_i;
                        ar_size_r   <= set_ARSIZE_i;
                        ar_burst_r  <= set_ARBURST_i;
                        ar_qos_r    <= set_ARQOS_i;
                        r_ptr_latch <= r_set_addr_memory;
                        m_ARVALID_r <= 1'b1;
                        ar_state    <= AR_SEND;
                    end
                end
                AR_SEND: begin
                    if (m_ARREADY_i) begin
                        m_ARVALID_r   <= 1'b0;
                        ar_done_pulse <= 1'b1;
                        ar_state      <= AR_IDLE;
                    end
                end
                default: ar_state <= AR_IDLE;
            endcase
        end
    end

    assign m_ARVALID_o = m_ARVALID_r;
    assign m_ARID_o    = ar_id_r;
    assign m_ARADDR_o  = ar_addr_r;
    assign m_ARLEN_o   = ar_len_r;
    assign m_ARSIZE_o  = ar_size_r;
    assign m_ARBURST_o = ar_burst_r;
    assign m_ARQOS_o   = ar_qos_r;

    //================================================================
    // R FSM - CHI bat dau nhan SAU KHI AR handshake xong (ar_done_pulse)
    //================================================================
    localparam R_IDLE = 1'b0, R_RECV = 1'b1;
    reg                      r_state;
    reg                      m_RREADY_r;
    reg [RAM_ADDR_WIDTH-1:0] r_ptr;
    wire                     r_wr_en;

    assign r_idle = (r_state == R_IDLE);

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            r_state    <= R_IDLE;
            m_RREADY_r <= 1'b0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    if (ar_done_pulse) begin
                        r_ptr      <= r_ptr_latch;
                        m_RREADY_r <= 1'b1;
                        r_state    <= R_RECV;
                    end
                end
                R_RECV: begin
                    if (m_RVALID_i && m_RREADY_r) begin
                        if (m_RLAST_i) begin
                            m_RREADY_r <= 1'b0;
                            r_state    <= R_IDLE;
                        end else begin
                            r_ptr <= r_ptr + 1'b1;
                        end
                    end
                end
                default: r_state <= R_IDLE;
            endcase
        end
    end

    assign m_RREADY_o = m_RREADY_r;
    assign r_wr_en    = (r_state == R_RECV) && m_RVALID_i && m_RREADY_r;

    //================================================================
    // RAM noi bo: 1 cong ghi (uu tien ben ngoai truoc, roi den R channel),
    // 1 cong doc dang ky cho truy cap ngoai (dong bo theo m_READ_EN),
    // rieng W channel doc truc tiep ram_mem[w_ptr] (khong can dang ky).
    //================================================================
    reg [DATA_WIDTH-1:0] dmem_out_r;

    always @(posedge ACLK_i) begin
        if (m_WRITE_EN)
            ram_mem[m_address_memory] <= m_DATA_MEMORY_i; // ghi tu ben ngoai - uu tien
        else if (r_wr_en)
            ram_mem[r_ptr] <= m_RDATA_i;                   // ghi tu AXI R channel

        if (m_READ_EN)
            dmem_out_r <= ram_mem[m_address_memory];
    end

    assign m_DATA_MEMORY_o = dmem_out_r;

endmodule