//=====================================================================
// axi_slave_if.v
// Slave device: nhan AXI4 write/read transaction tu axi_interconnect,
// xu ly va tra data/response ve interconnect.
//
// AW/W/B/AR/R hoat dong doc lap (moi channel co logic rieng), nhung:
//   - B channel CHI phat sau khi CA AW va W (toi WLAST) da nhan xong
//   - R channel CHI bat dau phat SAU KHI AR da duoc chap nhan
// Moi huong (write / read) xu ly don outstanding (1 giao dich / luc):
//   AWREADY chi bat khi khong co giao dich write nao dang xu ly (aw_busy=0)
//   ARREADY chi bat khi khong co giao dich read  nao dang xu ly (ar_busy=0)
//
// LUU Y VE ID_WIDTH: khi instantiate module nay trong he thong co
// axi_interconnect, phai gan ID_WIDTH = MST_ID_W + TRANS_MST_ID_W cua
// interconnect (KHONG phai bang ID_WIDTH ben Master), vi interconnect
// gan them ma so Master (MST_ID_W bit) vao truoc ID goc de dinh tuyen
// response B/R ve dung Master. Slave chi can echo nguyen ID nhan duoc
// tren AWID/ARID ra lai BID/RID - module ben duoi lam dung viec nay.
//=====================================================================
module axi_slave_if_n #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter RAM_SIZE = 128,

    parameter RAM_ADDR_WIDTH = $clog2(RAM_SIZE)
)(
    input                       ACLK_i,
    input                       ARESETn_i,

    //================ LOCAL CONTROL INTERFACE =================//
    input  [RAM_ADDR_WIDTH-1:0] s_address_memory,
    input                       s_READ_EN,
    input  [DATA_WIDTH-1:0]     s_DATA_MEMORY_i,
    input                       s_WRITE_EN,
    output [DATA_WIDTH-1:0]     s_DATA_MEMORY_o,

    //================ WRITE ADDRESS CHANNEL ===================//
    input                       s_AWVALID_i,
    input  [ID_WIDTH-1:0]       s_AWID_i,
    input  [ADDR_WIDTH-1:0]     s_AWADDR_i,
    input  [7:0]                s_AWLEN_i,
    input  [1:0]                s_AWBURST_i,
    input  [2:0]                s_AWSIZE_i,
    input  [3:0]                s_AWQOS_i,
    output                      s_AWREADY_o,

    //================ WRITE DATA CHANNEL ======================//
    input                       s_WVALID_i,
    input  [DATA_WIDTH-1:0]     s_WDATA_i,
    input                       s_WLAST_i,
    output                      s_WREADY_o,

    //================ WRITE RESPONSE CHANNEL ==================//
    output                      s_BVALID_o,
    output [ID_WIDTH-1:0]       s_BID_o,
    output [1:0]                s_BRESP_o,
    input                       s_BREADY_i,

    //================ READ ADDRESS CHANNEL ====================//
    input                       s_ARVALID_i,
    input  [ID_WIDTH-1:0]       s_ARID_i,
    input  [ADDR_WIDTH-1:0]     s_ARADDR_i,
    input  [7:0]                s_ARLEN_i,
    input  [1:0]                s_ARBURST_i,
    input  [2:0]                s_ARSIZE_i,
    input  [3:0]                s_ARQOS_i,
    output                      s_ARREADY_o,

    //================ READ DATA CHANNEL =======================//
    output                      s_RVALID_o,
    output                      s_RLAST_o,
    output [ID_WIDTH-1:0]       s_RID_o,
    output [DATA_WIDTH-1:0]     s_RDATA_o,
    output [1:0]                s_RRESP_o,
    input                       s_RREADY_i
);

    // So bit dia chi byte can bo qua de doi dia chi byte (AWADDR/ARADDR)
    // sang dia chi tu (word) cua RAM noi bo.
    // Gia dinh moi transfer la full-width (khong ho tro WSTRB / partial write)
    localparam ADDR_LSB = $clog2(DATA_WIDTH/8);

    //-----------------------------------------------------------------
    // RAM noi bo cua Slave
    //   - Cong ngoai : s_address_memory / READ_EN / WRITE_EN
    //   - Cong AXI   : W channel ghi vao, R channel doc ra
    //-----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] ram_mem [0:RAM_SIZE-1];

    //================================================================
    // AW - don outstanding: AWREADY chi bat khi khong co giao dich
    // write nao dang duoc xu ly (aw_busy = 0)
    //================================================================
    reg                      aw_busy;
    reg [ID_WIDTH-1:0]       aw_id_r;

    wire aw_accept_pulse = s_AWVALID_i && s_AWREADY_o;
    wire b_done_pulse;

    assign s_AWREADY_o = !aw_busy;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i)
            aw_busy <= 1'b0;
        else if (aw_accept_pulse)
            aw_busy <= 1'b1;
        else if (b_done_pulse)
            aw_busy <= 1'b0;
    end

    always @(posedge ACLK_i) begin
        if (aw_accept_pulse)
            aw_id_r <= s_AWID_i;
    end

    //================================================================
    // W - chi nhan beat (WREADY=1) sau khi AW da duoc chap nhan va
    // chua nhan du (chua toi WLAST) cua giao dich hien tai
    //================================================================
    reg                      w_done;   // da nhan xong WLAST, dang cho B gui response
    reg [RAM_ADDR_WIDTH-1:0] w_ptr;
    wire                     w_beat = s_WVALID_i && s_WREADY_o;

    assign s_WREADY_o = aw_busy && !w_done;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            w_done <= 1'b0;
            w_ptr  <= {RAM_ADDR_WIDTH{1'b0}};
        end else if (aw_accept_pulse) begin
            // giao dich write moi bat dau: nap con tro ghi tu AWADDR, reset co done
            w_ptr  <= s_AWADDR_i[(RAM_ADDR_WIDTH+ADDR_LSB-1):ADDR_LSB];
            w_done <= 1'b0;
        end else if (w_beat) begin
            if (s_WLAST_i)
                w_done <= 1'b1;
            else
                w_ptr <= w_ptr + 1'b1;
        end
    end

    wire w_wr_en = w_beat; // dung cho RAM ghi du lieu W channel

    //================================================================
    // B - CHI phat response SAU KHI CA AW va W (WLAST) da nhan xong
    //================================================================
    reg                b_valid_r;
    reg [ID_WIDTH-1:0] b_id_r;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            b_valid_r <= 1'b0;
        end else if (aw_busy && w_done && !b_valid_r) begin
            b_valid_r <= 1'b1;
            b_id_r    <= aw_id_r;
        end else if (b_valid_r && s_BREADY_i) begin
            b_valid_r <= 1'b0;
        end
    end

    assign s_BVALID_o  = b_valid_r;
    assign s_BID_o     = b_id_r;
    assign s_BRESP_o   = 2'b00; // OKAY
    assign b_done_pulse = b_valid_r && s_BREADY_i;

    //================================================================
    // AR - don outstanding: ARREADY chi bat khi khong co giao dich
    // read nao dang duoc xu ly (ar_busy = 0)
    //================================================================
    reg ar_busy;

    wire ar_accept_pulse = s_ARVALID_i && s_ARREADY_o;
    wire r_done_pulse;

    assign s_ARREADY_o = !ar_busy;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i)
            ar_busy <= 1'b0;
        else if (ar_accept_pulse)
            ar_busy <= 1'b1;
        else if (r_done_pulse)
            ar_busy <= 1'b0;
    end

    //================================================================
    // R - CHI bat dau phat SAU KHI AR da duoc chap nhan (ar_accept_pulse)
    //================================================================
    localparam R_IDLE = 1'b0, R_SEND = 1'b1;
    reg                      r_state;
    reg                      r_valid_r;
    reg [RAM_ADDR_WIDTH-1:0] r_ptr;
    reg [7:0]                r_beat_cnt;
    reg [7:0]                r_len_r;
    reg [ID_WIDTH-1:0]       r_id_r;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            r_state   <= R_IDLE;
            r_valid_r <= 1'b0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    if (ar_accept_pulse) begin
                        r_ptr      <= s_ARADDR_i[(RAM_ADDR_WIDTH+ADDR_LSB-1):ADDR_LSB];
                        r_len_r    <= s_ARLEN_i;
                        r_id_r     <= s_ARID_i;
                        r_beat_cnt <= 8'd0;
                        r_valid_r  <= 1'b1;
                        r_state    <= R_SEND;
                    end
                end
                R_SEND: begin
                    if (s_RREADY_i) begin
                        if (r_beat_cnt == r_len_r) begin
                            r_valid_r <= 1'b0;
                            r_state   <= R_IDLE;
                        end else begin
                            r_beat_cnt <= r_beat_cnt + 8'd1;
                            r_ptr      <= r_ptr + 1'b1;
                        end
                    end
                end
                default: r_state <= R_IDLE;
            endcase
        end
    end

    assign s_RVALID_o  = r_valid_r;
    assign s_RDATA_o   = ram_mem[r_ptr];
    assign s_RLAST_o   = r_valid_r && (r_beat_cnt == r_len_r);
    assign s_RID_o     = r_id_r;
    assign s_RRESP_o   = 2'b00; // OKAY
    assign r_done_pulse = r_valid_r && (r_beat_cnt == r_len_r) && s_RREADY_i;

    //================================================================
    // RAM noi bo: 1 cong ghi (uu tien ben ngoai truoc, roi den W channel),
    // 1 cong doc dang ky cho truy cap ngoai (dong bo theo s_READ_EN),
    // rieng R channel doc truc tiep ram_mem[r_ptr] (khong can dang ky).
    //================================================================
    reg [DATA_WIDTH-1:0] dmem_out_r;

    always @(posedge ACLK_i) begin
        if (s_WRITE_EN)
            ram_mem[s_address_memory] <= s_DATA_MEMORY_i; // ghi tu ben ngoai - uu tien
        else if (w_wr_en)
            ram_mem[w_ptr] <= s_WDATA_i;                   // ghi tu AXI W channel

        if (s_READ_EN)
            dmem_out_r <= ram_mem[s_address_memory];
    end

    assign s_DATA_MEMORY_o = dmem_out_r;

endmodule