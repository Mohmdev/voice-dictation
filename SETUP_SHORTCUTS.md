# Voice Dictation Shortcut Setup

## Option 1: Toggle Mode (Easier - No sudo required)

This mode uses a single key press to start/stop recording.

### Setup GNOME Keyboard Shortcut:

1. Open **Settings** → **Keyboard** → **View and Customize Shortcuts**
2. Scroll to bottom and click **Custom Shortcuts**
3. Click **Add Shortcut** (+)
4. Fill in:
   - **Name**: Voice Dictation Toggle
   - **Command**: `/home/$USER/workspace/voice-dictation/scripts/voice-toggle.sh`
   - **Shortcut**: Click "Set Shortcut" and press your desired key combo
     - Recommended: `Super+V` or `Alt+/` or `F8`

### How to use:
- Press your hotkey once → starts recording (notification appears)
- Press hotkey again → stops, transcribes, and types text

## Option 2: Push-to-Talk Mode (Hold key to record)

This requires running a daemon with sudo access.

### Install Python evdev:
```bash
pip install evdev
# or
sudo dnf install python3-evdev
```

### Test the daemon:
```bash
sudo python3 ~/workspace/voice-dictation/scripts/push-to-talk.py
```

### Create systemd service (optional):
```bash
# Create service file
sudo tee /etc/systemd/system/voice-ptt.service << EOF
[Unit]
Description=Voice Push-to-Talk Daemon
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $HOME/workspace/voice-dictation/scripts/push-to-talk.py
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable voice-ptt.service
sudo systemctl start voice-ptt.service
```

### How to use:
- Hold `Alt+/` → recording starts
- Release `Alt+/` → stops, transcribes, types text

## Option 3: Terminal Alias (Quick access)

Add to your `~/.bashrc`:
```bash
# Voice dictation toggle
alias vd='~/workspace/voice-dictation/scripts/voice-toggle.sh'

# Manual dictation
alias dictate='~/workspace/voice-dictation/scripts/dictate.sh -m -p'
```

Then use:
- Type `vd` + Enter → start/stop recording
- Type `dictate` + Enter → manual mode

## Installing Typing Tools

For text to be automatically typed (not just copied):

### Wayland (recommended for GNOME):
```bash
# Install ydotool
sudo dnf install ydotool

# Start ydotool daemon
sudo systemctl enable ydotool
sudo systemctl start ydotool
```

### Fallback clipboard tools:
```bash
# Wayland clipboard
sudo dnf install wl-clipboard

# X11 clipboard (backup)
sudo dnf install xclip
```

## Testing Your Setup

1. Test toggle mode:
```bash
~/workspace/voice-dictation/scripts/voice-toggle.sh
# Speak something
~/workspace/voice-dictation/scripts/voice-toggle.sh
```

2. Test with your shortcut key
3. Open a text editor and try dictating

## Troubleshooting

### No text appearing?
- Install ydotool for Wayland: `sudo dnf install ydotool`
- Check clipboard: the text might be copied instead of typed
- Run script manually to see error messages

### Recording not working?
- Check mic volume: `pavucontrol`
- Test recording: `parecord test.wav` (Ctrl+C to stop)
- Play back: `paplay test.wav`

### Shortcut not working?
- Make sure script is executable: `chmod +x ~/workspace/voice-dictation/scripts/*.sh`
- Test script directly in terminal first
- Check GNOME shortcut is not conflicting with another

## Tips

- Speak clearly and at normal pace
- Wait for notification before speaking
- For toggle mode, wait 1-2 seconds between presses
- Push-to-talk needs sudo but is more natural
- Toggle mode works without sudo and is easier to set up