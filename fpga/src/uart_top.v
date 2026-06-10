module uart_top #(
    parameter CLK_FREQ = 27000000,   
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst,
    input uart_rx_pin, //serial input from ESP
    output uart_tx_pin, //serial output to ESP
    output [5:0] led //leds to show num
);

    wire rst_i = ~rst;

    wire [7:0] rx_byte;
    wire rx_valid;
    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) rx (
        .clk(clk),
        .rst(rst_i),
        .rx(uart_rx_pin),
        .data(rx_byte),
        .valid(rx_valid)
    );

    //urat transmission
    reg tx_send;
    reg [7:0] tx_data;
    wire tx_busy;
    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) tx (
        .clk(clk),
        .rst(rst_i),
        .send(tx_send),
        .data(tx_data),
        .tx(uart_tx_pin),
        .busy(tx_busy)
    );

    //neural network 
    reg net_start;
    reg [783:0] image;
    wire [3:0] digit;
    wire net_done;
    
    bnn_seq NET (
        .clk(clk),
        .rst(rst_i),
        .start(net_start),
        .image(image),
        .digit(digit),
        .done(net_done)
    );

    assign led = ~{2'b00, digit}; //digit

    //wrapper
    localparam RECV = 0, RUN = 1, WAIT = 2, SEND = 3, SENDWAIT = 4;
    reg [2:0] state;
    reg [6:0] byte_count; //how many bytes, 784/8 is 98 so we need 7 bits

    always @(posedge clk) begin
        if (rst_i) begin
            state <= RECV; byte_count <= 0; net_start <= 0; tx_send <= 0;
        end else begin
            case (state)
                RECV: begin
                    net_start <=0;
                    if (rx_valid) //if we get a byte store in its pos in image
                    begin
                        image[byte_count*8 +: 8] <= rx_byte; //store byte
                        if (byte_count == 97) begin //recieved all bytes
                            byte_count <= 0;
                            state <= RUN; //start net
                        end else byte_count <= byte_count + 1;
                    end
                end
                RUN: begin
                    net_start <= 1; //start net
                    state <= WAIT;
                end
                WAIT: begin
                    net_start <= 0;
                    if (net_done) state <= SEND; //when net done, send result
                end
                SEND: begin
                    tx_data <= {4'b0, digit}; //send digit as byte, 0-9, digit is 4 bits, so need 4 more
                    tx_send <= 1; //send data
                    state <= SENDWAIT;
                end
                SENDWAIT: begin
                    tx_send <= 0; //clear send
                    if (!tx_busy) state <= RECV; //when done sending, go back to recv
                end
            endcase
        end
    end
endmodule




