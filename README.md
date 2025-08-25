#TESPAR Feature Extraction in Verilog

This project implements a Time Encoded Signal Processing And Recognition (TESPAR) feature extraction system in Verilog.
It processes sampled audio data and generates feature vectors (histograms of alphabets) using zero-crossing analysis.

##📌 Project Overview

TESPAR is a speech/signal processing technique that encodes waveforms into symbolic alphabets based on their zero-crossings and minima detection.
The design here implements a TESPAR front-end that performs:

##DS Generation

Detects zero crossings in the input waveform.

Counts the number of samples (D) between zero crossings.

Counts the number of minima (S) within the segment.

##Alphabet Generation

Maps (D, S) pairs into alphabets (1–8) using classification rules.

Sliding Window Histogram

Uses an SRAM buffer to maintain the last WINDOW_SIZE alphabets.

Maintains a histogram feature vector of alphabet frequencies in the window.

Supports real-time updates with old alphabet removal and new alphabet addition.

##📂 Module Descriptions
1. DS_Gen

Inputs: clk, reset, data_in (signed 8-bit sample)

Outputs: D (5-bit, number of samples between zero crossings), S (3-bit, number of minima)

Logic:

Detects zero crossings using sign change.

Resets counters on crossing and outputs (D, S).

2. Alphabet_Gen

Inputs: D, S

Outputs: Alpha (4-bit alphabet code)

Logic:

Maps (D, S) into alphabets 1–8.

Default output = 0 (invalid).

3. SRAM

Simple synchronous SRAM model.

Stores alphabets in circular buffer.

Parameters: ADDR_WIDTH (default = 8 → depth 256), DATA_WIDTH = 4.

4. tespar (Top Module)

Integrates all submodules.

Maintains sliding window histogram of alphabets.

Parameters:

ADDR_WIDTH = 8 (→ 256 window size).

WINDOW_SIZE = 256.

ALPHA_COUNT = 8.

Outputs:

Alpha: current alphabet.

feature_vector: concatenated histogram (each 16-bit count per alphabet).

##🛠️ Simulation Flow

Input:
Provide data_in as a sampled signal sequence (e.g., speech or waveform samples).

Process:

DS_Gen computes (D, S) per zero-crossing interval.

Alphabet_Gen assigns an alphabet.

SRAM buffer stores alphabets for a fixed sliding window.

Histogram (feature_vector) is updated dynamically.

Output:

Real-time Alpha code.

Feature vector representing alphabet distribution in the window.

##📊 Feature Vector Format

feature_vector is a concatenated array of 16-bit counters:

| Alpha 1 Count | Alpha 2 Count | ... | Alpha 8 Count |


Each counter increments/decrements as alphabets enter/leave the sliding window.

##▶️ Example Testbench Usage

You can create a testbench that:

Feeds data_in from a sampled waveform file ($readmemb or $readmemh).

Monitors outputs (Alpha and feature_vector).

Verifies histogram updates correctly.

initial begin
    $readmemb("signal_samples.mem", samples);
    reset = 1; #10 reset = 0;
    for (i = 0; i < N; i = i + 1) begin
        data_in = samples[i];
        #10;
    end
    $stop;
end

##📦 Project Structure
tespar/
├── tespar.v          # Top module
├── DS_Gen.v          # Zero-crossing + minima detector
├── Alphabet_Gen.v    # D-S to alphabet mapper
├── sram.v            # Simple SRAM
├── tb_tespar.v       # Testbench (to be written)
├── signal_samples.mem # Example input data (binary/text samples)
└── README.md



