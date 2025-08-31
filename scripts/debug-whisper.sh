#!/bin/bash

echo "=== Whisper Debug Test ==="
echo ""
echo "1. Record 5 seconds of audio"
echo "2. Save it for testing"
echo "3. Test different Whisper settings"
echo ""
echo "Press Enter to start..."
read

SAVE_FILE="$HOME/workspace/voice-dictation/recordings/debug_audio.wav"
WHISPER_BIN="$HOME/workspace/whisper.cpp/build/bin/whisper-cli"
MODEL_PATH="$HOME/workspace/voice-dictation/models/ggml-base.en.bin"

echo "🎤 RECORDING for 5 seconds... SPEAK CLEARLY!"
echo "Say: 'Hello world, testing one two three'"

# Record with PulseAudio
parecord --channels=1 --rate=16000 --format=s16le "$SAVE_FILE" &
RECORD_PID=$!
sleep 5
kill $RECORD_PID 2>/dev/null

echo "✅ Recording saved to: $SAVE_FILE"
echo ""

# Check file
echo "File info:"
file "$SAVE_FILE"
ls -lh "$SAVE_FILE"
echo ""

echo "🔊 Playing back your recording..."
paplay "$SAVE_FILE"
echo ""

echo "=== Testing Whisper ==="
echo ""

# Test 1: Direct whisper command with visible output
echo "Test 1: Running Whisper with full output..."
"$WHISPER_BIN" -m "$MODEL_PATH" -f "$SAVE_FILE" -l en --print-progress false

echo ""
echo "----------------------------------------"
echo ""

# Test 2: Try with different parameters
echo "Test 2: Running with minimal parameters..."
"$WHISPER_BIN" -m "$MODEL_PATH" -f "$SAVE_FILE" --no-timestamps 2>&1 | grep -v "^whisper_" | tail -5

echo ""
echo "----------------------------------------"
echo ""

# Test 3: Convert to different format and try
echo "Test 3: Converting audio format and testing..."
CONVERTED="$HOME/workspace/voice-dictation/recordings/debug_converted.wav"
ffmpeg -i "$SAVE_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$CONVERTED" -y 2>/dev/null || sox "$SAVE_FILE" -r 16000 -c 1 -b 16 "$CONVERTED"

if [ -f "$CONVERTED" ]; then
    "$WHISPER_BIN" -m "$MODEL_PATH" -f "$CONVERTED" --no-timestamps 2>&1 | grep -v "^whisper_" | tail -5
else
    echo "Conversion failed, skipping test 3"
fi

echo ""
echo "=== Debug Complete ==="
echo ""
echo "Audio files saved in recordings/ folder for further testing"
echo "If you heard your voice but Whisper shows nothing, the audio might be:"
echo "1. Too quiet (try speaking louder)"
echo "2. Wrong format (we'll fix this)"
echo "3. Model issue (we can try a different model)"