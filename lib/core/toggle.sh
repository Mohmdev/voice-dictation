#!/bin/bash

# Voice Dictation Toggle Script
# Can be bound to a single key in GNOME or terminal
# Press once to start recording, press again to stop and transcribe

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
WHISPER_BIN="$HOME/workspace/whisper.cpp/build/bin/whisper-cli"
MODEL_PATH="$PROJECT_ROOT/data/models/ggml-base.en.bin"
RECORDINGS_DIR="$PROJECT_ROOT/data/recordings"
LOCK_FILE="/tmp/voice_dictation.lock"
PID_FILE="/tmp/voice_dictation.pid"
AUDIO_FILE="/tmp/voice_dictation.wav"

# Check if already recording
if [ -f "$LOCK_FILE" ]; then
    # Stop recording
    echo "Stopping recording..."
    
    # Get PID and kill recording process
    if [ -f "$PID_FILE" ]; then
        RECORD_PID=$(cat "$PID_FILE")
        kill $RECORD_PID 2>/dev/null
        rm -f "$PID_FILE"
    fi
    
    # Remove lock
    rm -f "$LOCK_FILE"
    
    # Wait a moment for file to be written
    sleep 0.5
    
    # Transcribe
    if [ -f "$AUDIO_FILE" ]; then
        echo "Transcribing..."
        
        # Run whisper
        OUTPUT=$("$WHISPER_BIN" \
            -m "$MODEL_PATH" \
            -f "$AUDIO_FILE" \
            --no-timestamps \
            --print-colors false \
            --print-special false \
            --print-progress false \
            -l en \
            -t 4 \
            2>/dev/null | tail -n 1 | sed 's/\x1b\[[0-9;]*m//g; s/<|endoftext|>//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
        
        if [ -n "$OUTPUT" ]; then
            echo "Transcribed: $OUTPUT"
            
            # Try to type the text
            typed=false
            
            # Try wtype first (best for Wayland)
            if command -v wtype &> /dev/null; then
                sleep 0.3  # Give time to focus target window
                if wtype "$OUTPUT" 2>/dev/null; then
                    typed=true
                fi
            fi
            
            # Try ydotool if wtype failed
            if [ "$typed" = false ] && command -v ydotool &> /dev/null && [ -S "/run/user/$(id -u)/.ydotool_socket" ]; then
                if ydotool type "$OUTPUT" 2>/dev/null; then
                    typed=true
                fi
            fi
            
            # Try xdotool if both failed
            if [ "$typed" = false ] && command -v xdotool &> /dev/null; then
                sleep 0.3
                if xdotool type "$OUTPUT" 2>/dev/null; then
                    typed=true
                fi
            fi
            
            # Fall back to clipboard if typing failed
            if [ "$typed" = false ]; then
                if command -v wl-copy &> /dev/null; then
                    echo -n "$OUTPUT" | wl-copy
                    notify-send "Voice Dictation" "Text copied to clipboard (Ctrl+V to paste)"
                elif command -v xclip &> /dev/null; then
                    echo -n "$OUTPUT" | xclip -selection clipboard
                    notify-send "Voice Dictation" "Text copied to clipboard (Ctrl+V to paste)"
                else
                    echo "$OUTPUT"
                fi
            fi
        else
            notify-send "Voice Dictation" "No speech detected"
        fi
        
        # Clean up
        rm -f "$AUDIO_FILE"
    fi
else
    # Start recording
    echo "Starting recording..."
    touch "$LOCK_FILE"
    
    # Start recording in background
    parecord --channels=1 --rate=16000 --format=s16le "$AUDIO_FILE" &
    RECORD_PID=$!
    echo $RECORD_PID > "$PID_FILE"
    
    # Send notification
    notify-send "Voice Dictation" "🎤 Recording... Press hotkey again to stop"
fi