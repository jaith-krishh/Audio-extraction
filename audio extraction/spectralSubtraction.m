function [y_clean, fs] = spectralSubtraction(inputFile, alpha, noiseDuration)
    % inputFile: path to noisy audio file
    % alpha: oversubtraction factor (default 2)
    % noiseDuration: seconds of noise-only audio at start (default 0.5)

    if nargin < 2, alpha = 2; end
    if nargin < 3, noiseDuration = 0.5; end

    [y, fs] = audioread(inputFile);
    if size(y,2) > 1
        y = mean(y, 2); % convert to mono
    end

    % Pre-emphasis filter to boost high frequencies (drastically improves speech clarity)
    y = filter([1, -0.95], 1, y);

    frameLen = 1024;
    hopLen = 512;
    
    % Use sqrt(Hann) window for perfect reconstruction at 50% overlap
    hann_win = 0.5 - 0.5 * cos(2 * pi * (0:frameLen-1)' / frameLen);
    win = sqrt(hann_win);

    % Get number of frames
    numFrames = floor((length(y) - frameLen) / hopLen) + 1;
    
    % --- STFT of full signal ---
    S = zeros(frameLen, numFrames);
    for k = 1:numFrames
        idx = (k-1)*hopLen + 1;
        frame = y(idx : idx+frameLen-1) .* win;
        S(:, k) = fft(frame);
    end
    
    % --- Noise Profile ---
    noiseSamples = min(round(noiseDuration*fs), length(y));
    noiseFrames = floor((noiseSamples - frameLen) / hopLen) + 1;
    if noiseFrames < 1
        noiseFrames = 1;
    end
    % --- Advanced Wiener Filtering (Decision-Directed Approach with Adaptive Noise Profile) ---
    magS = abs(S);
    phaseS = angle(S);
    
    % Initialize noise power from the first few frames
    currentNoisePow = mean(magS(:, 1:noiseFrames).^2, 2);
    noisePow = zeros(frameLen, numFrames); % to store the history
    
    G = ones(frameLen, numFrames);
    alpha_dd = 0.98; % Smoothing factor (0.95 to 0.99)
    
    % VAD and Adaptive Noise Parameters
    vad_threshold = 2.0; % Energy multiplier threshold for speech detection
    noise_update_alpha = 0.95; % Recursive blending factor for updating noise profile
    
    % Initialize prior SNR
    SNR_prior = max((magS(:,1).^2) ./ (currentNoisePow + eps) - 1, 0);
    
    for k = 1:numFrames
        framePow = magS(:,k).^2;
        
        % Simple Voice Activity Detector (VAD)
        % If the frame's total energy is close to the noise floor, it's noise.
        if sum(framePow) < vad_threshold * sum(currentNoisePow)
            % It's a noise frame! Slowly update the noise profile recursively.
            currentNoisePow = noise_update_alpha * currentNoisePow + (1 - noise_update_alpha) * framePow;
        end
        
        % Store the adaptive noise profile for this frame
        noisePow(:,k) = currentNoisePow;
        
        % A-posteriori SNR (incorporating the user's alpha parameter for aggressiveness)
        % Lower alpha = clearer speech but more noise; Higher alpha = less noise but muffled speech
        SNR_post = framePow ./ (alpha * currentNoisePow + eps);
        
        % A-priori SNR (Decision-Directed)
        if k > 1
            SNR_prior = alpha_dd * (G(:,k-1).^2 .* SNR_post_prev) + (1 - alpha_dd) * max(SNR_post - 1, 0);
        end
        SNR_post_prev = SNR_post;
        
        % Calculate Wiener Gain
        G(:,k) = SNR_prior ./ (1 + SNR_prior);
        
        % Apply a soft spectral floor based on the user's alpha parameter
        noiseFloor = max(0.1 / max(alpha, 1), 0.01);
        G(:,k) = max(G(:,k), noiseFloor);
    end
    
    magS_clean = magS .* G;
    
    % --- Reconstruct (ISTFT) ---
    S_clean = magS_clean .* exp(1i * phaseS);
    
    y_clean = zeros(length(y), 1);
    winSum = zeros(length(y), 1);
    
    for k = 1:numFrames
        idx = (k-1)*hopLen + 1;
        % Apply synthesis window (sqrt-Hann * sqrt-Hann = Hann, which sums perfectly to 1)
        frame_clean = real(ifft(S_clean(:, k))) .* win; 
        
        y_clean(idx : idx+frameLen-1) = y_clean(idx : idx+frameLen-1) + frame_clean;
    end
    
    % We no longer need to divide by winSum because Hann windows sum perfectly to 1 at 50% overlap!
    
    % De-emphasis filter to restore natural voice tone
    y_clean = filter(1, [1, -0.95], y_clean);
    
    y_clean = y_clean / max(abs(y_clean) + eps); % normalize volume
end
