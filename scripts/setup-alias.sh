#!/bin/bash

# Setup script to add voice dictation alias to bashrc

SCRIPT_PATH="$HOME/workspace/voice-dictation/scripts/dictate.sh"
ALIAS_NAME="dictate"

echo "Setting up voice dictation alias..."

# Check if alias already exists
if grep -q "alias $ALIAS_NAME=" ~/.bashrc; then
    echo "Alias '$ALIAS_NAME' already exists in ~/.bashrc"
    echo "Updating it..."
    sed -i "/alias $ALIAS_NAME=/d" ~/.bashrc
fi

# Add alias to bashrc
echo "" >> ~/.bashrc
echo "# Voice dictation alias" >> ~/.bashrc
echo "alias $ALIAS_NAME='$SCRIPT_PATH'" >> ~/.bashrc

echo "✓ Added alias '$ALIAS_NAME' to ~/.bashrc"
echo ""
echo "To use it, either:"
echo "  1. Restart your terminal, or"
echo "  2. Run: source ~/.bashrc"
echo ""
echo "Then you can use:"
echo "  dictate           # Record and transcribe"
echo "  dictate -m        # Manual recording mode"
echo "  dictate -p        # Print only mode"
echo "  dictate --help    # Show all options"