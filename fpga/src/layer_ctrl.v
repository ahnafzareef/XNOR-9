//layer controler, fsm
//drive seq_neuron for all neurons in n_out
//get weights from weight_meme, collect the outputs

module layer_ctrl #(
    parameter N_IN = 784,
    parameter N_OUT = 256,
    parameter MEMFILE = "../weights/hw/layer1_weights.mem",
    parameter THFILE = "../weights/hw/layer1_threshold.hex"
)(
    input clk,
    input rst,
    input start, //start signal for layer ctrl, from top level
    input [N_IN-1:0] in_bits, //input bits for layer
    output reg [N_OUT-1:0] out_bits, //output bits for layer
    output reg done 
);

    reg [9:0] thresh [0:N_OUT-1];

    initial $readmemh(THFILE, thresh);

    //load weight
    wire w_bit;
    reg [$clog2(N_OUT)-1:0] neuron; //neuron index for weight mem
    wire [$clog2(N_IN)-1:0] index; //index for weight mem
    
    weight_mem #(
        .N_IN(N_IN),
        .N_OUT(N_OUT),
        .MEMFILE(MEMFILE)
    ) wm (
        .clk(clk),
        .neuron(neuron),
        .idx(index),
        .w_bit(w_bit)
    );

    //neuron
    reg n_start; //start signal for neuron
    wire n_busy, n_done, n_fire;
    reg in_bit_r; //register to hold input bit for neuron

    seq_neuron #(
        .N_IN(N_IN)
    ) neuron_inst (
     .clk(clk),
     .rst(rst),
     .start(n_start),
     .in_bit(in_bit_r),
     .w_bit(w_bit),
     .threshold(thresh[neuron]),
     .index(index),
     .busy(n_busy),
     .done(n_done),
     .fire(n_fire)
    );

    //feed bit
    always @(*) in_bit_r = in_bits[index];

    //fsm
    localparam IDLE = 0, START_N = 1, COUNT=2, NEXT = 3, DONE = 4;
    reg [2:0] state; //state of fsm

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; done <= 0; n_start <= 0; neuron <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <=0;
                    if (start) begin
                        neuron <= 0;
                        state <= START_N;
                    end
                end
                START_N: begin
                    n_start <= 1;
                    state <= COUNT; //count now
                end
                COUNT: begin
                    n_start <=0; //no start new neuron
                    if (n_done) begin
                        out_bits[neuron] <= n_fire; //in the index of this neuron store result
                        state <= NEXT; 
                    end
                end
                NEXT: begin
                    if (neuron == N_OUT-1) begin
                        state <= DONE;
                    end else begin
                        neuron <= neuron + 1; //next one
                        state <= START_N;
                    end
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
