//tl for l1 l2
//runs l1, feeds output to l2. shows h2 for l3

module bnn_seq (
    input clk,
    input rst,

    input start,
    input [783:0] image,
    output [255:0] h2_out,
    output [3:0] digit,
    output reg done
);

// layer 1
reg l1_start;
wire [255:0] h1;
wire l1_done;
layer_ctrl #(.N_IN(784), .N_OUT(256), 
    .MEMFILE("../weights/hw/layer1_weights_flat.mem"),
    .THFILE ("../weights/hw/layer1_threshold.hex")) L1 (
    .clk(clk),
    .rst(rst),
    .start(l1_start),
    .in_bits(image),
    .out_bits(h1),
    .done(l1_done)
    );

    // layer 2
    reg l2_start;
    wire [255:0] h2;
    wire l2_done;
    layer_ctrl #(.N_IN(256), .N_OUT(256),
        .MEMFILE("../weights/hw/layer2_weights_flat.mem"),
        .THFILE ("../weights/hw/layer2_threshold.hex")) L2 (
        .clk(clk), .rst(rst), .start(l2_start),
        .in_bits(h1), .out_bits(h2), .done(l2_done)
    );

    assign h2_out = h2;

    //l3 
    reg l3_start;
    wire [3:0] digit_w;
    wire l3_done;
    seq_output #(.N_IN(256), .N_OUT(10),
        .MEMFILE("../weights/hw/layer3_weights_flat.mem")) L3 (
        .clk(clk), .rst(rst), .start(l3_start),
        .in_bits(h2), .digit(digit_w), .done(l3_done)
    );

    assign digit = digit_w;

    //top level fsm
    localparam IDLE = 0, RUN_L1 = 1, WAIT_L1 = 2, SETTLE = 3, RUN_L2 = 4, WAIT_L2 = 5, SETTLE2 = 6, RUN_L3 = 7, WAIT_L3 = 8, DONE = 9;
    reg [3:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            l1_start <= 0;
            l2_start <= 0;
            l3_start <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) state <= RUN_L1;
                end
                RUN_L1: begin
                    l1_start <= 1;
                    state <= WAIT_L1;
                end
                WAIT_L1: begin
                    l1_start <= 0;
                    if (l1_done) state <= SETTLE;
                end
                SETTLE: begin
                    //wait a cycle for handoff
                    state <= RUN_L2;
                end
                RUN_L2: begin
                    l2_start <= 1;
                    state <= WAIT_L2;
                end
                WAIT_L2: begin
                    l2_start <= 0;
                    if (l2_done) state <= SETTLE2;
                end
                SETTLE2: begin
                    //wait a cycle for handoff
                    state <= RUN_L3;
                end
                RUN_L3: begin
                    l3_start <= 1;
                    state <= WAIT_L3;
                end
                WAIT_L3: begin
                    l3_start <= 0;
                    if (l3_done) state <= DONE;
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

    
