module qos_request_mask #(
    parameter REQUESTER_NUM = 4,
    parameter QOS_WIDTH     = 4
)(
    input  wire [REQUESTER_NUM-1:0] request,

    input  wire [REQUESTER_NUM*QOS_WIDTH-1:0] qos,

    output reg  [REQUESTER_NUM-1:0] masked_request,

    output reg  [QOS_WIDTH-1:0] highest_qos
);

integer i;

reg [QOS_WIDTH-1:0] qos_value;

always @(*) begin

    //--------------------------------------------------------
    // Find highest QoS among active requests
    //--------------------------------------------------------

    highest_qos = {QOS_WIDTH{1'b0}};

    for(i=0;i<REQUESTER_NUM;i=i+1) begin

        qos_value = qos[i*QOS_WIDTH +: QOS_WIDTH];

        if(request[i] && (qos_value > highest_qos))
            highest_qos = qos_value;

    end

    //--------------------------------------------------------
    // Generate request mask
    //--------------------------------------------------------

    masked_request = {REQUESTER_NUM{1'b0}};

    for(i=0;i<REQUESTER_NUM;i=i+1) begin

        qos_value = qos[i*QOS_WIDTH +: QOS_WIDTH];

        if(request[i] && (qos_value == highest_qos))
            masked_request[i] = 1'b1;

    end

end

endmodule