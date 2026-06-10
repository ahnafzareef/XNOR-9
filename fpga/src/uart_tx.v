module uart_tx #(
    parameter CLK_FREQ = 27000000,   
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst,
    input send, //send data pulse high. will be set high when data VALID
    input [7:0] data, //data to send
    output reg tx, //serial output serially give a bit at a time
    output reg busy
);
    localparam CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE; //234
    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state;
    reg [15:0] clk_count; 
    reg [2:0] bit_index;
    reg [7:0] shift; //shift register for data bits, shift a bit for a byte at a time

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; tx = 1; busy <= 0; clk_count <= 0; bit_index <= 0; 
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1;
                    busy <= 0;
                    if (send) begin //if ready to send
                        shift <= data; //load data into shift register
                        busy <= 1; //we're now busy
                        clk_count <= 0; 
                        state <= START;
                    end
                end
                START: begin
                    tx <= 0; //start bit
                    if (clk_count == CYCLES_PER_BIT-1) begin
                        clk_count <= 0;
                        bit_index <= 0;
                        state <= DATA;
                    end else clk_count <= clk_count + 1;
                end
                DATA: begin
                    tx <= shift[0]; //send current lsb
                    if (clk_count == CYCLES_PER_BIT-1) begin //if done bit
                        clk_count <= 0;
                        if (bit_index == 7) state <= STOP;
                        else begin
                            bit_index <= bit_index + 1;
                            shift <= shift >> 1; //advance to next bit (lsb first)
                        end
                    end else clk_count <= clk_count + 1;
                end
                STOP: begin
                    tx <= 1; 
                    if (clk_count == CYCLES_PER_BIT-1) begin
                        clk_count <= 0;
                        busy <= 0; 
                        state <= IDLE;
                    end else clk_count <= clk_count + 1;
                end
            endcase
        end
    end
endmodule

