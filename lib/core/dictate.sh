#!/bin/bash

# Voice Dictation Script using Whisper.cpp
# Records audio and transcribes it to text

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
WHISPER_PATH="$HOME/workspace/whisper.cpp"
WHISPER_BIN="$WHISPER_PATH/build/bin/whisper-cli"
MODEL_PATH="$PROJECT_ROOT/data/models/ggml-base.en.bin"
RECORDINGS_DIR="$PROJECT_ROOT/data/recordings"
TEMP_AUDIO="$RECORDINGS_DIR/temp_recording.wav"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check dependencies
check_dependencies() {
    local missing=()
    
    if ! command -v sox &> /dev/null; then
        missing+=("sox")
    fi
    
    if [ ! -f "$WHISPER_BIN" ]; then
        missing+=("whisper-cli (not found at $WHISPER_BIN)")
    fi
    
    if [ ! -f "$MODEL_PATH" ]; then
        missing+=("Whisper model (not found at $MODEL_PATH)")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing dependencies:${NC}"
        printf '%s\n' "${missing[@]}"
        exit 1
    fi
}

# Record audio using parecord with timeout
record_audio() {
    echo -e "${YELLOW}Recording... (speak clearly, will stop after 10 seconds or press Ctrl+C)${NC}"
    
    # Record with timeout using PulseAudio
    parecord --channels=1 --rate=16000 --format=s16le "$TEMP_AUDIO" &
    RECORD_PID=$!
    
    # Wait for up to 10 seconds or until user interrupts
    sleep 10
    
    # Stop recording if still running
    if kill -0 $RECORD_PID 2>/dev/null; then
        kill $RECORD_PID 2>/dev/null
    fi
    
    wait $RECORD_PID 2>/dev/null
    
    if [ ! -f "$TEMP_AUDIO" ] || [ ! -s "$TEMP_AUDIO" ]; then
        echo -e "${RED}Recording failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Recording complete${NC}"
    return 0
}

# Record audio with manual stop
record_audio_manual() {
    echo -e "${YELLOW}Recording... (press Ctrl+C to stop)${NC}"
    
    # Set flag to indicate we're recording
    MANUAL_RECORDING=true
    
    # Record until user interrupts using PulseAudio
    parecord --channels=1 --rate=16000 --format=s16le "$TEMP_AUDIO"
    
    echo -e "${GREEN}Recording complete${NC}"
    return 0
}

# Transcribe audio using whisper
transcribe_audio() {
    echo -e "${YELLOW}Transcribing...${NC}"
    
    # Run whisper with optimized settings
    OUTPUT=$("$WHISPER_BIN" \
        -m "$MODEL_PATH" \
        -f "$TEMP_AUDIO" \
        --no-timestamps \
        --print-colors false \
        --print-special false \
        --print-progress false \
        -l en \
        -t 4 \
        2>/dev/null | tail -n 1 | sed 's/\x1b\[[0-9;]*m//g; s/<|endoftext|>//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
    
    if [ -z "$OUTPUT" ]; then
        echo -e "${RED}Transcription failed or no speech detected${NC}"
        return 1
    fi
    
    # Don't echo here - let main() handle output
    return 0
}

# Type the transcribed text (requires xdotool)
type_text() {
    local text="$1"
    
    if command -v xdotool &> /dev/null; then
        echo -e "${YELLOW}Typing text...${NC}"
        sleep 0.5  # Give time to switch windows if needed
        xdotool type "$text"
        echo -e "${GREEN}Text typed${NC}"
    else
        echo -e "${YELLOW}xdotool not installed. Text copied to clipboard if xclip is available${NC}"
        if command -v xclip &> /dev/null; then
            echo -n "$text" | xclip -selection clipboard
            echo -e "${GREEN}Text copied to clipboard${NC}"
        else
            echo -e "${YELLOW}Install xdotool or xclip for automatic typing/copying${NC}"
        fi
    fi
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Voice dictation tool using Whisper.cpp

OPTIONS:
    -h, --help          Show this help message
    -m, --manual        Manual recording (press Ctrl+C to stop)
    -c, --copy-only     Only copy to clipboard, don't type
    -p, --print-only    Only print to stdout, don't type or copy
    -t, --timeout SEC   Recording timeout in seconds (default: no timeout)
    
EXAMPLES:
    $0                  # Record with auto-stop on silence and type text
    $0 -m               # Manual recording mode
    $0 -p               # Record and print transcription only
    $0 -c               # Record and copy to clipboard

EOF
}

# Main function
main() {
    local manual_mode=false
    local copy_only=false
    local print_only=false
    local timeout=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -m|--manual)
                manual_mode=true
                shift
                ;;
            -c|--copy-only)
                copy_only=true
                shift
                ;;
            -p|--print-only)
                print_only=true
                shift
                ;;
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # Create recordings directory if it doesn't exist
    mkdir -p "$RECORDINGS_DIR"
    
    # Set up trap to clean up on exit
    trap "rm -f $TEMP_AUDIO" EXIT
    
    # Record audio
    if [ "$manual_mode" = true ]; then
        record_audio_manual
    else
        record_audio
    fi
    
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Transcribe audio
    transcribe_audio
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Handle output based on mode
    if [ "$print_only" = true ]; then
        echo -e "${GREEN}Transcription:${NC} $OUTPUT"
    elif [ "$copy_only" = true ]; then
        if command -v xclip &> /dev/null; then
            echo -n "$OUTPUT" | xclip -selection clipboard
            echo -e "${GREEN}Text copied to clipboard${NC}"
        else
            echo -e "${RED}xclip not installed${NC}"
            echo "$OUTPUT"
        fi
    else
        type_text "$OUTPUT"
    fi
}

# Handle Ctrl+C gracefully - but only exit if not in recording
MANUAL_RECORDING=false
trap 'if [ "$MANUAL_RECORDING" = true ]; then echo -e "\n${YELLOW}Stopping recording...${NC}"; MANUAL_RECORDING=false; else exit 0; fi' INT

# Run main function
main "$@"