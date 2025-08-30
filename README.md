# Voice Dictation for Terminal

A lightweight, **FREE**, offline voice dictation tool for Linux terminals using OpenAI's Whisper model running locally.

## Features

- **100% Free**: Uses open-source Whisper model, no API costs
- **Offline**: Works without internet connection after setup
- **Fast**: ~3-5 seconds to transcribe 10 seconds of speech
- **Lightweight**: Runs on older hardware (tested on i7-4710HQ with 8GB RAM)
- **Terminal-friendly**: Designed for SSH sessions and terminal workflows

## Quick Start

```bash
# Test the voice dictation
./scripts/dictate.sh -p

# Set up convenient alias
./scripts/setup-alias.sh
source ~/.bashrc

# Now you can use from anywhere:
dictate           # Record and auto-type transcribed text
dictate -m        # Manual recording (Ctrl+C to stop)
dictate -p        # Print transcription only
dictate -c        # Copy to clipboard only
```

## Project Structure

```
voice-dictation/
├── scripts/          # Main scripts
│   ├── dictate.sh    # Voice dictation tool
│   └── setup-alias.sh # Setup convenience alias
├── models/           # Whisper models (150MB+)
│   └── ggml-base.en.bin
├── recordings/       # Temporary audio files
└── config/          # Configuration (future)
```

## How It Works

1. **Recording**: Uses `sox` to capture audio from your microphone
2. **Transcription**: Processes audio through Whisper.cpp (running locally)
3. **Output**: Can type text directly, copy to clipboard, or print to stdout

## Recording Modes

- **Auto-stop** (default): Stops recording after 1 second of silence
- **Manual** (`-m`): Record until you press Ctrl+C

## Output Modes

- **Auto-type** (default): Types transcribed text using xdotool
- **Copy** (`-c`): Copies to clipboard using xclip
- **Print** (`-p`): Outputs to terminal only

## System Requirements

- **CPU**: Any x86_64 processor (4+ cores recommended)
- **RAM**: 2GB minimum (4GB+ recommended)
- **Disk**: ~200MB for model and binaries
- **OS**: Linux (tested on Fedora, Ubuntu)

## Dependencies

Already installed:
- gcc/g++ (for compilation)
- cmake (build system)
- sox (audio recording)
- whisper.cpp (transcription engine)
- Whisper model (ggml-base.en.bin, 121MB)

Optional (for enhanced features):
- xdotool (for auto-typing text)
- xclip (for clipboard support)

To install optional dependencies:
```bash
# Fedora
sudo dnf install xdotool xclip

# Ubuntu/Debian
sudo apt install xdotool xclip
```

## Hotkey Setup (Optional)

To bind voice dictation to a hotkey (e.g., Super+V):

### For GNOME (Fedora default)
1. Open Settings → Keyboard → Keyboard Shortcuts
2. Add custom shortcut:
   - Name: Voice Dictation
   - Command: `/home/$USER/workspace/voice-dictation/scripts/dictate.sh`
   - Shortcut: Super+V (or your preference)

### For terminal hotkeys
Add to `~/.bashrc`:
```bash
# Ctrl+Alt+D for dictation
bind '"\e\C-d": "dictate\n"'
```

## Performance

- **Model**: base.en (121MB, English-only, optimized)
- **Speed**: ~3-5 seconds for 10 seconds of audio
- **Accuracy**: Excellent for English, handles accents well
- **CPU Usage**: Moderate during transcription (few seconds)

## Tips for Best Results

1. **Speak clearly** and at normal pace
2. **Minimize background noise** for better accuracy
3. **Use manual mode** (`-m`) for longer dictations
4. **Test with print mode** (`-p`) first to verify setup

## Troubleshooting

### No audio recorded
- Check microphone permissions
- Test with: `sox -d test.wav` (Ctrl+C to stop)
- Verify audio device: `arecord -l`

### Transcription errors
- Speak more clearly
- Reduce background noise
- Try manual recording mode: `dictate -m`

### Text not typing automatically
- Install xdotool: `sudo dnf install xdotool`
- Use clipboard mode instead: `dictate -c`

## Advanced Usage

### Different Whisper models

For better accuracy (slower, larger):
```bash
# Download larger model (if needed)
cd ~/workspace/whisper.cpp
bash ./models/download-ggml-model.sh small.en  # 466MB

# Update MODEL_PATH in dictate.sh
```

### Custom recording settings

Edit `dictate.sh` to adjust:
- Sample rate (default: 16000 Hz)
- Silence threshold (default: 1%)
- Silence duration (default: 1 second)

## Privacy & Security

- **100% offline**: No data sent to any servers
- **Local processing**: All transcription happens on your machine
- **No tracking**: Completely private, no telemetry
- **Temporary files**: Audio recordings auto-deleted after transcription

## Credits

- [Whisper](https://github.com/openai/whisper) by OpenAI (model)
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov (C++ implementation)
- Sox audio toolkit for recording

## License

This project uses open-source components:
- Whisper model: MIT License
- whisper.cpp: MIT License

---

Created with Claude Code for improved terminal workflow and accessibility.