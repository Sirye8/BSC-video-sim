# Channel-Coding-Video-Sim 📡📹

Simulate video transmission over a Binary Symmetric Channel (BSC) using punctured convolutional codes, measuring Bit Error Rate (BER) and throughput performance.

## Overview 🔍
This MATLAB project simulates the transmission of a video stream over a noisy channel with configurable error probability (`p`). It implements:
- **Convolutional encoding/decoding** (rate 1/2) with puncturing patterns (e.g., 8/9, 4/5, 2/3).
- **Bit Error Rate (BER) and throughput analysis** across channel error probabilities (`p = 0.0001` to `0.2`).
- **Video reconstruction** from decoded bits for qualitative assessment.

## Features ✨
- Convert `.avi` video to binary streams and segment into 1024-bit packets.
- Apply convolutional coding with puncturing for variable code rates.
- Simulate transmission over a BSC with adjustable error probability `p`.
- Generate BER vs. `p` and throughput vs. `p` plots.
- Save decoded videos for qualitative comparison (6 output files).

## Installation ⚙️
1. **Requirements**:
   - MATLAB R2020a or later.
   - MATLAB Communications Toolbox (for `convenc`, `vitdec`, `bsc`).
   - An input `.avi` file (e.g., `highway.avi` included in the repository).

2. **Clone the Repository**:
   ```bash
   git clone https://github.com/Sirye8/BSC-video-sim.git
   ```

## Usage 🚀
1. **Run the Main Script**:
   ```matlab
   % Execute in MATLAB
   VideoChannelCodingSim;
   ```
2. **Adjust Parameters** (optional):
   - Modify `p_values` in `ChannelCoding.m` to change the error probability range.
   - Update `packet_size` or puncturing patterns (`puncpat89`, `puncpat45`, etc.).

3. **Outputs**:
   - `BER vs. Channel Error Probability (Puncturing).fig`: BER performance plot.
   - `Throughput vs. Channel Error Probability (Puncturing).fig`: Throughput plot.
   - Decoded videos (e.g., `decoded_p0.001_punct.avi`, `decoded_p0.1_conv.avi`).

## Results 📊
- **Quantitative Analysis**: BER and throughput curves compare performance of punctured vs. non-punctured codes.
- **Qualitative Analysis**: Decoded videos at `p = 0.001` and `p = 0.1` illustrate visual degradation/improvement with coding.

## Included Files 📂
- `VideoChannelCodingSim.m`: Main simulation script.
- `highway.avi`: Example input video (replace with your own `.avi` file if desired).
---

⚠️ **Disclaimer**: This project is part of an academic assignment. Do not submit this code directly as your own work.  