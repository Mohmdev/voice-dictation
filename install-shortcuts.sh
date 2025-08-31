#!/bin/bash

# Voice Dictation Shortcut Installer
# Sets up keyboard shortcuts for voice dictation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Voice Dictation Shortcut Setup"
echo "==============================="
echo ""

# Check dependencies
echo "Checking dependencies..."

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 found"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not found"
        return 1
    fi
}

# Required commands
check_command parecord || echo "  Install with: sudo dnf install pulseaudio-utils"

# Optional but recommended
echo ""
echo "Optional tools for auto-typing:"
HAS_TYPING=false

if check_command ydotool; then
    HAS_TYPING=true
    echo -e "${GREEN}  Wayland typing supported${NC}"
elif check_command xdotool; then
    HAS_TYPING=true
    echo -e "${YELLOW}  X11 typing supported (may not work on Wayland)${NC}"
fi

if check_command wl-copy; then
    echo -e "${GREEN}  Wayland clipboard supported${NC}"
elif check_command xclip; then
    echo -e "${YELLOW}  X11 clipboard supported${NC}"
else
    echo -e "${RED}  No clipboard tool found${NC}"
    echo "  Install with: sudo dnf install wl-clipboard"
fi

if [ "$HAS_TYPING" = false ]; then
    echo ""
    echo -e "${YELLOW}Warning: No typing tool found. Text will be copied to clipboard instead.${NC}"
    echo "To enable auto-typing on Wayland, install ydotool:"
    echo "  sudo dnf install ydotool"
fi

echo ""
echo "Setup Options:"
echo "--------------"
echo "1. Add GNOME keyboard shortcut (GUI setup required)"
echo "2. Add terminal alias for quick access"
echo "3. Install push-to-talk daemon (requires sudo)"
echo "4. Just show me the manual instructions"
echo ""
read -p "Choose option (1-4): " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "Setting up GNOME shortcut..."
        echo ""
        
        # Create custom shortcut using gsettings
        SHORTCUT_PATH="/home/$USER/workspace/voice-dictation/scripts/voice-toggle.sh"
        
        echo "I'll open GNOME Settings for you to add the shortcut manually."
        echo ""
        echo "When Settings opens:"
        echo "1. Go to Keyboard → View and Customize Shortcuts"
        echo "2. Scroll down to 'Custom Shortcuts'"
        echo "3. Click '+' to add new shortcut"
        echo "4. Set:"
        echo "   Name: Voice Dictation"
        echo "   Command: $SHORTCUT_PATH"
        echo "   Shortcut: Super+V (or your preference)"
        echo ""
        read -p "Press Enter to open Settings..."
        
        gnome-control-center keyboard &
        
        echo ""
        echo -e "${GREEN}After adding the shortcut, you can use it to toggle voice recording!${NC}"
        ;;
        
    2)
        echo ""
        echo "Adding terminal aliases..."
        
        # Check if aliases already exist
        if grep -q "alias vd=" ~/.bashrc; then
            echo "Aliases already exist in ~/.bashrc"
        else
            echo "" >> ~/.bashrc
            echo "# Voice dictation aliases" >> ~/.bashrc
            echo "alias vd='$SCRIPT_DIR/scripts/voice-toggle.sh'" >> ~/.bashrc
            echo "alias dictate='$SCRIPT_DIR/scripts/dictate.sh -m'" >> ~/.bashrc
            echo -e "${GREEN}✓ Added aliases to ~/.bashrc${NC}"
            echo ""
            echo "Run 'source ~/.bashrc' or restart terminal to use:"
            echo "  vd       - Toggle voice recording"
            echo "  dictate  - Manual dictation mode"
        fi
        ;;
        
    3)
        echo ""
        echo "Setting up push-to-talk daemon..."
        echo ""
        
        # Check for python3-evdev
        if python3 -c "import evdev" 2>/dev/null; then
            echo -e "${GREEN}✓ python3-evdev installed${NC}"
        else
            echo "Installing python3-evdev..."
            pip install evdev || sudo dnf install python3-evdev
        fi
        
        echo ""
        echo "To test push-to-talk (requires sudo):"
        echo "  sudo python3 $SCRIPT_DIR/scripts/push-to-talk.py"
        echo ""
        echo "Hold Alt+/ to record, release to transcribe"
        echo ""
        
        read -p "Do you want to create a systemd service? (y/n): " CREATE_SERVICE
        
        if [ "$CREATE_SERVICE" = "y" ]; then
            cat << EOF | sudo tee /etc/systemd/system/voice-ptt.service
[Unit]
Description=Voice Push-to-Talk Daemon
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $SCRIPT_DIR/scripts/push-to-talk.py
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF
            
            sudo systemctl daemon-reload
            echo ""
            echo "Service created. To enable and start:"
            echo "  sudo systemctl enable voice-ptt.service"
            echo "  sudo systemctl start voice-ptt.service"
        fi
        ;;
        
    4)
        echo ""
        echo "Manual setup instructions are in:"
        echo "  $SCRIPT_DIR/SETUP_SHORTCUTS.md"
        echo ""
        echo "Quick test commands:"
        echo "  $SCRIPT_DIR/scripts/voice-toggle.sh    # Toggle recording"
        echo "  $SCRIPT_DIR/scripts/dictate.sh -p      # Print mode test"
        ;;
esac

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Quick reference:"
echo "  Toggle script: $SCRIPT_DIR/scripts/voice-toggle.sh"
echo "  Manual mode:   $SCRIPT_DIR/scripts/dictate.sh -m"
echo "  Push-to-talk:  sudo python3 $SCRIPT_DIR/scripts/push-to-talk.py"
echo ""
echo "For more help, see SETUP_SHORTCUTS.md"