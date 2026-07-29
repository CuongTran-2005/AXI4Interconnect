`timescale 1ns/1ps

module tb_interrupt_controller;

    //--------------------------------------------------------------
    // PARAMETERS
    //--------------------------------------------------------------
    parameter SLV_AMT    = 4;
    parameter SLV_ID_W   = (SLV_AMT > 1) ? $clog2(SLV_AMT) : 1;
    parameter PRIORITY_W = 3;

    parameter CLK_PERIOD = 10;


    //--------------------------------------------------------------
    // DUT INPUT
    //--------------------------------------------------------------
    reg                             clk_i;
    reg                             rst_n_i;

    reg [SLV_AMT-1:0]               irq_i;

    reg [SLV_AMT-1:0]               irq_en_i;

    reg [SLV_AMT*PRIORITY_W-1:0]    priority_i;

    reg                             irq_ack_i;


    //--------------------------------------------------------------
    // DUT OUTPUT
    //--------------------------------------------------------------
    wire                            irq_o;
    wire [SLV_ID_W-1:0]             irq_id_o;


    //--------------------------------------------------------------
    // DUT
    //--------------------------------------------------------------
    interrupt_controller #(
        .SLV_AMT    (SLV_AMT),
        .SLV_ID_W   (SLV_ID_W),
        .PRIORITY_W (PRIORITY_W)
    )
    dut (
        .clk_i       (clk_i),
        .rst_n_i     (rst_n_i),

        .irq_i       (irq_i),

        .irq_en_i    (irq_en_i),
        .priority_i  (priority_i),

        .irq_ack_i   (irq_ack_i),

        .irq_o       (irq_o),
        .irq_id_o    (irq_id_o)
    );


    //--------------------------------------------------------------
    // CLOCK
    //--------------------------------------------------------------
    initial begin
        clk_i = 1'b0;

        forever #(CLK_PERIOD/2)
            clk_i = ~clk_i;
    end


    //--------------------------------------------------------------
    // MONITOR
    //--------------------------------------------------------------
    always @(posedge clk_i) begin

        $display("");
        $display(
            "=============================================================="
        );

        $display(
            "[TIME %0t] INPUT",
            $time
        );

        $display(
            "  rst_n_i   = %b",
            rst_n_i
        );

        $display(
            "  irq_i     = %b",
            irq_i
        );

        $display(
            "  irq_en_i  = %b",
            irq_en_i
        );

        $display(
            "  irq_ack_i = %b",
            irq_ack_i
        );

        $display(
            "  PRIORITY  : SLV0=%0d | SLV1=%0d | SLV2=%0d | SLV3=%0d",
            priority_i[0*PRIORITY_W +: PRIORITY_W],
            priority_i[1*PRIORITY_W +: PRIORITY_W],
            priority_i[2*PRIORITY_W +: PRIORITY_W],
            priority_i[3*PRIORITY_W +: PRIORITY_W]
        );

        $display(
            "[TIME %0t] OUTPUT",
            $time
        );

        $display(
            "  irq_o     = %b",
            irq_o
        );

        $display(
            "  irq_id_o  = %0d",
            irq_id_o
        );

        if (irq_o) begin

            $display(
                "  >>> CONTROLLER IS SERVING SLAVE %0d",
                irq_id_o
            );

        end
        else begin

            $display(
                "  >>> CONTROLLER IS NOT SERVING ANY SLAVE"
            );

        end

    end


    //--------------------------------------------------------------
    // TASK: SET PRIORITY
    //--------------------------------------------------------------
    task set_priority;
        input integer slv;
        input [PRIORITY_W-1:0] priority_value;

        begin

            priority_i[
                slv*PRIORITY_W +: PRIORITY_W
            ] = priority_value;

        end

    endtask


    //--------------------------------------------------------------
    // TASK: WAIT CLOCK
    //--------------------------------------------------------------
    task wait_clk;
        input integer n;

        begin

            repeat(n)
                @(posedge clk_i);

        end

    endtask


    //--------------------------------------------------------------
    // TASK: MASTER ACK
    //--------------------------------------------------------------
    task master_ack;

        begin

            $display("");
            $display(
                ">>> MASTER: received IRQ from SLAVE %0d",
                irq_id_o
            );

            @(negedge clk_i);

            irq_ack_i = 1'b1;

            $display(
                ">>> MASTER: irq_ack_i = 1"
            );

            @(negedge clk_i);

            irq_ack_i = 1'b0;

            $display(
                ">>> MASTER: irq_ack_i = 0"
            );

        end

    endtask


    //--------------------------------------------------------------
    // TASK: SLAVE RELEASE INTERRUPT
    //--------------------------------------------------------------
    task slave_release;
        input integer slv;

        begin

            @(negedge clk_i);

            irq_i[slv] = 1'b0;

            $display("");
            $display(
                ">>> SLAVE %0d: IRQ RELEASED -> irq_i[%0d] = 0",
                slv,
                slv
            );

        end

    endtask


    //--------------------------------------------------------------
    // TASK: SLAVE ASSERT INTERRUPT
    //--------------------------------------------------------------
    task slave_irq;
        input integer slv;

        begin

            @(negedge clk_i);

            irq_i[slv] = 1'b1;

            $display("");
            $display(
                ">>> SLAVE %0d: IRQ ASSERTED -> irq_i[%0d] = 1",
                slv,
                slv
            );

        end

    endtask


    //--------------------------------------------------------------
    // TASK: TESTCASE HEADER
    //--------------------------------------------------------------
    task testcase;
        input [200*8:1] name;

        begin

            $display("");
            $display("");
            $display("############################################################");
            $display("# %s", name);
            $display("############################################################");

        end

    endtask


    //--------------------------------------------------------------
    // INITIAL TEST
    //--------------------------------------------------------------
    initial begin

        //----------------------------------------------------------
        // INITIAL VALUES
        //----------------------------------------------------------

        rst_n_i   = 1'b0;

        irq_i     = 4'b0000;

        irq_en_i  = 4'b1111;

        irq_ack_i = 1'b0;

        priority_i = {SLV_AMT*PRIORITY_W{1'b0}};


        //----------------------------------------------------------
        // PRIORITY
        //----------------------------------------------------------
        //
        // SLV0 = 1
        // SLV1 = 3
        // SLV2 = 5
        // SLV3 = 7
        //
        //----------------------------------------------------------

        set_priority(0, 3'd1);
        set_priority(1, 3'd3);
        set_priority(2, 3'd5);
        set_priority(3, 3'd7);


        //----------------------------------------------------------
        // TC01
        //----------------------------------------------------------

        testcase("TC01 - RESET");

        wait_clk(3);


        //----------------------------------------------------------
        // RELEASE RESET
        //----------------------------------------------------------

        @(negedge clk_i);

        rst_n_i = 1'b1;

        wait_clk(2);


        //----------------------------------------------------------
        // TC02
        //
        // SLV0 ASSERT IRQ
        //----------------------------------------------------------

        testcase("TC02 - SINGLE SLAVE INTERRUPT");

        slave_irq(0);

        wait_clk(2);

        /*
         * Expected:
         *
         * irq_o    = 1
         * irq_id_o = 0
         */

        master_ack;

        wait_clk(2);


        //----------------------------------------------------------
        // IMPORTANT:
        //
        // IRQ FROM SLV0 IS STILL HIGH.
        //
        // Controller must NOT move to another slave.
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> CHECK: SLV0 IRQ IS STILL HIGH"
        );

        wait_clk(3);


        //----------------------------------------------------------
        // SLV0 RELEASES IRQ
        //----------------------------------------------------------

        slave_release(0);

        wait_clk(3);


        //----------------------------------------------------------
        // TC03
        //
        // MULTIPLE SLAVES ASSERT IRQ
        //----------------------------------------------------------

        testcase("TC03 - MULTIPLE SLAVES INTERRUPT");

        /*
         * SLV0 priority = 1
         * SLV1 priority = 3
         * SLV2 priority = 5
         * SLV3 priority = 7
         */

        slave_irq(0);
        slave_irq(1);
        slave_irq(2);
        slave_irq(3);

        wait_clk(3);


        //----------------------------------------------------------
        // Expected first slave = SLV3
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> EXPECTED FIRST SLAVE = SLV3"
        );

        master_ack;

        wait_clk(2);


        //----------------------------------------------------------
        // IMPORTANT:
        //
        // SLV3 remains HIGH.
        // Controller must continue serving SLV3.
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> SLV3 IRQ STILL HIGH"
        );

        wait_clk(3);


        //----------------------------------------------------------
        // Release SLV3
        //----------------------------------------------------------

        slave_release(3);

        wait_clk(3);


        //----------------------------------------------------------
        // Now SLV2 should be selected
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> EXPECTED NEXT SLAVE = SLV2"
        );

        master_ack;

        wait_clk(2);


        //----------------------------------------------------------
        // Release SLV2
        //----------------------------------------------------------

        slave_release(2);

        wait_clk(3);


        //----------------------------------------------------------
        // SLV1 should be selected
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> EXPECTED NEXT SLAVE = SLV1"
        );

        master_ack;

        wait_clk(2);

        slave_release(1);

        wait_clk(3);


        //----------------------------------------------------------
        // SLV0 should be selected
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> EXPECTED NEXT SLAVE = SLV0"
        );

        master_ack;

        wait_clk(2);

        slave_release(0);

        wait_clk(3);


        //----------------------------------------------------------
        // TC04
        //
        // NEW IRQ ARRIVES WHILE CURRENT IRQ IS BEING SERVED
        //----------------------------------------------------------

        testcase(
            "TC04 - NEW IRQ ARRIVES WHILE CURRENT IRQ ACTIVE"
        );

        //----------------------------------------------------------
        // SLV0 starts first
        //----------------------------------------------------------

        slave_irq(0);

        wait_clk(2);

        master_ack;

        wait_clk(2);


        //----------------------------------------------------------
        // SLV3 generates a new IRQ
        //----------------------------------------------------------

        slave_irq(3);

        wait_clk(3);


        //----------------------------------------------------------
        // SLV0 MUST STILL BE THE CURRENT SERVICE
        //
        // because irq_i[0] is still HIGH.
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> SLV0 STILL ACTIVE"
        );

        wait_clk(3);


        //----------------------------------------------------------
        // Release SLV0
        //----------------------------------------------------------

        slave_release(0);

        wait_clk(3);


        //----------------------------------------------------------
        // Now SLV3 can be serviced
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> SLV0 RELEASED"
        );

        wait_clk(2);

        master_ack;

        wait_clk(2);

        slave_release(3);

        wait_clk(3);


        //----------------------------------------------------------
        // TC05
        //
        // IRQ ENABLE
        //----------------------------------------------------------

        testcase("TC05 - INTERRUPT ENABLE");

        /*
         * SLV1 generates IRQ but is disabled.
         */

        @(negedge clk_i);

        irq_en_i[1] = 1'b0;
        irq_i[1]    = 1'b1;

        wait_clk(3);


        //----------------------------------------------------------
        // No interrupt should be sent to master
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> SLV1 IRQ IS ACTIVE BUT IRQ ENABLE IS 0"
        );

        wait_clk(3);


        //----------------------------------------------------------
        // Enable SLV1
        //----------------------------------------------------------

        @(negedge clk_i);

        irq_en_i[1] = 1'b1;

        wait_clk(3);


        //----------------------------------------------------------
        // Now controller should service SLV1
        //----------------------------------------------------------

        master_ack;

        wait_clk(2);

        slave_release(1);

        wait_clk(3);


        //----------------------------------------------------------
        // TC06
        //
        // ACK DOES NOT CLEAR LEVEL INTERRUPT
        //----------------------------------------------------------

        testcase(
            "TC06 - ACK DOES NOT CLEAR LEVEL INTERRUPT"
        );

        slave_irq(2);

        wait_clk(3);

        master_ack;

        wait_clk(3);


        //----------------------------------------------------------
        // Keep IRQ2 HIGH
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> SLV2 IRQ IS STILL HIGH AFTER ACK"
        );

        wait_clk(5);


        //----------------------------------------------------------
        // Release SLV2
        //----------------------------------------------------------

        slave_release(2);

        wait_clk(3);


        //----------------------------------------------------------
        // TC07
        //
        // TWO SLAVES ACTIVE, CURRENT ONE DOES NOT RELEASE
        //----------------------------------------------------------

        testcase(
            "TC07 - CURRENT SLAVE HOLDS INTERRUPT"
        );

        slave_irq(0);

        wait_clk(2);

        master_ack;

        wait_clk(2);


        //----------------------------------------------------------
        // SLV1 also requests
        //----------------------------------------------------------

        slave_irq(1);

        wait_clk(4);


        //----------------------------------------------------------
        // Controller must NOT switch to SLV1 yet
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> SLV0 STILL HOLDS IRQ"
        );

        wait_clk(3);


        //----------------------------------------------------------
        // Release SLV0
        //----------------------------------------------------------

        slave_release(0);

        wait_clk(3);


        //----------------------------------------------------------
        // Now SLV1 can be serviced
        //----------------------------------------------------------

        master_ack;

        wait_clk(2);

        slave_release(1);

        wait_clk(3);


        //----------------------------------------------------------
        // TC08
        //
        // ALL SLAVES ACTIVE
        //----------------------------------------------------------

        testcase("TC08 - ALL SLAVES ACTIVE");

        irq_i = 4'b1111;

        wait_clk(3);


        //----------------------------------------------------------
        // Highest priority should be selected first
        //----------------------------------------------------------

        master_ack;

        wait_clk(2);

        slave_release(3);

        wait_clk(3);


        //----------------------------------------------------------
        // SLV2
        //----------------------------------------------------------

        master_ack;

        wait_clk(2);

        slave_release(2);

        wait_clk(3);


        //----------------------------------------------------------
        // SLV1
        //----------------------------------------------------------

        master_ack;

        wait_clk(2);

        slave_release(1);

        wait_clk(3);


        //----------------------------------------------------------
        // SLV0
        //----------------------------------------------------------

        master_ack;

        wait_clk(2);

        slave_release(0);

        wait_clk(4);


        //----------------------------------------------------------
        // TC09
        //
        // DISABLED HIGH-PRIORITY SLAVE
        //----------------------------------------------------------

        testcase(
            "TC09 - HIGH PRIORITY SLAVE DISABLED"
        );

        /*
         * SLV3 has highest priority but is disabled.
         */

        irq_en_i = 4'b0111;

        irq_i = 4'b1111;

        wait_clk(3);


        //----------------------------------------------------------
        // SLV3 must NOT be selected
        //----------------------------------------------------------

        $display("");
        $display(
            ">>> SLV3 IS DISABLED"
        );

        wait_clk(3);


        //----------------------------------------------------------
        // Re-enable SLV3
        //----------------------------------------------------------

        @(negedge clk_i);

        irq_en_i = 4'b1111;

        wait_clk(3);


        //----------------------------------------------------------
        // SLV3 should now be selected
        //----------------------------------------------------------

        master_ack;

        wait_clk(2);

        slave_release(3);

        wait_clk(3);


        //----------------------------------------------------------
        // Clear all
        //----------------------------------------------------------

        irq_i = 4'b0000;

        wait_clk(4);


        //----------------------------------------------------------
        // TC10
        //
        // LEVEL INTERRUPT SEQUENCE
        //----------------------------------------------------------

        testcase(
            "TC10 - COMPLETE LEVEL INTERRUPT SEQUENCE"
        );

        /*
         * This testcase explicitly demonstrates:
         *
         * IRQ ASSERT
         *      ?
         * Controller selects slave
         *      ?
         * irq_o = 1
         * irq_id_o = slave ID
         *      ?
         * Master ACK
         *      ?
         * Controller waits
         *      ?
         * Slave IRQ still 1
         *      ?
         * Controller STILL waits
         *      ?
         * Slave IRQ becomes 0
         *      ?
         * Controller can arbitrate again
         */

        slave_irq(2);

        wait_clk(3);

        master_ack;

        wait_clk(5);

        slave_release(2);

        wait_clk(5);


        //----------------------------------------------------------
        // END
        //----------------------------------------------------------

        $display("");
        $display("");
        $display(
            "############################################################"
        );

        $display(
            "# ALL TESTCASES FINISHED"
        );

        $display(
            "############################################################"
        );

        $finish;

    end

endmodule