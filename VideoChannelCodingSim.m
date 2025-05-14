inputVideo = 'highway.avi';
packet_size = 1024;
trellis = poly2trellis(6, [65 57]);
frame_depth = 35;

% Define puncturing patterns for three code rates 
puncpat89 = logical([1 1 1 1 0 1 1 1; 1 0 0 0 1 0 0 0]); puncpat89 = puncpat89(:)';
puncpat45 = logical([1 1 1 1 1 1 1 1; 1 0 0 0 1 0 0 0]); puncpat45 = puncpat45(:)';
puncpat23 = logical([1 1 1 1 1 1 1 1; 1 0 1 0 1 0 1 0]); puncpat23 = puncpat23(:)';
punc_patterns = {puncpat89, puncpat45, puncpat23};
pattern_labels = {'8/9', '4/5', '2/3'};

% Define a range of channel error probabilities for simulation
p_values = linspace(0.0001, 0.2, 20);      % 20 values from 0.0001 to 0.2
ber_matrix = zeros(length(p_values), length(punc_patterns));
thr_matrix = zeros(length(p_values), length(punc_patterns));  

% Performance Evaluation for Each Puncturing Pattern
for j = 1:length(punc_patterns)
    puncture = punc_patterns{j};
    for i = 1:length(p_values)
        p = p_values(i);
        [BER, throughput] = measure_ber_throughput(inputVideo, p, 'punct', trellis, packet_size, puncture);
        ber_matrix(i, j) = BER;
        thr_matrix(i, j) = throughput;
    end
end

%BER Plotting
figure;
hold on;
for j = 1:length(punc_patterns)
    semilogy(p_values, ber_matrix(:, j), '-o', 'LineWidth', 2, 'DisplayName', pattern_labels{j});
end
grid on;
xlabel('Bit Error Probability (p)');
ylabel('BER');
title('BER vs. Channel Error Probability (Puncturing)');
legend('Location', 'best');
hold off;

%Throughput Plotting
figure;
hold on;
for j = 1:length(punc_patterns)
    plot(p_values, thr_matrix(:, j), '-s', 'LineWidth', 2, 'DisplayName', pattern_labels{j});
end
grid on;
xlabel('Bit Error Probability (p)');
ylabel('Throughput');
title('Throughput vs. Channel Error Probability (Puncturing)');
legend('Location', 'best');
hold off;

% Decode and Save Videos at Specific Error Rates
% Save six video reconstructions using different error probabilities and coding modes
for p = [0.001, 0.1]
    % Uncoded transmission
    decode_and_save(inputVideo, sprintf('decoded_p%.3f_none.avi', p), p, 'none', trellis, packet_size);
    % Convolutionally coded (rate 1/2)
    decode_and_save(inputVideo, sprintf('decoded_p%.3f_conv.avi', p), p, 'conv', trellis, packet_size);
    % Convolutional with puncturing (rate 8/9)
    decode_and_save(inputVideo, sprintf('decoded_p%.3f_punct.avi', p), p, 'punct', trellis, packet_size, puncpat89);
end

% Function: measure_ber_throughput
% Computes BER and throughput for a video under specified channel conditions
function [BER, throughput] = measure_ber_throughput(inputVideo, p, mode, trellis, packet_size, puncture)
    if nargin < 6, puncture = []; end
    obj = VideoReader(inputVideo);
    vid = read(obj);
    no_frames = 1; % Use only one frame for BER simulation to reduce runtime

    total_errors = 0;
    total_bits = 0;
    total_encoded_bits = 0;

    for Frame = 1:no_frames
        % Extract RGB channels and convert to binary
        R = vid(:,:,1,Frame); G = vid(:,:,2,Frame); B = vid(:,:,3,Frame);
        R_bin = reshape(de2bi(double(R(:)), 8, 'left-msb'), [], 1);
        G_bin = reshape(de2bi(double(G(:)), 8, 'left-msb'), [], 1);
        B_bin = reshape(de2bi(double(B(:)), 8, 'left-msb'), [], 1);

        % Process metrics for each channel
        [R_err, R_total, R_enc] = process_metrics(R_bin, p, mode, trellis, packet_size, puncture);
        [G_err, G_total, G_enc] = process_metrics(G_bin, p, mode, trellis, packet_size, puncture);
        [B_err, B_total, B_enc] = process_metrics(B_bin, p, mode, trellis, packet_size, puncture);

        % Accumulate results
        total_errors = total_errors + R_err + G_err + B_err;
        total_bits = total_bits + R_total + G_total + B_total;
        total_encoded_bits = total_encoded_bits + R_enc + G_enc + B_enc;
    end

    % Final BER and throughput calculations
    BER = total_errors / total_bits;
    throughput = (total_bits - total_errors) / total_encoded_bits;
end

