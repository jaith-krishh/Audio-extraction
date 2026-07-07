# MATLAB Speech Noise Removal Tool

A MATLAB desktop application that removes background noise from speech recordings using an adaptive **Decision-Directed Wiener Filter** — a significant upgrade over basic spectral subtraction, designed to eliminate the "musical noise" and muffled-speech artifacts common in simpler noise reduction methods.

Load a noisy audio file, tune the filter, preview the waveform, and export a cleaned `.wav` — all through a simple GUI.

---
## How It Works

The core algorithm goes well beyond basic spectral subtraction:
1. **Pre-emphasis filtering** — boosts high frequencies so quiet consonants (s, t, k) survive the noise removal process
2. **Framing & windowing** — audio is split into overlapping frames using a Square-Root Hann window for artifact-free reconstruction
3. **Short-Time Fourier Transform (STFT)** — converts each frame into magnitude and phase spectra
4. **Adaptive noise profiling** — estimates the noise "fingerprint" from an initial silent segment, then continuously updates it using a simple Voice Activity Detector (VAD), so it adapts even if background noise changes mid-recording
5. **Decision-Directed SNR estimation** — smooths the signal-to-noise ratio estimate across frames (Ephraim–Malah method) to eliminate robotic "musical noise" artifacts
6. **Wiener gain masking** — applies a smooth, soft gain (0 to 1) per frequency bin instead of hard on/off subtraction, for natural-sounding suppression
7. **Inverse STFT + Overlap-Add** — reconstructs the time-domain signal seamlessly using the preserved phase
8. **De-emphasis & normalization** — restores natural voice tone and consistent playback volume

##  Getting Started

### Requirements
- MATLAB (with Signal Processing Toolbox recommended for full audio format support)

### Run the app
```matlab
app = noiseReductionApp;
```

### Usage
1. Click **Load Audio File** and select a noisy recording
2. Adjust the **Alpha** value to control filtering aggressiveness (higher = more aggressive noise removal, but risks muffling speech)
3. Click **Process**
4. Use **Play Original** / **Play Cleaned** to compare, and **Stop Audio** to halt playback
5. Click **Save Output** to export the cleaned `.wav` file

---

##  Tuning Notes

- **Alpha (subtraction/aggressiveness factor):** typical range 1–3. Too high causes muffled speech; too low leaves residual noise.
- **Noise profile window:** assumes the first ~0.5s of audio is noise-only (silence before speech starts). If your recording doesn't start with silence, results may vary.
- The adaptive noise tracking (VAD-based) helps the filter adjust if background noise changes partway through the recording.

---

##  License

This project is open for educational and personal use. Feel free to fork and adapt it for your own experiments.
