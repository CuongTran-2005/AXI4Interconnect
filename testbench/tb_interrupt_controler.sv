// `timescale 1ns/1ps

// module tb_interrupt_controller;

//     //--------------------------------------------------------------
//     // PARAMETERS
//     //--------------------------------------------------------------
//     parameter SLV_AMT    = 4;
//     parameter SLV_ID_W   = (SLV_AMT > 1) ? $clog2(SLV_AMT) : 1;
//     parameter PRIORITY_W = 3;

//     parameter CLK_PERIOD = 10;


//     //--------------------------------------------------------------
//     // DUT INPUT
//     //--------------------------------------------------------------
//     reg                             clk_i;
//     reg                             rst_n_i;

//     reg [SLV_AMT-1:0]               irq_i;

//     reg [SLV_AMT-1:0]               irq_en_i;

//     reg [SLV_AMT*PRIORITY_W-1:0]    priority_i;

//     reg                             irq_ack_i;


//     //--------------------------------------------------------------
//     // DUT OUTPUT
//     //--------------------------------------------------------------
//     wire                            irq_o;
//     wire [SLV_ID_W-1:0]             irq_id_o;


//     //--------------------------------------------------------------
//     // DUT
//     //--------------------------------------------------------------
//     interrupt_controller #(
//         .SLV_AMT    (SLV_AMT),
//         .SLV_ID_W   (SLV_ID_W),
//         .PRIORITY_W (PRIORITY_W)
//     )
//     dut (
//         .clk_i       (clk_i),
//         .rst_n_i     (rst_n_i),

//         .irq_i       (irq_i),

//         .irq_en_i    (irq_en_i),
//         .priority_i  (priority_i),

//         .irq_ack_i   (irq_ack_i),

//         .irq_o       (irq_o),
//         .irq_id_o    (irq_id_o)
//     );


//     //--------------------------------------------------------------
//     // CLOCK
//     //--------------------------------------------------------------
//     initial begin
//         clk_i = 1'b0;

//         forever #(CLK_PERIOD/2)
//             clk_i = ~clk_i;
//     end


//     //--------------------------------------------------------------
//     // MONITOR
//     //--------------------------------------------------------------
//     always @(posedge clk_i) begin

//         $display("");
//         $display(
//             "=============================================================="
//         );

//         $display(
//             "[TIME %0t] INPUT",
//             $time
//         );

//         $display(
//             "  rst_n_i   = %b",
//             rst_n_i
//         );

//         $display(
//             "  irq_i     = %b",
//             irq_i
//         );

//         $display(
//             "  irq_en_i  = %b",
//             irq_en_i
//         );

//         $display(
//             "  irq_ack_i = %b",
//             irq_ack_i
//         );

//         $display(
//             "  PRIORITY  : SLV0=%0d | SLV1=%0d | SLV2=%0d | SLV3=%0d",
//             priority_i[0*PRIORITY_W +: PRIORITY_W],
//             priority_i[1*PRIORITY_W +: PRIORITY_W],
//             priority_i[2*PRIORITY_W +: PRIORITY_W],
//             priority_i[3*PRIORITY_W +: PRIORITY_W]
//         );

//         $display(
//             "[TIME %0t] OUTPUT",
//             $time
//         );

//         $display(
//             "  irq_o     = %b",
//             irq_o
//         );

//         $display(
//             "  irq_id_o  = %0d",
//             irq_id_o
//         );

//         if (irq_o) begin

//             $display(
//                 "  >>> CONTROLLER IS SERVING SLAVE %0d",
//                 irq_id_o
//             );

//         end
//         else begin

//             $display(
//                 "  >>> CONTROLLER IS NOT SERVING ANY SLAVE"
//             );

//         end

//     end


//     //--------------------------------------------------------------
//     // TASK: SET PRIORITY
//     //--------------------------------------------------------------
//     task set_priority;
//         input integer slv;
//         input [PRIORITY_W-1:0] priority_value;

