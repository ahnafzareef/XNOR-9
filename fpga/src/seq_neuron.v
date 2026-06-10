//compute popcount of one input per clk and add

module seq_neuron #(

    parameter N_IN = 784

)(

    input clk,
    input rst,
    input start,
    input in_bit, //input bit
    input w_bit, //weight bit 

    input [9:0] threshold, //thresh is done at the end.

    //the input file is just 784 digits, and we read one at a time, need a tracker
    output reg [$clog2(N_IN)-1:0] index, 
    output reg busy,
    output reg done,
    output reg fire
);

    reg [9:0] acc; //accumulator for popcount
    reg  in_bit_d;    //because of bram 1 cycle delay         
    reg [$clog2(N_IN):0] seen;     

   
    always @(posedge clk) begin
        if (rst) begin
            acc <= 0; index <= 0; busy <= 0; done <= 0; fire <= 0; seen <= 0;
        end else if (start) begin
            acc <= 0; index <= 1; busy <= 1; done <= 0; seen <= 0;
            in_bit_d <= in_bit;       
        end else if (busy) begin
            if (in_bit_d == w_bit) acc <= acc + 1;
            seen <= seen + 1;

            in_bit_d <= in_bit;      
            if (index < N_IN-1) index <= index + 1;

            if (seen == N_IN-1) begin 
                busy <= 0; done <= 1;
                fire <= ((acc + ((in_bit_d == w_bit) ? 1 : 0)) >= threshold);
            end
        end else begin
            done <= 0;
            index <= 0;  
        end
    end

endmodule
