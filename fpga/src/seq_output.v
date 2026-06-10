//l3
module seq_output #(
    parameter N_IN = 256, parameter N_OUT = 10,
    parameter MEMFILE = "../weights/hw/layer3_weights_flat.mem"
)(
    input clk, rst, start,
    input [N_IN-1:0] in_bits,
    output reg [3:0] digit,
    output reg done

);

    wire w_bit;
    reg  [3:0] neuron;                       // which output neuron (0..9)
    reg  [$clog2(N_IN)-1:0] index;           // input index
    weight_mem #(.N_IN(N_IN), .N_OUT(N_OUT), .MEMFILE(MEMFILE)) wm
        (.clk(clk), .neuron(neuron), .idx(index), .w_bit(w_bit));

    reg signed [9:0] acc;          // score accumulator: +1 agree, -1 disagree
    reg [$clog2(N_IN):0] seen;
    reg in_bit_d;
    reg signed [9:0] best_val;     // best score so far
    reg [3:0] best_idx;

    localparam IDLE=0, PRIME=1, COUNT=2, NEXTN=3;
    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state<=IDLE; done<=0; neuron<=0; index<=0; acc<=0; seen<=0;
            best_val<=-512; best_idx<=0;
        end else case (state)
            IDLE: begin
                done<=0;
                if (start) begin
                    neuron<=0; index<=0; best_val<=-512; best_idx<=0;
                    state<=PRIME;
                end
            end
            PRIME: begin
                // this cycle presents addr = neuron*N_IN + 0 (index==0),
                // so next cycle w_bit = mem[neuron,0]. prime the pipeline.
                index<=1; acc<=0; seen<=0;
                in_bit_d<=in_bits[0];
                state<=COUNT;
            end
            COUNT: begin
                if (seen == N_IN-1) begin
                    // last bit: finalize this neuron's score, compare for argmax
                    if ((acc + ((in_bit_d==w_bit)?1:-1)) > best_val) begin
                        best_val <= acc + ((in_bit_d==w_bit)?1:-1);
                        best_idx <= neuron;
                    end
                    state <= NEXTN;
                end else begin
                    // weight for in_bit_d's index is valid now
                    if (in_bit_d == w_bit) acc <= acc + 1; else acc <= acc - 1;
                    seen <= seen + 1;
                    in_bit_d <= in_bits[index];
                    if (index < N_IN-1) index <= index + 1;
                end
            end
            NEXTN: begin
                if (neuron == N_OUT-1) begin
                    digit <= best_idx; done <= 1; state <= IDLE;
                end else begin
                    neuron <= neuron + 1; index <= 0; //re-prime for next neuron
                    state <= PRIME;
                end
            end
        endcase
    end
endmodule
