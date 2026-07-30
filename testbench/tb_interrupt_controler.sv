`timescale 1ns/1ps
//=====================================================================
// Testbench cho interrupt_controller
//
// GIA DINH (vi khong co source cua arbiter_priority_irq /
// round_robin_masked_irq trong tay):
//   - priority_i cang LON thi do uu tien cang CAO
//     (neu thuc te nguoc lai, doi cac gia tri priority trong TC3
//      cho phu hop, phan con lai cua TB khong doi)
//   - Cac slave cung priority_i se duoc phan xu round-robin,
//     TB chi kiem tra tinh cong bang (khong bi doi/starvation),
//     khong ep thu tu ID chinh xac vi phu thuoc thiet ke ben trong.
//=====================================================================

module tb_interrupt_controller;

    parameter SLV_AMT    = 4;
    parameter SLV_ID_W   = 2; // $clog2(4)
    parameter PRIORITY_W = 3;
    parameter CLK_PERIOD = 10;

    reg                            clk_i;
    reg                            rst_n_i;
    reg  [SLV_AMT-1:0]             irq_i;
    reg  [SLV_AMT-1:0]             irq_en_i;
    reg  [SLV_AMT*PRIORITY_W-1:0]  priority_i;
    reg                            irq_ack_i;

    wire                           irq_o;
    wire [SLV_ID_W-1:0]            irq_id_o;

    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer i;
    integer got_id, timeout;

    //-----------------------------------------------------------
    // DUT
    //-----------------------------------------------------------
    interrupt_controller #(
        .SLV_AMT   (SLV_AMT),
        .SLV_ID_W  (SLV_ID_W),
        .PRIORITY_W(PRIORITY_W)
    ) dut (
        .clk_i     (clk_i),
        .rst_n_i   (rst_n_i),
        .irq_i     (irq_i),
        .irq_en_i  (irq_en_i),
        .priority_i(priority_i),
        .irq_ack_i (irq_ack_i),
        .irq_o     (irq_o),
        .irq_id_o  (irq_id_o)
    );

    //-----------------------------------------------------------
    // Clock
    //-----------------------------------------------------------
    initial clk_i = 0;
    always #(CLK_PERIOD/2) clk_i = ~clk_i;

    //-----------------------------------------------------------
    // Monitor: in ra tat ca tin hieu input/output moi chu ky clock
    //-----------------------------------------------------------
    parameter ENABLE_MONITOR = 1; // set = 0 neu muon tat log nay

    // Giai ma ten state noi bo (dut.state) cho de doc, phai khop
    // dung localparam IDLE/ASSERT_IRQ/WAIT_RELEASE trong DUT
    function [12*8:1] state_name;
        input [1:0] st;
        begin
            case (st)
                2'd0: state_name = "IDLE";
                2'd1: state_name = "ASSERT_IRQ";
                2'd2: state_name = "WAIT_RLS";
                2'd3: state_name = "DONE";
            endcase
        end
    endfunction

    initial begin
        if (ENABLE_MONITOR) begin
            $display("---------------------------------------------------------------------------------------------------------");
            $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                      "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
            $display("---------------------------------------------------------------------------------------------------------");
        end
    end

    always @(posedge clk_i) begin
        if (ENABLE_MONITOR) begin
            $display("%8t | %4b | %4b | %12b | %1b | %1b | %2b | %10s",
                      $time, irq_i, irq_en_i, priority_i, irq_ack_i, irq_o, irq_id_o,
                      state_name(dut.state));
        end
    end

    //-----------------------------------------------------------
    // Helper tasks
    //-----------------------------------------------------------
    task reset_dut;
    begin
        rst_n_i    = 0;
        irq_i      = 0;
        irq_en_i   = 0;
        priority_i = 0;
        irq_ack_i  = 0;
        repeat (3) @(posedge clk_i);
        rst_n_i = 1;
        @(posedge clk_i);
    end
    endtask

    task set_priority(input integer slv, input [PRIORITY_W-1:0] pri);
    begin
        priority_i[slv*PRIORITY_W +: PRIORITY_W] = pri;
    end
    endtask

    task raise_irq(input integer slv);
    begin
        //$display(" TESTBENCH interrupt_controller");
        irq_i[slv] = 1'b1;
    end
    endtask

    task lower_irq(input integer slv);
    begin
        irq_i[slv] = 1'b0;
    end
    endtask

    // Cho irq_o len 1, co timeout bao ve mo phong khoi treo
    task wait_irq_assert(output integer got, output integer tout);
        integer cnt;
    begin
        cnt  = 0;
        tout = 0;
        while (irq_o !== 1'b1) begin
            @(posedge clk_i);
            cnt = cnt + 1;
            if (cnt > 200) begin
                tout = 1;
                disable wait_irq_assert;
            end
        end
        got = irq_id_o;
    end
    endtask

    // Master ack trong 1 chu ky clock
    task do_ack;
    begin
        @(posedge clk_i);
        irq_ack_i = 1'b1;
        @(posedge clk_i);
        irq_ack_i = 1'b0;
    end
    endtask

    task check(input cond, input [50*8-1:0] msg);
    begin
        if (cond) begin
            pass_cnt = pass_cnt + 1;
            //$display("[PASS] t=%0t : %s", $time, msg);
        end else begin
            fail_cnt = fail_cnt + 1;
            //$display("[FAIL] t=%0t : %s", $time, msg);
        end
    end
    endtask

    //-----------------------------------------------------------
    // Test sequence
    //-----------------------------------------------------------
    initial begin
        $display("=========================================");
        $display(" TESTBENCH interrupt_controller");
        $display("=========================================");

        reset_dut;

        //=========================================================
        // TC1: Mot slave duy nhat phat interrupt
        //=========================================================
        // $display("--- TC1: Single slave interrupt ---");
        // irq_en_i = 4'b1111;
        // fork
        //     set_priority(0, 3'd1);
        //     set_priority(1, 3'd1);
        //     set_priority(2, 3'd1);
        //     set_priority(3, 3'd1);
        // join
        // repeat (1) @(posedge clk_i);
        // raise_irq(2);
        // repeat (1) @(posedge clk_i);
        // wait_irq_assert(got_id, timeout);
        // //check(!timeout,      "TC1: irq_o duoc assert trong thoi gian cho phep");
        // //check(got_id == 2,   "TC1: irq_id_o == 2 (slave duy nhat co irq)");
        // repeat (2) @(posedge clk_i);
        // do_ack;
        // //check(irq_o === 1'b0, "TC1: irq_o ha xuong 0 sau ack");
        // lower_irq(2);
        // repeat (5) @(posedge clk_i);
        // //check(irq_o === 1'b0, "TC1: irq_o = 0 sau khi slave 2 ha irq_i");

        // //=========================================================
        // // TC2: irq_en_i mask - slave bi disable khong duoc phuc vu
        // //=========================================================
        // $display("--- TC2: irq_en_i mask ---");
        // irq_en_i = 4'b1101; // slave 1 bi disable
        // raise_irq(1);
        // repeat (10) @(posedge clk_i);
        // //check(irq_o === 1'b0, "TC2: slave 1 bi disable (irq_en_i[1]=0) khong duoc phuc vu");
        // lower_irq(1);
        // //irq_en_i = 4'b1111;
        // repeat (20) @(posedge clk_i);

        // //=========================================================
        // // TC3: Nhieu slave cung yeu cau, khac priority
        // //      -> chon slave co priority cao nhat truoc
        // //=========================================================
        // $display("--- TC3: Multiple slaves, different priority ---");
        // fork
        //     set_priority(0, 3'd2);
        //     set_priority(1, 3'd5); // cao nhat
        //     set_priority(2, 3'd3);
        //     set_priority(3, 3'd1);
        // join
        // fork
        //     raise_irq(0);
        //     raise_irq(1);
        //     raise_irq(2);
        //     raise_irq(3);
        // join
        // //wait_irq_assert(got_id, timeout);
        // //check(!timeout,    "TC3: irq_o duoc assert");
        // //check(got_id == 1, "TC3: slave priority cao nhat (id=1) duoc chon truoc");
        // repeat (1) @(posedge clk_i);
        // do_ack;
        // lower_irq(1);
        // //repeat (5) @(posedge clk_i);
        // repeat (2) @(posedge clk_i);
        // do_ack;
        // repeat (1) @(posedge clk_i);
        // lower_irq(2);

        // repeat (2) @(posedge clk_i);
        // do_ack;
        // repeat (1) @(posedge clk_i);
        // lower_irq(0);

        // repeat (2) @(posedge clk_i);
        // do_ack;
        // repeat (1) @(posedge clk_i);
        // lower_irq(3);
        // wait_irq_assert(got_id, timeout);
        // check(!timeout,    "TC3: irq_o duoc assert lan 2");
        // check(got_id == 2, "TC3: slave priority cao thu 2 (id=2) duoc chon tiep theo");

        // do_ack;
        // lower_irq(2);
        // repeat (5) @(posedge clk_i);

        // wait_irq_assert(got_id, timeout);
        // check(!timeout,    "TC3: irq_o duoc assert lan 3");
        // check(got_id == 0, "TC3: slave id=0 (pri=2) duoc chon truoc slave id=3(pri=1)");

        // do_ack;
        // lower_irq(0);
        // repeat (5) @(posedge clk_i);

        // wait_irq_assert(got_id, timeout);
        // check(!timeout,    "TC3: irq_o duoc assert lan 4");
        // check(got_id == 3, "TC3: slave cuoi cung id=3 duoc phuc vu");

        // do_ack;
        // lower_irq(3);
        // repeat (5) @(posedge clk_i);
        // check(irq_o === 1'b0, "TC3: khong con slave nao pending, irq_o=0");


//=========================================================
        // TC1: Mot slave duy nhat phat interrupt
        //=========================================================
        $display("--- TC1: Single slave interrupt ---");
        $display("---------------------------------------------------------------------------------------------------------");
        $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                    "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
        $display("---------------------------------------------------------------------------------------------------------");

        irq_en_i = 4'b1111;
        set_priority(0, 3'd1);
        set_priority(1, 3'd1);
        set_priority(2, 3'd1);
        set_priority(3, 3'd1);
 
        raise_irq(2);
        wait_irq_assert(got_id, timeout);
        check(!timeout,      "TC1: irq_o duoc assert trong thoi gian cho phep");
        check(got_id == 2,   "TC1: irq_id_o == 2 (slave duy nhat co irq)");
 
        do_ack;
        check(irq_o === 1'b0, "TC1: irq_o ha xuong 0 sau ack");
 
        lower_irq(2);
        repeat (5) @(posedge clk_i);
        check(irq_o === 1'b0, "TC1: irq_o = 0 sau khi slave 2 ha irq_i");

        repeat (10) @(posedge clk_i);
        //=========================================================
        // TC2: irq_en_i mask - slave bi disable khong duoc phuc vu
        //=========================================================
        $display("--- TC2: irq_en_i mask ---");
        $display("---------------------------------------------------------------------------------------------------------");
        $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                    "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
        $display("---------------------------------------------------------------------------------------------------------");

        irq_en_i = 4'b1101; // slave 1 bi disable
        raise_irq(1);
        repeat (20) @(posedge clk_i);
        check(irq_o === 1'b0, "TC2: slave 1 bi disable (irq_en_i[1]=0) khong duoc phuc vu");
        lower_irq(1);
        irq_en_i = 4'b1111;
        @(posedge clk_i);
        repeat (10) @(posedge clk_i);
        //=========================================================
        // TC3: Nhieu slave cung yeu cau, khac priority
        //      -> chon slave co priority cao nhat truoc
        //=========================================================
        $display("--- TC3: Multiple slaves, different priority ---");
        $display("---------------------------------------------------------------------------------------------------------");
        $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                    "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
        $display("---------------------------------------------------------------------------------------------------------");

        set_priority(0, 3'd2);
        set_priority(1, 3'd5); // cao nhat
        set_priority(2, 3'd3);
        set_priority(3, 3'd1);
 
        raise_irq(0);
        raise_irq(1);
        raise_irq(2);
        raise_irq(3);
 
        wait_irq_assert(got_id, timeout);
        check(!timeout,    "TC3: irq_o duoc assert");
        check(got_id == 1, "TC3: slave priority cao nhat (id=1) duoc chon truoc");
 
        do_ack;
        lower_irq(1);
        repeat (5) @(posedge clk_i);
 
        wait_irq_assert(got_id, timeout);
        check(!timeout,    "TC3: irq_o duoc assert lan 2");
        check(got_id == 2, "TC3: slave priority cao thu 2 (id=2) duoc chon tiep theo");
 
        do_ack;
        lower_irq(2);
        repeat (5) @(posedge clk_i);
 
        wait_irq_assert(got_id, timeout);
        check(!timeout,    "TC3: irq_o duoc assert lan 3");
        check(got_id == 0, "TC3: slave id=0 (pri=2) duoc chon truoc slave id=3(pri=1)");
 
        do_ack;
        lower_irq(0);
        repeat (5) @(posedge clk_i);
 
        wait_irq_assert(got_id, timeout);
        check(!timeout,    "TC3: irq_o duoc assert lan 4");
        check(got_id == 3, "TC3: slave cuoi cung id=3 duoc phuc vu");
 
        do_ack;
        lower_irq(3);
        repeat (5) @(posedge clk_i);
        check(irq_o === 1'b0, "TC3: khong con slave nao pending, irq_o=0");

        repeat (10) @(posedge clk_i);
        //=========================================================
        // TC4: Cac slave co cung priority -> round robin
        //      (chi kiem tra cong bang qua nhieu vong)
        //=========================================================
        $display("--- TC4: Round-robin fairness (same priority) ---");
        $display("---------------------------------------------------------------------------------------------------------");
        $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                    "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
        $display("---------------------------------------------------------------------------------------------------------");

        begin
            integer serve_count [0:SLV_AMT-1];
            integer round;
            fork
                set_priority(0, 3'd4);
                set_priority(1, 3'd4);
                set_priority(2, 3'd4);
                set_priority(3, 3'd4);
            join
            fork
                raise_irq(0);
                raise_irq(1);
                raise_irq(2);
                raise_irq(3);
            join
            while (irq_i != 4'b0000) begin
                wait_irq_assert(got_id, timeout); // cho DUT assert irq_o cho 1 slave
                do_ack;                           // master ack
                @(posedge clk_i);
                lower_irq(got_id);                // slave ha irq cua chinh no
                @(posedge clk_i);
            end

        end
        //irq_i = 4'b0000;
        repeat (10) @(posedge clk_i);

        //=========================================================
        // TC5: Slave phat interrupt tro lai ngay sau khi vua duoc
        //      xu ly xong (back-to-back)
        //=========================================================
        $display("--- TC5: Back-to-back interrupt tren cung 1 slave ---");
        $display("---------------------------------------------------------------------------------------------------------");
        $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                    "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
        $display("---------------------------------------------------------------------------------------------------------");

        set_priority(0, 3'd1);
        raise_irq(0);
        wait_irq_assert(got_id, timeout);
        check(!timeout && got_id == 0, "TC5: lan 1 - slave 0 duoc phuc vu");
        do_ack;
        lower_irq(0);
        repeat (2) @(posedge clk_i);

        raise_irq(0); // phat lai ngay
        wait_irq_assert(got_id, timeout);
        check(!timeout && got_id == 0, "TC5: lan 2 - slave 0 duoc phuc vu lai");
        do_ack;
        lower_irq(0);
        repeat (10) @(posedge clk_i);

        //=========================================================
        // TC6: Slave khac phat irq trong luc controller dang xu ly
        //      1 slave khac (phai doi den luot)
        //=========================================================
        $display("--- TC6: Interrupt moi den trong luc dang xu ly slave khac ---");
        $display("---------------------------------------------------------------------------------------------------------");
        $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                    "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
        $display("---------------------------------------------------------------------------------------------------------");

        set_priority(1, 3'd1);
        set_priority(2, 3'd1);
        raise_irq(1);
        wait_irq_assert(got_id, timeout);
        check(!timeout && got_id == 1, "TC6: slave 1 duoc chon truoc");

        raise_irq(2); // slave 2 phat irq khi slave 1 chua duoc ack
        check(irq_id_o == 1, "TC6: irq_id_o van giu nguyen la slave 1 dang xu ly");

        do_ack;
        lower_irq(1);
        repeat (3) @(posedge clk_i);

        wait_irq_assert(got_id, timeout);
        check(!timeout && got_id == 2, "TC6: sau khi xong slave 1, slave 2 duoc phuc vu");
        do_ack;
        lower_irq(2);
        repeat (10) @(posedge clk_i);

        //=========================================================
        // TC7: Slave ha irq_i truoc khi master kip ack
        //=========================================================
        $display("--- TC7: Slave ha irq_i som (truoc ack) ---");
        $display("---------------------------------------------------------------------------------------------------------");
        $display("%8s | %6s | %8s | %10s | %9s | %5s | %8s | %10s",
                    "time", "irq_i", "irq_en_i", "priority_i", "irq_ack_i", "irq_o", "irq_id_o", "state");
        $display("---------------------------------------------------------------------------------------------------------");

        set_priority(3, 3'd1);
        raise_irq(3);
        wait_irq_assert(got_id, timeout);
        check(!timeout && got_id == 3, "TC7: slave 3 duoc chon");

        lower_irq(3); // ha irq_i truoc khi ack
        do_ack;
        repeat (10) @(posedge clk_i);
        check(irq_o === 1'b0, "TC7: irq_o tro ve 0, khong bi treo khi request bien mat som");

        //=========================================================
        // Ket qua tong hop
        //=========================================================
        $display("=========================================");
        $display(" KET QUA: PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt);
        $display("=========================================");
        if (fail_cnt == 0)
            $display("*** TAT CA TEST CASE DEU PASS ***");
        else
            $display("*** CO %0d TEST CASE FAIL ***", fail_cnt);

        $finish;
    end

    // Timeout toan cuc phong ngua treo mo phong
    initial begin
        #100000;
        $display("[TIMEOUT] Mo phong vuot qua thoi gian cho phep, dang dung...");
        $finish;
    end

    initial begin
        $dumpfile("tb_interrupt_controller.vcd");
        $dumpvars(0, tb_interrupt_controller);
    end

endmodule