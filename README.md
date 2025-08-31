# Voice Dictation for Linux

A powerful, **FREE**, offline voice dictation system with multiple input modes including push-to-talk and keyboard shortcuts. Uses OpenAI's Whisper model running locally - no cloud, no API costs, complete privacy.

## ✨ Features

- **🎯 Three Input Modes**: Toggle, Push-to-Talk, or Manual
- **⌨️ Keyboard Shortcuts**: Works with GNOME/Wayland hotkeys
- **🔒 100% Private**: Runs offline, no data leaves your machine
- **💰 Completely Free**: Uses open-source Whisper model
- **🚀 Fast**: 3-5 seconds to transcribe speech
- **🖥️ Wayland/GNOME**: Native PipeWire support, works on modern systems
- **🎤 Battle-Tested**: Proven working system with professional architecture

## 🚀 Quick Start

```bash
# 1. Download the Whisper model (142MB, one-time)
make download-model

# 2. Check dependencies and install
make check-deps
make install

# Or run directly without installation
./bin/voice-toggle  # Press once to start, again to stop
```

## 📦 Installation

### Prerequisites

```bash
# Required packages (Fedora)
sudo dnf install gcc-c++ cmake ffmpeg pulseaudio-utils wtype

# For auto-typing (recommended)
sudo dnf install wl-clipboard

# For push-to-talk mode (required)
sudo dnf install python3-evdev

# Check if you have PipeWire (modern audio system)
pactl info  # Should show server info
```

### Setup