//         begin

//             priority_i[
//                 slv*PRIORITY_W +: PRIORITY_W
//             ] = priority_value;

//         end

//     endtask


//     //--------------------------------------------------------------
//     // TASK: WAIT CLOCK
//     //--------------------------------------------------------------
//     task wait_clk;
//         input integer n;

//         begin

//             repeat(n)
//                 @(posedge clk_i);

//         end

//     endtask


//     //--------------------------------------------------------------
//     // TASK: MASTER ACK
//     //--------------------------------------------------------------
//     task master_ack;

//         begin

//             $display("");
//             $display(
//                 ">>> MASTER: received IRQ from SLAVE %0d",
//                 irq_id_o
//             );

//             @(negedge clk_i);

//             irq_ack_i = 1'b1;

//             $display(
//                 ">>> MASTER: irq_ack_i = 1"
//             );

//             @(negedge clk_i);

//             irq_ack_i = 1'b0;

//             $display(
//                 ">>> MASTER: irq_ack_i = 0"
//             );

//         end

//     endtask


//     //--------------------------------------------------------------
//     // TASK: SLAVE RELEASE INTERRUPT
//     //--------------------------------------------------------------
//     task slave_release;
//         input integer slv;

//         begin

//             @(negedge clk_i);

//             irq_i[slv] = 1'b0;

//             $display("");
//             $display(
//                 ">>> SLAVE %0d: IRQ RELEASED -> irq_i[%0d] = 0",
//                 slv,
//                 slv
//             );

//         end

//     endtask


//     //--------------------------------------------------------------
//     // TASK: SLAVE ASSERT INTERRUPT
//     //--------------------------------------------------------------
//     task slave_irq;
//         input integer slv;

//         begin

//             @(negedge clk_i);

//             irq_i[slv] = 1'b1;

//             $display("");
//             $display(
//                 ">>> SLAVE %0d: IRQ ASSERTED -> irq_i[%0d] = 1",
//                 slv,
//                 slv
//             );

//         end

//     endtask


//     //--------------------------------------------------------------
//     // TASK: TESTCASE HEADER
//     //--------------------------------------------------------------
//     task testcase;
//         input [200*8:1] name;

//         begin

//             $display("");
//             $display("");
//             $display("############################################################");
//             $display("# %s", name);
//             $display("############################################################");

//         end

//     endtask


//     //--------------------------------------------------------------
//     // INITIAL TEST
//     //--------------------------------------------------------------
//     initial begin

//         //----------------------------------------------------------
//         // INITIAL VALUES
//         //----------------------------------------------------------

//         rst_n_i   = 1'b0;

//         irq_i     = 4'b0000;

//         irq_en_i  = 4'b1111;

//         irq_ack_i = 1'b0;

//         priority_i = {SLV_AMT*PRIORITY_W{1'b0}};


//         //----------------------------------------------------------
//         // PRIORITY
//         //----------------------------------------------------------
//         //
//         // SLV0 = 1
//         // SLV1 = 3
//         // SLV2 = 5
//         // SLV3 = 7
//         //
//         //----------------------------------------------------------

//         set_priority(0, 3'd1);
//         set_priority(1, 3'd3);
//         set_priority(2, 3'd5);
//         set_priority(3, 3'd7);


//         //----------------------------------------------------------
//         // TC01
//         //----------------------------------------------------------

//         testcase("TC01 - RESET");

//         wait_clk(3);


//         //----------------------------------------------------------
//         // RELEASE RESET
//         //----------------------------------------------------------

//         @(negedge clk_i);

//         rst_n_i = 1'b1;

//         wait_clk(2);


//         //----------------------------------------------------------
//         // TC02
//         //
//         // SLV0 ASSERT IRQ
//         //----------------------------------------------------------

//         testcase("TC02 - SINGLE SLAVE INTERRUPT");

//         slave_irq(0);

//         wait_clk(2);

