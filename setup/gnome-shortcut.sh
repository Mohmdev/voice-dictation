#!/bin/bash

# Set up GNOME custom keyboard shortcut for voice dictation

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "GNOME Voice Dictation Shortcut Setup"
echo "====================================="
echo ""
echo "Choose your preferred shortcut:"
echo "1) Alt+Shift+V  (Recommended - won't conflict with push-to-talk)"
echo "2) Super+Shift+V"
echo "3) Alt+V"
echo "4) Custom"
echo ""
read -p "Enter choice (1-4): " CHOICE

case $CHOICE in
    1)
        SHORTCUT="<Alt><Shift>v"
        KEYS="Alt+Shift+V"
        ;;
    2)
        SHORTCUT="<Super><Shift>v"
        KEYS="Super+Shift+V"
        ;;
    3)
        SHORTCUT="<Alt>v"
        KEYS="Alt+V"
        ;;
    4)
        echo "Enter custom shortcut in GNOME format (e.g., <Alt>slash, <Super><Shift>v):"
        read SHORTCUT
        KEYS="$SHORTCUT"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Determine command path
if [ -f "$HOME/.local/bin/voice-toggle" ]; then
    COMMAND="$HOME/.local/bin/voice-toggle"
elif [ -f "$HOME/workspace/voice-dictation/bin/voice-toggle" ]; then
    COMMAND="$HOME/workspace/voice-dictation/bin/voice-toggle"
else
    echo -e "${YELLOW}Warning: voice-toggle not found. Using path after installation.${NC}"
    COMMAND="$HOME/.local/bin/voice-toggle"
fi

echo ""
echo "Setting up shortcut: $KEYS"
echo "Command: $COMMAND"
echo ""

# Create the custom shortcut
CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$CUSTOM_PATH/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH/custom0/ name "Voice Dictation"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH/custom0/ command "$COMMAND"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH/custom0/ binding "$SHORTCUT"

echo -e "${GREEN}✓ Shortcut configured!${NC}"
echo ""
echo "Usage:"
echo "  1. Press $KEYS to start recording"
echo "  2. Speak your text"
echo "  3. Press $KEYS again to stop and type"
echo ""
echo "The text will be typed with wtype (you installed it!)"