%Function: process_metrics
% Encodes, simulates channel, decodes, and computes error and encoded bit stats
function [err_bits, total_bits, encoded_bits] = process_metrics(bin_data, p, mode, trellis, packet_size, puncture)
    pad_len = mod(packet_size - mod(length(bin_data), packet_size), packet_size);
    bin_data = [bin_data; zeros(pad_len,1)];
    decoded = zeros(size(bin_data));
    encoded_bits = 0;

    for i = 1:packet_size:length(bin_data)
        packet = bin_data(i:i+packet_size-1);

        % Encode based on selected mode
        switch mode
            case 'none'
                encoded = packet;
            case 'conv'
                encoded = convenc(packet, trellis);
            case 'punct'
                encoded = convenc(packet, trellis, puncture);
        end
        encoded_bits = encoded_bits + length(encoded);

        % Simulate transmission through BSC
        noisy = bsc(encoded, p);

        % Decode based on selected mode
        switch mode
            case 'none'
                decoded_packet = noisy;
            case 'conv'
                decoded_packet = vitdec(noisy, trellis, 35, 'trunc', 'hard');
            case 'punct'
                decoded_packet = vitdec(noisy, trellis, 35, 'trunc', 'hard', puncture);
        end

        decoded(i:i+packet_size-1) = decoded_packet;
    end

    % Compute number of bit errors (excluding padding)
    decoded = decoded(1:end - pad_len);
    err_bits = sum(bin_data(1:end - pad_len) ~= decoded);
    total_bits = length(bin_data) - pad_len;
end

%Function: decode_and_save
% Decodes the video using a specified coding mode and saves the reconstructed video
function decode_and_save(inputVideo, outputName, p, mode, trellis, packet_size, puncture)
    if nargin < 7, puncture = []; end
    obj = VideoReader(inputVideo);
    vid = read(obj);
    no_frames = obj.NumFrames;
    s = size(vid(:,:,:,1));
    mov(1:no_frames) = struct('cdata', zeros(s(1), s(2), 3, 'uint8'), 'colormap', []);

    for Frame = 1:no_frames
        % Extract and convert RGB channels to binary
        R = vid(:,:,1,Frame); G = vid(:,:,2,Frame); B = vid(:,:,3,Frame);
        R_bin = reshape(de2bi(double(R(:)), 8, 'left-msb'), [], 1);
        G_bin = reshape(de2bi(double(G(:)), 8, 'left-msb'), [], 1);
        B_bin = reshape(de2bi(double(B(:)), 8, 'left-msb'), [], 1);

        % Decode binary streams
        R_decoded = process_channel(R_bin, p, mode, trellis, packet_size, puncture);
        G_decoded = process_channel(G_bin, p, mode, trellis, packet_size, puncture);
        B_decoded = process_channel(B_bin, p, mode, trellis, packet_size, puncture);

        % Convert binary back to uint8 pixel values
        R_uint8 = uint8(bi2de(reshape(R_decoded, [], 8), 'left-msb'));
        G_uint8 = uint8(bi2de(reshape(G_decoded, [], 8), 'left-msb'));
        B_uint8 = uint8(bi2de(reshape(B_decoded, [], 8), 'left-msb'));

        % Reconstruct image frame
        R_img = reshape(R_uint8, s(1), s(2));
        G_img = reshape(G_uint8, s(1), s(2));
        B_img = reshape(B_uint8, s(1), s(2));
        mov(Frame).cdata = cat(3, R_img, G_img, B_img);
    end

    % Write video to output file
    v = VideoWriter(outputName, 'Motion JPEG AVI');
    v.FrameRate = obj.FrameRate;
    open(v);
    for i = 1:no_frames
        writeVideo(v, mov(i).cdata);
    end
    close(v);
end

% Function: process_channel
% Encodes, simulates noise, and decodes a binary stream using the specified mode
function decoded = process_channel(bin_data, p, mode, trellis, packet_size, puncture)
    pad_len = mod(packet_size - mod(length(bin_data), packet_size), packet_size);
    bin_data = [bin_data; zeros(pad_len,1)];
    decoded = zeros(size(bin_data));

    for i = 1:packet_size:length(bin_data)
        packet = bin_data(i:i+packet_size-1);

        % Encode
        switch mode
            case 'none'
                encoded = packet;
            case 'conv'
                encoded = convenc(packet, trellis);
            case 'punct'
                encoded = convenc(packet, trellis, puncture);
        end

        % Pass through BSC
        noisy = bsc(encoded, p);

        % Decode
        switch mode
            case 'none'
                decoded_packet = noisy;
            case 'conv'
                decoded_packet = vitdec(noisy, trellis, 35, 'trunc', 'hard');
            case 'punct'
                decoded_packet = vitdec(noisy, trellis, 35, 'trunc', 'hard', puncture);
        end

        decoded(i:i+packet_size-1) = decoded_packet;
    end

    decoded = decoded(1:end - pad_len);
end