//         /*
//          * Expected:
//          *
//          * irq_o    = 1
//          * irq_id_o = 0
//          */

//         master_ack;

//         wait_clk(2);


//         //----------------------------------------------------------
//         // IMPORTANT:
//         //
//         // IRQ FROM SLV0 IS STILL HIGH.
//         //
//         // Controller must NOT move to another slave.
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> CHECK: SLV0 IRQ IS STILL HIGH"
//         );

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV0 RELEASES IRQ
//         //----------------------------------------------------------

//         slave_release(0);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // TC03
//         //
//         // MULTIPLE SLAVES ASSERT IRQ
//         //----------------------------------------------------------

//         testcase("TC03 - MULTIPLE SLAVES INTERRUPT");

//         /*
//          * SLV0 priority = 1
//          * SLV1 priority = 3
//          * SLV2 priority = 5
//          * SLV3 priority = 7
//          */

//         slave_irq(0);
//         slave_irq(1);
//         slave_irq(2);
//         slave_irq(3);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Expected first slave = SLV3
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> EXPECTED FIRST SLAVE = SLV3"
//         );

//         master_ack;

//         wait_clk(2);


//         //----------------------------------------------------------
//         // IMPORTANT:
//         //
//         // SLV3 remains HIGH.
//         // Controller must continue serving SLV3.
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> SLV3 IRQ STILL HIGH"
//         );

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Release SLV3
//         //----------------------------------------------------------

//         slave_release(3);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Now SLV2 should be selected
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> EXPECTED NEXT SLAVE = SLV2"
//         );

//         master_ack;

//         wait_clk(2);


//         //----------------------------------------------------------
//         // Release SLV2
//         //----------------------------------------------------------

//         slave_release(2);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV1 should be selected
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> EXPECTED NEXT SLAVE = SLV1"
//         );

//         master_ack;

//         wait_clk(2);

//         slave_release(1);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV0 should be selected
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> EXPECTED NEXT SLAVE = SLV0"
//         );

//         master_ack;

//         wait_clk(2);

//         slave_release(0);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // TC04
//         //
//         // NEW IRQ ARRIVES WHILE CURRENT IRQ IS BEING SERVED
//         //----------------------------------------------------------

//         testcase(
//             "TC04 - NEW IRQ ARRIVES WHILE CURRENT IRQ ACTIVE"
//         );

//         //----------------------------------------------------------
//         // SLV0 starts first
//         //----------------------------------------------------------

//         slave_irq(0);

//         wait_clk(2);

//         master_ack;

//         wait_clk(2);


//         //----------------------------------------------------------
//         // SLV3 generates a new IRQ
//         //----------------------------------------------------------

//         slave_irq(3);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV0 MUST STILL BE THE CURRENT SERVICE
//         //
//         // because irq_i[0] is still HIGH.
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> SLV0 STILL ACTIVE"
//         );

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Release SLV0
//         //----------------------------------------------------------

//         slave_release(0);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Now SLV3 can be serviced
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> SLV0 RELEASED"
//         );

//         wait_clk(2);

//         master_ack;

//         wait_clk(2);

//         slave_release(3);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // TC05
//         //
//         // IRQ ENABLE
//         //----------------------------------------------------------

//         testcase("TC05 - INTERRUPT ENABLE");

//         /*
//          * SLV1 generates IRQ but is disabled.
//          */

//         @(negedge clk_i);

//         irq_en_i[1] = 1'b0;
//         irq_i[1]    = 1'b1;

//         wait_clk(3);


//         //----------------------------------------------------------
//         // No interrupt should be sent to master
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> SLV1 IRQ IS ACTIVE BUT IRQ ENABLE IS 0"
//         );

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Enable SLV1
//         //----------------------------------------------------------

//         @(negedge clk_i);

//         irq_en_i[1] = 1'b1;

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Now controller should service SLV1
//         //----------------------------------------------------------

//         master_ack;

//         wait_clk(2);