1. **Clone and compile** (already done if you're reading this)
2. **Download the model** (142MB, one-time):
   ```bash
   make download-model  # Or: ./setup/download-model.sh
   ```
3. **Install with Make**:
   ```bash
   make check-deps  # Verify dependencies
   make install     # Install to ~/.local
   ```
4. **Set up shortcuts**:
   ```bash
   make setup-gnome  # For GNOME keyboard shortcut
   # Or run setup/install.sh for interactive setup
   ```

## 🎤 Usage Modes

### 1. Toggle Mode (Easiest - No sudo)
Best for GNOME keyboard shortcuts.

```bash
./bin/voice-toggle
```
- **Press hotkey once** → Start recording (notification appears)
- **Press hotkey again** → Stop, transcribe, type text
- **No sudo required!**

**Setup GNOME Shortcut:**
1. Settings → Keyboard → View and Customize Shortcuts
2. Add Custom Shortcut
3. Command: `~/.local/bin/voice-toggle` (after installation)
   Or: `/home/$USER/workspace/voice-dictation/bin/voice-toggle`
4. Set key: `Alt+Shift+V` (recommended - won't conflict)

**Or use our helper script:**
```bash
./setup/gnome-shortcut.sh  # Interactive setup
```

### 2. Push-to-Talk (Most Natural)
Like Discord/gaming - hold key to record.

**Setup (one-time):**
```bash
# 1. Add yourself to input group (for keyboard access)
sudo usermod -a -G input $USER

# 2. Start ydotool daemon (for auto-typing)
ydotoold &

# 3. Run push-to-talk (secure wrapper - no permanent group changes!)
./bin/ptt
```

**Why use `ptt` instead of `voice-ptt`?**
- `./bin/ptt` uses temporary input group permissions (more secure)
- `./bin/voice-ptt` requires permanent group activation (`newgrp input` after each terminal)
- Same functionality, better security model

**Usage:**
- **Hold `Right Alt (AltGr)`** → Recording
- **Release** → Transcribes & types automatically
- **No sudo required** with proper setup!

**Make it permanent:**
```bash
echo "ydotoold &" >> ~/.bashrc  # Auto-start ydotool daemon
```

### 3. Manual Mode (Original)
Terminal-based, full control.

```bash
./bin/dictate -m     # Manual mode (Ctrl+C to stop)
./bin/dictate -p     # Auto-stop mode, print only
./bin/dictate        # Auto-type mode
# Or after installation: just 'dictate'
```

### Terminal Aliases

Add to `~/.bashrc`:
```bash
alias vd='voice-toggle'    # After make install
alias dictate='dictate -m'  # After make install
# Or without installation:
alias vd='~/workspace/voice-dictation/bin/voice-toggle'
alias dictate='~/workspace/voice-dictation/bin/dictate -m'
```

## 🛠️ Configuration

### Project Structure
```
voice-dictation/
├── bin/                   # User executables
│   ├── dictate           # Main CLI
│   ├── voice-toggle      # Toggle mode
│   ├── voice-ptt         # Push-to-talk daemon
│   └── ptt               # Secure PTT wrapper
├── lib/core/             # Core implementations
│   ├── dictate.sh        # Original script
│   ├── toggle.sh         # Toggle logic
│   └── ptt.py           # PTT daemon
├── data/                 # Runtime data
│   ├── models/          # Whisper models
│   └── recordings/      # Temp audio
├── setup/               # Installation
│   └── install.sh       # Setup script
├── test/                # Test scripts
├── docs/                # Documentation
└── Makefile            # Build system
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

- **Toggle mode** - Recording with GNOME notifications (Alt+Shift+V)
- **Push-to-talk** - Hold Right Alt to record (no sudo needed!)
- **Auto-typing** - Types transcribed text with ydotool
- **PipeWire/PulseAudio** - Reliable audio capture with fallbacks
- **Wayland/GNOME native** - Full support on modern systems
- **Clean output** - No ANSI color codes in transcription

## 🔧 Troubleshooting

### Push-to-talk not working?
```bash
# 1. Make sure you're in the input group
groups | grep input

# 2. Start ydotool daemon for typing
- `ydotoold &`  # Have it run in the background
- `ydotoold`    # Or have it run in the foreground in another terminal

# 3. Check if socket exists
ls -la /run/user/$UID/.ydotool_socket
```

### Audio recording fails?
```bash
# Fix PulseAudio runtime directory (if owned by root)
sudo chown -R $USER:$USER /run/user/$UID

# Test PipeWire/PulseAudio
pactl info  # Should show server info without errors
```

### "No speech detected"?
- Speak louder or closer to microphone
- Check microphone volume: `pavucontrol`
- Test recording: `parecord --channels=1 --rate=16000 --format=s16le test.wav`

### Transcription inaccurate?
- Speak clearly, normal pace
- Reduce background noise
- Consider `small.en` model for better accuracy

## 📊 Performance

- **Model**: base.en (142MB, English-optimized)
- **Speed**: ~3-5 seconds for 10 seconds of audio
- **RAM**: ~1-2GB during transcription
- **CPU**: 4 cores recommended (works on i7-4710HQ)

## 🧪 Tested Configuration

**Known Working Setup:**
- **OS**: Fedora 42 with GNOME on Wayland
- **Audio**: PipeWire (with PulseAudio compatibility)
- **Hardware**: Multiple keyboards detected automatically
- **Microphone**: ALC3239 Analog (card 1, device 0)
- **Typing**: ydotool with user-level daemon

**Key Success Factors:**
- User in `input` group (no sudo needed)
- ydotoold running as user (not system service)
- PipeWire runtime directory owned by user
- Right Alt key for push-to-talk

## 🔒 Privacy & Security

- **100% Offline**: No internet required after setup
- **Local Processing**: All transcription on your machine
- **No Telemetry**: Zero tracking or analytics
- **Auto-cleanup**: Temporary recordings deleted after use

## 💡 Tips

1. **For meetings**: Use toggle mode with `Alt+Shift+V`
2. **For coding**: Push-to-talk with `Right Alt` (most natural)
3. **For long text**: Manual mode with `dictate -m`
4. **Quick test**: `dictate -p` to print only
5. **Voice clarity**: Speak at normal pace, reduce background noise
6. **Multiple keyboards**: System auto-detects and lets you choose

## 🐛 Known Issues

- ~~Push-to-talk requires sudo~~ ✅ **SOLVED**: Use input group
- ~~GNOME blocks global hotkeys~~ ✅ **SOLVED**: Use toggle mode with Alt+Shift+V
- First transcription may be slower (model loading - normal)
- wtype doesn't work on GNOME/Mutter (use ydotool instead)

## 📚 Documentation

- [Setup Shortcuts Guide](SETUP_SHORTCUTS.md) - Detailed setup instructions
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) - Transcription engine
- [OpenAI Whisper](https://github.com/openai/whisper) - Original model

## 🙏 Credits

- **Whisper** by OpenAI - Speech recognition model
- **whisper.cpp** by Georgi Gerganov - C++ implementation  
- **PipeWire/PulseAudio** - Modern audio architecture
- Built with **Claude Code** for improved developer experience

## 🎉 Success Story

This system was built from scratch through collaborative problem-solving, evolving from a simple terminal voice input idea to a professional-grade dictation system. Key challenges overcome:

- **Audio permissions** on modern Linux (PipeWire/Wayland)
- **Keyboard monitoring** without sudo (input group approach)
- **Clean transcription** output (ANSI code removal)
- **Professional architecture** (proper Unix directory structure)

**The result**: A complete voice dictation system that's offline, private, and performs as well as commercial alternatives.

## 📄 License

MIT License - Use freely, modify as needed.

---

*Voice control your Linux desktop. Type with your voice. Stay in flow.* 🎤