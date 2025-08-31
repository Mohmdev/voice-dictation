#!/usr/bin/env python3
"""
Push-to-Talk Voice Dictation Daemon
Monitors keyboard for Alt+/ hold to record, transcribes on release
Works on Wayland/GNOME using evdev (requires sudo)
"""

import os
import sys
import time
import signal
import subprocess
import threading
import tempfile
from pathlib import Path
from typing import Optional

try:
    import evdev
    from evdev import InputDevice, categorize, ecodes
except ImportError:
    print("Error: python3-evdev not installed")
    print("Install with: pip install evdev")
    sys.exit(1)

# Configuration
WHISPER_BIN = Path.home() / "workspace/whisper.cpp/build/bin/whisper-cli"
MODEL_PATH = Path.home() / "workspace/voice-dictation/data/models/ggml-base.en.bin"
RECORDINGS_DIR = Path.home() / "workspace/voice-dictation/data/recordings"

# Key configuration (Alt + /)
MODIFIER_KEY = ecodes.KEY_LEFTALT  # or KEY_RIGHTALT
TRIGGER_KEY = ecodes.KEY_SLASH

class PushToTalkDaemon:
    def __init__(self):
        self.recording = False
        self.recording_process = None
        self.temp_audio = None
        self.alt_pressed = False
        self.slash_pressed = False
        
        # Ensure recordings directory exists
        RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)
        
        # Find keyboard device
        self.keyboard = self.find_keyboard()
        if not self.keyboard:
            print("Error: No keyboard found. Make sure you're running with sudo.")
            sys.exit(1)
        
        print(f"Using keyboard: {self.keyboard.name}")
        print("Push-to-Talk ready! Hold Alt+/ to record, release to transcribe.")
        print("Press Ctrl+C to exit.")
    
    def find_keyboard(self) -> Optional[InputDevice]:
        """Find the first keyboard device"""
        devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
        for device in devices:
            capabilities = device.capabilities(verbose=True)
            # Check if device has KEY events and common keyboard keys
            if ('EV_KEY', 1) in capabilities:
                keys = capabilities[('EV_KEY', 1)]
                # Check for alphabetic keys to identify keyboard
                if any('KEY_A' in str(key) for key in keys):
                    return device
        return None
    
    def start_recording(self):
        """Start audio recording"""
        if self.recording:
            return
        
        self.recording = True
        self.temp_audio = tempfile.NamedTemporaryFile(
            suffix='.wav', 
            dir=RECORDINGS_DIR, 
            delete=False
        )
        
        print("\n🎤 Recording... (release Alt+/ to stop)")
        
        # Start recording with parecord
        cmd = [
            'parecord',
            '--channels=1',
            '--rate=16000',
            '--format=s16le',
            self.temp_audio.name
        ]
        
        self.recording_process = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    
    def stop_recording_and_transcribe(self):
        """Stop recording and transcribe the audio"""
        if not self.recording or not self.recording_process:
            return
        
        self.recording = False
        
        # Stop recording
        self.recording_process.terminate()
        self.recording_process.wait(timeout=1)
        
        print("⏹️  Stopped recording")
        print("🔄 Transcribing...")
        
        # Transcribe with whisper
        cmd = [
            str(WHISPER_BIN),
            '-m', str(MODEL_PATH),
            '-f', self.temp_audio.name,
            '--no-timestamps',
            '--print-colors', 'false',
            '--print-special', 'false',
            '--print-progress', 'false',
            '-l', 'en',
            '-t', '4'
        ]
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=10
            )
            
            # Extract transcription from output
            lines = result.stdout.strip().split('\n')
            if lines:
                # Get last non-empty line and clean it
                transcription = lines[-1].strip()
                transcription = transcription.replace('<|endoftext|>', '').strip()
                
                if transcription:
                    print(f"✅ Transcribed: {transcription}")
                    self.type_text(transcription)
                else:
                    print("❌ No speech detected")
            else:
                print("❌ Transcription failed")
                
        except subprocess.TimeoutExpired:
            print("❌ Transcription timeout")
        except Exception as e:
            print(f"❌ Error: {e}")
        finally:
            # Clean up temp file
            if self.temp_audio and os.path.exists(self.temp_audio.name):
                os.unlink(self.temp_audio.name)
            self.temp_audio = None
    
    def type_text(self, text: str):
        """Type the transcribed text using ydotool or xdotool"""
        # Try ydotool first (Wayland compatible)
        if self.try_ydotool(text):
            return
        
        # Fall back to xdotool (X11)
        if self.try_xdotool(text):
            return
        
        # Last resort: copy to clipboard
        self.copy_to_clipboard(text)
    
    def try_ydotool(self, text: str) -> bool:
        """Try to type with ydotool (Wayland)"""
        try:
            # Check if ydotool is available
            subprocess.run(['which', 'ydotool'], check=True, capture_output=True)
            
            # Type the text
            subprocess.run(['ydotool', 'type', text], check=True)
            print("📝 Text typed (ydotool)")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def try_xdotool(self, text: str) -> bool:
        """Try to type with xdotool (X11)"""
        try:
            # Check if xdotool is available
            subprocess.run(['which', 'xdotool'], check=True, capture_output=True)
            
            # Type the text
            time.sleep(0.5)  # Give time to focus
            subprocess.run(['xdotool', 'type', text], check=True)
            print("📝 Text typed (xdotool)")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def copy_to_clipboard(self, text: str):
        """Copy text to clipboard as fallback"""
        try:
            # Try wl-copy for Wayland
            subprocess.run(
                ['wl-copy'],
                input=text,
                text=True,
                check=True,
                capture_output=True
            )
            print("📋 Text copied to clipboard (wl-copy)")
        except (subprocess.CalledProcessError, FileNotFoundError):
            try:
                # Try xclip for X11
                subprocess.run(
                    ['xclip', '-selection', 'clipboard'],
                    input=text,
                    text=True,
                    check=True
                )
                print("📋 Text copied to clipboard (xclip)")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"⚠️  Could not type or copy. Text: {text}")
    
    def run(self):
        """Main event loop"""
        try:
            for event in self.keyboard.read_loop():
                if event.type == ecodes.EV_KEY:
                    key_event = categorize(event)
                    
                    # Track Alt key state
                    if key_event.keycode == MODIFIER_KEY:
                        if key_event.keystate == 1:  # Key down
                            self.alt_pressed = True
                        elif key_event.keystate == 0:  # Key up
                            self.alt_pressed = False
                            # If slash was pressed with alt, stop recording
                            if self.slash_pressed:
                                self.slash_pressed = False
                                self.stop_recording_and_transcribe()
                    
                    # Track Slash key state
                    elif key_event.keycode == TRIGGER_KEY:
                        if key_event.keystate == 1:  # Key down
                            self.slash_pressed = True
                            # Start recording if Alt is held
                            if self.alt_pressed:
                                self.start_recording()
                        elif key_event.keystate == 0:  # Key up
                            if self.slash_pressed and self.alt_pressed:
                                self.stop_recording_and_transcribe()
                            self.slash_pressed = False
                    
        except KeyboardInterrupt:
            print("\n👋 Exiting push-to-talk daemon")
            if self.recording_process:
                self.recording_process.terminate()
            sys.exit(0)

def check_requirements():
    """Check if all requirements are met"""
    if os.geteuid() != 0:
        print("Error: This script needs root access to monitor keyboard events.")
        print("Run with: sudo python3 push-to-talk.py")
        sys.exit(1)
    
    if not WHISPER_BIN.exists():
        print(f"Error: Whisper not found at {WHISPER_BIN}")
        sys.exit(1)
    
    if not MODEL_PATH.exists():
        print(f"Error: Model not found at {MODEL_PATH}")
        sys.exit(1)
    
    # Check for parecord
    try:
        subprocess.run(['which', 'parecord'], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        print("Error: parecord not found. Install with: sudo dnf install pulseaudio-utils")
        sys.exit(1)

def main():
    """Main entry point"""
    check_requirements()
    
    daemon = PushToTalkDaemon()
    daemon.run()

if __name__ == "__main__":
    main()