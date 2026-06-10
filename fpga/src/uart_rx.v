module uart_rx#(
    parameter CLK_FREQ = 27000000,   
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst,
    input rx,
    output reg [7:0] data,
    output reg valid //when byte ready
);
    localparam CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE; //234

    //start at centre of bit
    localparam HALF_BIT = CYCLES_PER_BIT / 2; //117

    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state;
    reg [7:0] clk_count;
    reg [2:0] bit_index; //which bit of the byte we're on

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; valid <= 0; clk_count <= 0; bit_index <= 0;
        end else begin
        case (state)
            IDLE: begin
                valid <= 0;
                //if bit goes low, start
                if (rx == 0) begin
                    state <= START;
                    clk_count <= 0;
                end
            end
            START: begin
                //wait half a bit for sampling
                if (clk_count == HALF_BIT-1) begin
                    //sample full bit periods from this point
                    clk_count <= 0;
                    bit_index <= 0;
                    state <= DATA;
                end else clk_count <= clk_count + 1;
            end
            DATA: begin
                //are we at the end
                if (clk_count == CYCLES_PER_BIT-1) begin
                    clk_count <= 0;
                    data[bit_index] <= rx; //sample, add to our reg
                    if (bit_index == 7) state <= STOP; //if thats the last data bit
                    else bit_index <= bit_index + 1; 
                end else clk_count <= clk_count + 1;
            end
            STOP: begin
                //wait for stop bit
                if (clk_count == CYCLES_PER_BIT-1) begin
                    valid <= 1; //data ready
                    state <= IDLE; 
                    clk_count <= 0;
                end else clk_count <= clk_count + 1;
            end
        endcase
        end
    end
endmodule
            
                
