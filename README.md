# Voice Dictation for Linux

A powerful, **FREE**, offline voice dictation system with multiple input modes including push-to-talk and keyboard shortcuts. Uses OpenAI's Whisper model running locally - no cloud, no API costs, complete privacy.

## ✨ Features

- **🎯 Three Input Modes**: Toggle, Push-to-Talk, or Manual
- **⌨️ Keyboard Shortcuts**: Works with GNOME/Wayland hotkeys
- **🔒 100% Private**: Runs offline, no data leaves your machine
- **💰 Completely Free**: Uses open-source Whisper model
- **🚀 Fast**: 3-5 seconds to transcribe speech
- **🖥️ Wayland/X11**: Works on modern and legacy systems

## 🚀 Quick Start

```bash
# Run the interactive installer
./install-shortcuts.sh

# Or test immediately with toggle mode (no sudo needed!)
./scripts/voice-toggle.sh  # Press once to start, again to stop
```

## 📦 Installation

### Prerequisites

```bash
# Required packages
sudo dnf install gcc-c++ cmake sox pulseaudio-utils

# For auto-typing (recommended)
sudo dnf install ydotool wl-clipboard

# For push-to-talk mode
pip install evdev  # or sudo dnf install python3-evdev
```

### Setup

1. **Clone and compile** (already done if you're reading this)
2. **Run the installer**:
   ```bash
   ./install-shortcuts.sh
   ```
3. **Choose your setup**:
   - Option 1: GNOME keyboard shortcut (recommended)
   - Option 2: Terminal aliases
   - Option 3: Push-to-talk daemon

## 🎤 Usage Modes

### 1. Toggle Mode (Easiest - No sudo)
Best for GNOME keyboard shortcuts.

```bash
./scripts/voice-toggle.sh
```
- **Press hotkey once** → Start recording (notification appears)
- **Press hotkey again** → Stop, transcribe, type text
- **No sudo required!**

**Setup GNOME Shortcut:**
1. Settings → Keyboard → View and Customize Shortcuts
2. Add Custom Shortcut
3. Command: `/home/$USER/workspace/voice-dictation/scripts/voice-toggle.sh`
4. Set key: `Super+V` or `Alt+/`

### 2. Push-to-Talk (Most Natural)
Like Discord/gaming - hold key to record.

```bash
sudo python3 ./scripts/push-to-talk.py
```
- **Hold `Alt+/`** → Recording
- **Release** → Transcribes & types
- **Requires sudo** (for keyboard monitoring)

**Optional: Run as service**
```bash
sudo systemctl enable voice-ptt.service
sudo systemctl start voice-ptt.service
```

### 3. Manual Mode (Original)
Terminal-based, full control.

```bash
./scripts/dictate.sh -m     # Manual mode (Ctrl+C to stop)
./scripts/dictate.sh -p     # Auto-stop mode, print only
./scripts/dictate.sh        # Auto-type mode
```

### Terminal Aliases

Add to `~/.bashrc`:
```bash
alias vd='~/workspace/voice-dictation/scripts/voice-toggle.sh'
alias dictate='~/workspace/voice-dictation/scripts/dictate.sh -m'
```

## 🛠️ Configuration

### Project Structure
```
voice-dictation/
├── scripts/
│   ├── dictate.sh         # Original dictation script
│   ├── voice-toggle.sh    # Toggle mode for shortcuts
│   ├── push-to-talk.py    # Push-to-talk daemon
│   └── setup-alias.sh     # Alias installer
├── models/
│   └── ggml-base.en.bin   # Whisper model (142MB)
├── recordings/            # Temporary audio files
└── install-shortcuts.sh   # Interactive installer
```

### Whisper Models

Current: `base.en` (142MB, good accuracy)

For better accuracy:
```bash
cd ~/workspace/whisper.cpp
bash ./models/download-ggml-model.sh small.en  # 466MB
# Update MODEL_PATH in scripts
```

## ✅ What Works

- **Toggle mode** - Recording with GNOME notifications
- **Push-to-talk** - Hold Alt+/ to record
- **Auto-typing** - Types transcribed text (ydotool/xdotool)
- **Clipboard fallback** - Copies if typing unavailable
- **Wayland native** - Full Wayland/GNOME support
- **PulseAudio** - Reliable audio capture

## 🔧 Troubleshooting

### No text appearing?
```bash
# Install typing tools
sudo dnf install ydotool
sudo systemctl enable --now ydotool  # For Wayland

# Or use clipboard fallback
sudo dnf install wl-clipboard
```

### Recording not working?
```bash
# Test microphone
parecord test.wav  # Ctrl+C to stop
paplay test.wav    # Should hear your voice

# Check volume
pavucontrol  # GUI mixer
```

### Push-to-talk not detecting keys?
```bash
# Must run with sudo
sudo python3 scripts/push-to-talk.py

# Check python-evdev
python3 -c "import evdev"  # Should not error
```

### Transcription inaccurate?
- Speak clearly, normal pace
- Reduce background noise
- Consider `small.en` model for better accuracy

## 📊 Performance

- **Model**: base.en (142MB, English-optimized)
- **Speed**: ~3-5 seconds for 10 seconds of audio
- **RAM**: ~1-2GB during transcription
- **CPU**: 4 cores recommended (works on i7-4710HQ)

## 🔒 Privacy & Security

- **100% Offline**: No internet required after setup
- **Local Processing**: All transcription on your machine
- **No Telemetry**: Zero tracking or analytics
- **Auto-cleanup**: Temporary recordings deleted after use

## 💡 Tips

1. **For meetings**: Use toggle mode with `Super+V`
2. **For coding**: Push-to-talk with `Alt+/`
3. **For long text**: Manual mode with `dictate -m`
4. **Quick test**: `dictate -p` to print only

## 🐛 Known Issues

- Push-to-talk requires sudo (evdev limitation)
- GNOME on Wayland blocks global hotkeys (use toggle mode)
- First transcription may be slower (model loading)

## 📚 Documentation

- [Setup Shortcuts Guide](SETUP_SHORTCUTS.md) - Detailed setup instructions
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) - Transcription engine
- [OpenAI Whisper](https://github.com/openai/whisper) - Original model

## 🙏 Credits

- **Whisper** by OpenAI - Speech recognition model
- **whisper.cpp** by Georgi Gerganov - C++ implementation  
- **PulseAudio** - Audio capture
- Built with **Claude Code** for improved developer experience

## 📄 License

MIT License - Use freely, modify as needed.

---

*Voice control your terminal. Type with your voice. Stay in flow.*