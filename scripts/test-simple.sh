#!/bin/bash

echo "=== Simple Voice Test ==="
echo "This will:"
echo "1. Record for 5 seconds"
echo "2. Transcribe what you said"
echo ""
echo "Ready? Press Enter to start recording..."
read

WHISPER_BIN="$HOME/workspace/whisper.cpp/build/bin/whisper-cli"
MODEL_PATH="$HOME/workspace/voice-dictation/models/ggml-base.en.bin"
TEMP_AUDIO="/tmp/test_audio.wav"

echo "🎤 RECORDING for 5 seconds... SPEAK NOW!"
timeout 5 sox -d -r 16000 -c 1 -b 16 "$TEMP_AUDIO" 2>/dev/null

echo "✅ Recording done!"
echo ""
echo "🔄 Transcribing..."

# Run whisper
RESULT=$("$WHISPER_BIN" \
    -m "$MODEL_PATH" \
    -f "$TEMP_AUDIO" \
    --no-timestamps \
    --print-colors false \
    --print-special false \
    --print-progress false \
    -t 4 \
    2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*//')

echo ""
if [ -z "$RESULT" ]; then
    echo "❌ No speech detected or transcription failed"
    echo "Troubleshooting:"
    echo "- Was your microphone on?"
    echo "- Did you speak during the 5 seconds?"
    echo "- Let's check the audio file size:"
    ls -lh "$TEMP_AUDIO" 2>/dev/null || echo "Audio file not created!"
else
    echo "✅ You said: $RESULT"
fi

# Clean up
rm -f "$TEMP_AUDIO"