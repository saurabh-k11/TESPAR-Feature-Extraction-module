module tespar #(
    parameter ADDR_WIDTH = 8,  // For WINDOW_SIZE = 256
    parameter WINDOW_SIZE = 256,
    parameter ALPHA_COUNT = 8  // Number of possible alphabets (1..8)
)(
    input clk,
    input reset,
    input signed [7:0] data_in,
    output [3:0] Alpha,                  // Current alphabet
    output reg [ALPHA_COUNT*16-1:0] feature_vector    // Histogram counts
);

    // Wires for DS and S
    wire [4:0] D;
    wire [2:0] S;

    // Instantiate DS_Gen and Alphabet_Gen
    DS_Gen ds(.clk(clk), .reset(reset), .data_in(data_in), .D(D), .S(S));
    Alphabet_Gen ag(.D(D), .S(S), .Alpha(Alpha));

    // SRAM signals
    reg we;
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [3:0] alpha_in;         // Alphabet to write into SRAM
    wire [3:0] old_alpha;       // Alphabet read from SRAM

    // Internal histogram array
    reg [15:0] feature_vector_int [1:ALPHA_COUNT];
    
    // SRAM instance
    sram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(4)) alpha_mem (
        .clk(clk),
        .we(we),
        .addr(we ? wr_ptr : rd_ptr),
        .din(alpha_in),
        .dout(old_alpha)
    );

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            we <= 0;
            alpha_in <= 0;
            for (i = 1; i <= ALPHA_COUNT; i = i + 1)
                feature_vector_int[i] <= 0;
        end 
        else begin
            // Step 1: Read oldest alphabet
            we <= 0;
            rd_ptr <= wr_ptr;

            // Step 2: Remove old alpha count
            if (old_alpha >= 1 && old_alpha <= ALPHA_COUNT) begin
                if (feature_vector_int[old_alpha] > 0)
                    feature_vector_int[old_alpha] <= feature_vector_int[old_alpha] - 1;
            end

            // Step 3: Store new alpha in SRAM
            we <= 1;
            alpha_in <= Alpha;
            wr_ptr <= wr_ptr + 1'b1;

            // Step 4: Add new alpha to histogram
            if (Alpha >= 1 && Alpha <= ALPHA_COUNT)
                feature_vector_int[Alpha] <= feature_vector_int[Alpha] + 1;
        end
    end


       always @(*) begin
        for (i = 1; i <= ALPHA_COUNT; i = i + 1) begin
            feature_vector[(i-1)*16 +: 16] = feature_vector_int[i];
        end
    end

endmodule
// ==================== DS_Gen ====================
module DS_Gen (
    input clk,
    input reset,
    input signed [7:0] data_in,
    output [4:0] D, // No. of samples between 2 zero crossings
    output [2:0] S  // No. of minima between 2 zero crossings
);

    reg signed [7:0] data_0; 
    reg signed [7:0] data_1; 
    reg [4:0] count_samples;
    reg [4:0] d_out;
    reg [2:0] count_minimas;
    reg [2:0] s_out;
    wire s_detect;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_0 <= 0;
            data_1 <= 0;
            count_samples <= 0;
            d_out <= 0;
            count_minimas <= 0;
            s_out <= 0;  
        end
        else begin 
            if (data_0[7] ^ data_in[7]) begin // zero crossing
                data_0 <= data_in;
                d_out <= count_samples;
                count_samples <= 5'd1;
                count_minimas <= 3'd0;
                s_out <= count_minimas;
            end
            else begin // minima detection
                data_0 <= data_in;
                data_1 <= data_0;
                count_samples <= count_samples + 5'd1;
                count_minimas <= count_minimas + {2'd0, s_detect};
            end
        end
    end

    assign s_detect = (data_0 < data_1) && (data_0 < data_in);
    assign D = d_out;
    assign S = s_out;
endmodule


// ==================== Alphabet_Gen ====================
module Alphabet_Gen(
    input [4:0] D,
    input [2:0] S,
    output reg [3:0] Alpha
);
    always @(*) begin
        case ({D,S})
            {5'd1,3'd0},{5'd1,3'd1},{5'd1,3'd2} : Alpha <= 1;
            {5'd2,3'd0},{5'd2,3'd1},{5'd2,3'd2} : Alpha <= 2;
            {5'd3,3'd0},{5'd3,3'd1},{5'd3,3'd2} : Alpha <= 3;
            {5'd4,3'd0},{5'd4,3'd1},{5'd4,3'd2} : Alpha <= 4;
            {5'd5,3'd0},{5'd5,3'd1},{5'd5,3'd2} : Alpha <= 5;
            {5'd6,3'd0},{5'd6,3'd1},{5'd6,3'd2} : Alpha <= 6;
            {5'd7,3'd0},{5'd7,3'd1},{5'd7,3'd2} : Alpha <= 6;
            {5'd8,3'd0},{5'd9,3'd0},{5'd10,3'd0} : Alpha <= 7;
            {5'd8,3'd1},{5'd8,3'd2},
            {5'd9,3'd1},{5'd9,3'd2},
            {5'd10,3'd1},{5'd10,3'd2} : Alpha <= 8;
            default: Alpha <= 0;
        endcase
    end
endmodule


// ==================== SRAM Module ====================
module sram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 4
)(
    input clk,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule
