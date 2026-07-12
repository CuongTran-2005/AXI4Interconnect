`timescale 1ns / 1ps

module round_robin_arbiter #(
    parameter NUM_MASTERS = 4,
    parameter ID_WIDTH    = 2  // Must be large enough to hold NUM_MASTERS-1 (e.g., clog2(NUM_MASTERS))
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [NUM_MASTERS-1:0] ax_req,       // Request vector from masters
    input  wire                   ax_handshake, // Active when slave accepts request
    output reg  [ID_WIDTH-1:0]    Master_id_ax, // The winning master ID
    output wire                   fifo_write    // Triggers FIFO write
);

    // -------------------------------------------------------------------------
    // Internal State
    // -------------------------------------------------------------------------
    // Keeps track of which master was granted access last
    reg [ID_WIDTH-1:0] last_grant;
    reg [ID_WIDTH-1:0] next_grant;
    
    integer i, idx;
    reg grant_found;

    // -------------------------------------------------------------------------
    // Combinational Round-Robin Logic
    // -------------------------------------------------------------------------
    always @(*) begin
        // Default assignments to prevent latches
        next_grant   = last_grant; 
        Master_id_ax = last_grant; 
        grant_found  = 1'b0;

        // Start checking for requests starting at the master AFTER the last grant.
        // We iterate NUM_MASTERS times to check every possible master exactly once.
        for (i = 1; i <= NUM_MASTERS; i = i + 1) begin
            if (!grant_found) begin
                // Wrap around logic using modulo. 
                // (e.g., if last_grant=3 and i=1, (3+1)%4 = 0)
                idx = (last_grant + i) % NUM_MASTERS;
                
                if (ax_req[idx]) begin
                    Master_id_ax = idx[ID_WIDTH-1:0];
                    next_grant   = idx[ID_WIDTH-1:0];
                    grant_found  = 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Update Round-Robin State
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Default to master 0 on reset
            last_grant <= {ID_WIDTH{1'b0}};
        end else begin
            // Only move the round-robin pointer if a transaction was successfully
            // acknowledged by the slave (ax_handshake is high)
            if (ax_handshake && grant_found) begin
                last_grant <= next_grant;
            end
        end
    end

    // -------------------------------------------------------------------------
    // FIFO Write Request Logic
    // -------------------------------------------------------------------------
    // As requested, this pulls high in the exact same cycle the slave 
    // acknowledges the data beat.
    assign fifo_write = ax_handshake;

endmodule