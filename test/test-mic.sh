#!/bin/bash

echo "=== Microphone Test ==="
echo ""
echo "This will record 3 seconds and play it back to you"
echo "Press Enter when ready..."
read

TEST_FILE="/tmp/mic_test.wav"

echo "🎤 RECORDING for 3 seconds... SPEAK LOUDLY NOW!"
echo "(Say something like 'Testing 1 2 3')"

# Record using the specific audio card
arecord -D hw:1,0 -f cd -d 3 "$TEST_FILE" 2>/dev/null

echo "✅ Recording done!"
echo ""

# Check file size
SIZE=$(stat -c%s "$TEST_FILE" 2>/dev/null)
if [ "$SIZE" -gt 1000 ]; then
    echo "Audio file created: $(ls -lh $TEST_FILE)"
    echo ""
    echo "🔊 Playing back your recording..."
    aplay "$TEST_FILE" 2>/dev/null
    echo ""
    echo "Did you hear your voice? (y/n)"
    read RESPONSE
    
    if [ "$RESPONSE" = "y" ]; then
        echo "✅ Great! Microphone is working!"
        echo ""
        echo "Now let's test if Whisper can transcribe it..."
        
        WHISPER_BIN="$HOME/workspace/whisper.cpp/build/bin/whisper-cli"
        MODEL_PATH="$HOME/workspace/voice-dictation/models/ggml-base.en.bin"
        
        RESULT=$("$WHISPER_BIN" \
            -m "$MODEL_PATH" \
            -f "$TEST_FILE" \
            --no-timestamps \
            --print-colors false \
            --print-special false \
            --print-progress false \
            -t 4 \
            2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*//')
        
        if [ -z "$RESULT" ]; then
            echo "❌ Whisper couldn't transcribe. Audio might be too quiet."
        else
            echo "✅ Whisper heard: $RESULT"
        fi
    else
        echo "❌ Microphone issue detected. Let's try different settings..."
        echo ""
        echo "Try running this command manually:"
        echo "arecord -D pulse -f cd -d 3 test.wav"
        echo "Then: aplay test.wav"
    fi
else
    echo "❌ No audio recorded. Microphone might be muted or disabled."
    echo ""
    echo "Check:"
    echo "1. Is your microphone physically connected?"
    echo "2. Run: alsamixer"
    echo "   - Press F4 for Capture"
    echo "   - Check if Mic is enabled (not muted)"
    echo "   - Adjust volume with arrow keys"
fi

rm -f "$TEST_FILE"