#!/bin/bash

# Voice Dictation Script using Whisper.cpp
# Records audio and transcribes it to text

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WHISPER_PATH="$HOME/workspace/whisper.cpp"
WHISPER_BIN="$WHISPER_PATH/build/bin/whisper-cli"
MODEL_PATH="$PROJECT_ROOT/models/ggml-base.en.bin"
RECORDINGS_DIR="$PROJECT_ROOT/recordings"
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

# Record audio using sox
record_audio() {
    echo -e "${YELLOW}Recording... (speak clearly, press Ctrl+C when done)${NC}"
    
    # Record with automatic silence detection
    # Stops recording after 1 second of silence
    sox -d -r 16000 -c 1 -b 16 "$TEMP_AUDIO" silence 1 0.1 1% 1 1.0 1%
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Recording failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Recording complete${NC}"
    return 0
}

# Record audio with manual stop
record_audio_manual() {
    echo -e "${YELLOW}Recording... (press Ctrl+C to stop)${NC}"
    
    # Record until user interrupts
    sox -d -r 16000 -c 1 -b 16 "$TEMP_AUDIO"
    
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
        -t 4 \
        2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*//')
    
    if [ -z "$OUTPUT" ]; then
        echo -e "${RED}Transcription failed or no speech detected${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Transcription: ${NC}$OUTPUT"
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
        echo "$OUTPUT"
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

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Stopping recording...${NC}"; exit 0' INT

# Run main function
main "$@"