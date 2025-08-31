#!/bin/bash

echo "=== PulseAudio Microphone Test ==="
echo ""
echo "This will record 3 seconds using PulseAudio"
echo "Press Enter when ready..."
read

TEST_FILE="/tmp/pulse_test.wav"

echo "🎤 RECORDING for 3 seconds... SPEAK NOW!"
echo "(Say something like 'Testing 1 2 3')"

# Record using PulseAudio
parecord --channels=1 --rate=16000 --format=s16le --latency-msec=10 "$TEST_FILE" &
RECORD_PID=$!
sleep 3
kill $RECORD_PID 2>/dev/null

echo "✅ Recording done!"
echo ""

# Check file
if [ -f "$TEST_FILE" ]; then
    SIZE=$(stat -c%s "$TEST_FILE" 2>/dev/null)
    echo "Audio file: $(ls -lh $TEST_FILE)"
    
    if [ "$SIZE" -gt 10000 ]; then
        echo "🔊 Playing back..."
        paplay "$TEST_FILE"
        
        echo ""
        echo "Testing Whisper transcription..."
        
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
            echo "❌ No speech detected"
        else
            echo "✅ Whisper heard: $RESULT"
        fi
    else
        echo "❌ File too small, microphone might be muted"
    fi
else
    echo "❌ Recording failed"
fi

rm -f "$TEST_FILE"