//         slave_release(1);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // TC06
//         //
//         // ACK DOES NOT CLEAR LEVEL INTERRUPT
//         //----------------------------------------------------------

//         testcase(
//             "TC06 - ACK DOES NOT CLEAR LEVEL INTERRUPT"
//         );

//         slave_irq(2);

//         wait_clk(3);

//         master_ack;

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Keep IRQ2 HIGH
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> SLV2 IRQ IS STILL HIGH AFTER ACK"
//         );

//         wait_clk(5);


//         //----------------------------------------------------------
//         // Release SLV2
//         //----------------------------------------------------------

//         slave_release(2);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // TC07
//         //
//         // TWO SLAVES ACTIVE, CURRENT ONE DOES NOT RELEASE
//         //----------------------------------------------------------

//         testcase(
//             "TC07 - CURRENT SLAVE HOLDS INTERRUPT"
//         );

//         slave_irq(0);

//         wait_clk(2);

//         master_ack;

//         wait_clk(2);


//         //----------------------------------------------------------
//         // SLV1 also requests
//         //----------------------------------------------------------

//         slave_irq(1);

//         wait_clk(4);


//         //----------------------------------------------------------
//         // Controller must NOT switch to SLV1 yet
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> SLV0 STILL HOLDS IRQ"
//         );

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Release SLV0
//         //----------------------------------------------------------

//         slave_release(0);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Now SLV1 can be serviced
//         //----------------------------------------------------------

//         master_ack;

//         wait_clk(2);

//         slave_release(1);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // TC08
//         //
//         // ALL SLAVES ACTIVE
//         //----------------------------------------------------------

//         testcase("TC08 - ALL SLAVES ACTIVE");

//         irq_i = 4'b1111;

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Highest priority should be selected first
//         //----------------------------------------------------------

//         master_ack;

//         wait_clk(2);

//         slave_release(3);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV2
//         //----------------------------------------------------------

//         master_ack;

//         wait_clk(2);

//         slave_release(2);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV1
//         //----------------------------------------------------------

//         master_ack;

//         wait_clk(2);

//         slave_release(1);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV0
//         //----------------------------------------------------------

//         master_ack;

//         wait_clk(2);

//         slave_release(0);

//         wait_clk(4);


//         //----------------------------------------------------------
//         // TC09
//         //
//         // DISABLED HIGH-PRIORITY SLAVE
//         //----------------------------------------------------------

//         testcase(
//             "TC09 - HIGH PRIORITY SLAVE DISABLED"
//         );

//         /*
//          * SLV3 has highest priority but is disabled.
//          */

//         irq_en_i = 4'b0111;

//         irq_i = 4'b1111;

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV3 must NOT be selected
//         //----------------------------------------------------------

//         $display("");
//         $display(
//             ">>> SLV3 IS DISABLED"
//         );

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Re-enable SLV3
//         //----------------------------------------------------------

//         @(negedge clk_i);

//         irq_en_i = 4'b1111;

//         wait_clk(3);


//         //----------------------------------------------------------
//         // SLV3 should now be selected
//         //----------------------------------------------------------

//         master_ack;

//         wait_clk(2);

//         slave_release(3);

//         wait_clk(3);


//         //----------------------------------------------------------
//         // Clear all
//         //----------------------------------------------------------

//         irq_i = 4'b0000;

//         wait_clk(4);


//         //----------------------------------------------------------
//         // TC10
//         //
//         // LEVEL INTERRUPT SEQUENCE
//         //----------------------------------------------------------

//         testcase(
//             "TC10 - COMPLETE LEVEL INTERRUPT SEQUENCE"
//         );

//         /*
//          * This testcase explicitly demonstrates:
//          *
//          * IRQ ASSERT
//          *      ?
//          * Controller selects slave
//          *      ?
//          * irq_o = 1
//          * irq_id_o = slave ID
//          *      ?
//          * Master ACK
//          *      ?
//          * Controller waits
//          *      ?
//          * Slave IRQ still 1
//          *      ?
//          * Controller STILL waits
//          *      ?
//          * Slave IRQ becomes 0
//          *      ?
//          * Controller can arbitrate again
//          */

