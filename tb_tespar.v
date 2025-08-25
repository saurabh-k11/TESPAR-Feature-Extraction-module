`timescale 1ns/1ps

module tb_tespar;

    // Parameters
    parameter ADDR_WIDTH = 8;
    parameter WINDOW_SIZE = 256;
    parameter ALPHA_COUNT = 8;

    // Signals
    reg clk;
    reg reset;
    reg signed [7:0] data_in;
    wire [3:0] Alpha;
    wire [ALPHA_COUNT*16-1:0] feature_vector;

    // Sample memory
    reg signed [7:0] samples [0:511];  // example: 512 samples
    integer i;

    // DUT instance
    tespar #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .WINDOW_SIZE(WINDOW_SIZE),
        .ALPHA_COUNT(ALPHA_COUNT)
    ) dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .Alpha(Alpha),
        .feature_vector(feature_vector)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock (10ns period)
    end

    // Test procedure
    initial begin
        // Load test samples from file
        $readmemb("signal_samples.mem", samples);

        // Reset DUT
        reset = 1;
        data_in = 0;
        #20;
        reset = 0;

        // Feed samples one by one
        for (i = 0; i < 512; i = i + 1) begin
            data_in = samples[i];
            #10;  // wait one clock cycle
            $display("t=%0t, data_in=%0d, Alpha=%0d, FeatureVec=%h", 
                      $time, data_in, Alpha, feature_vector);
        end

        $stop;
    end

endmodule
