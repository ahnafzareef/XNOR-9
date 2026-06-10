module weight_mem #(
    parameter N_IN    = 784,
    parameter N_OUT   = 256,
    parameter MEMFILE = "../weights/hw/layer1_weights_flat.mem"
)(
    input                          clk,
    input  [$clog2(N_OUT)-1:0]     neuron,
    input  [$clog2(N_IN)-1:0]      idx,
    output reg                     w_bit
);
    // Flat, 1-bit-wide, deep memory into BRAM.
    reg mem [0:N_IN*N_OUT-1];
    initial $readmemb(MEMFILE, mem);
    
    wire [$clog2(N_IN*N_OUT)-1:0] addr = neuron*N_IN + idx;
    always @(posedge clk) begin
        w_bit <= mem[addr];
    end
endmodule