//         slave_irq(2);

//         wait_clk(3);

//         master_ack;

//         wait_clk(5);

//         slave_release(2);

//         wait_clk(5);


//         //----------------------------------------------------------
//         // END
//         //----------------------------------------------------------

//         $display("");
//         $display("");
//         $display(
//             "############################################################"
//         );

//         $display(
//             "# ALL TESTCASES FINISHED"
//         );

//         $display(
//             "############################################################"
//         );

//         $finish;

//     end

// endmodule

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

    task check(input cond, input [400*8-1:0] msg);
    begin
        if (cond) begin
            pass_cnt = pass_cnt + 1;
            $display("[PASS] t=%0t : %s", $time, msg);
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("[FAIL] t=%0t : %s", $time, msg);
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
        $display("--- TC1: Single slave interrupt ---");
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

        //=========================================================
        // TC2: irq_en_i mask - slave bi disable khong duoc phuc vu
        //=========================================================
        $display("--- TC2: irq_en_i mask ---");
        irq_en_i = 4'b1101; // slave 1 bi disable
        raise_irq(1);
        repeat (20) @(posedge clk_i);
        check(irq_o === 1'b0, "TC2: slave 1 bi disable (irq_en_i[1]=0) khong duoc phuc vu");
        lower_irq(1);
        irq_en_i = 4'b1111;
        @(posedge clk_i);

        //=========================================================
        // TC3: Nhieu slave cung yeu cau, khac priority
        //      -> chon slave co priority cao nhat truoc
        //=========================================================
        $display("--- TC3: Multiple slaves, different priority ---");
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

        //=========================================================
        // TC4: Cac slave co cung priority -> round robin
        //      (chi kiem tra cong bang qua nhieu vong)
        //=========================================================
        $display("--- TC4: Round-robin fairness (same priority) ---");
        begin
            integer serve_count [0:SLV_AMT-1];
            integer round;
            for (i = 0; i < SLV_AMT; i = i + 1) begin
                set_priority(i, 3'd4);
                serve_count[i] = 0;
            end

            for (round = 0; round < 20; round = round + 1) begin
                irq_i = 4'b1111; // tat ca 4 slave cung yeu cau 1 luc
                wait_irq_assert(got_id, timeout);
                if (!timeout) serve_count[got_id] = serve_count[got_id] + 1;
                do_ack;
                irq_i[got_id] = 1'b0;
                repeat (3) @(posedge clk_i);
            end

            $display("Serve count sau 20 vong: slv0=%0d slv1=%0d slv2=%0d slv3=%0d",
                       serve_count[0], serve_count[1], serve_count[2], serve_count[3]);

            check(serve_count[0] > 0 && serve_count[1] > 0 &&
                  serve_count[2] > 0 && serve_count[3] > 0,
                  "TC4: khong slave nao bi doi (starvation) khi cung priority");
        end
        irq_i = 4'b0000;
        repeat (5) @(posedge clk_i);

        //=========================================================
        // TC5: Slave phat interrupt tro lai ngay sau khi vua duoc
        //      xu ly xong (back-to-back)
        //=========================================================
        $display("--- TC5: Back-to-back interrupt tren cung 1 slave ---");
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
        repeat (5) @(posedge clk_i);

        //=========================================================
        // TC6: Slave khac phat irq trong luc controller dang xu ly
        //      1 slave khac (phai doi den luot)
        //=========================================================
        $display("--- TC6: Interrupt moi den trong luc dang xu ly slave khac ---");
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
        repeat (5) @(posedge clk_i);

        //=========================================================
        // TC7: Slave ha irq_i truoc khi master kip ack
        //=========================================================
        $display("--- TC7: Slave ha irq_i som (truoc ack) ---");
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