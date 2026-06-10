module top (
    input        clk,          // 27 MHz onboard oscillator
    input        btn,          // a button to start (active-low on the board)
    output [5:0] led           // 6 onboard LEDs (active-low on Tang Nano 9K)
);

    // ---- Bake in the test image, same as weights ----
    reg [783:0] image;
    reg [783:0] image_mem [0:0];
    initial $readmemb("../weights/hw/test_image.mem", image_mem);

    // ---- Start handshake: pulse start once after power-up ----
    reg started;
    reg start;
    reg rst;

    wire [3:0] digit;
    wire done;

    bnn_seq net (
        .clk(clk), .rst(rst), .start(start),
        .image(image), .digit(digit), .done(done)
    );

    // Simple startup FSM: reset briefly, load image, pulse start once, then hold.
    reg [3:0] boot;
    always @(posedge clk) begin
        if (boot < 4'd10) begin
            boot  <= boot + 1;
            rst   <= (boot < 4'd3);          // reset for first few cycles
            image <= image_mem[0];           // load the baked-in image
            start <= 0;
        end else if (boot == 4'd10) begin
            start <= 1;                       // pulse start
            boot  <= boot + 1;
        end else begin
            start <= 0;                       // start was one cycle
        end
    end

    // ---- Show the digit on LEDs. Tang Nano 9K LEDs are ACTIVE-LOW. ----
    // led = ~digit so a lit LED means a 1 bit. 4 bits of digit -> low 4 LEDs.
    assign led = ~{2'b00, digit};

endmodule
