#!/usr/bin/env python3
"""
Push-to-Talk Voice Dictation Daemon
Hold Right Alt (AltGr) to record, release to transcribe
Works on Wayland/GNOME using evdev

Preferred: Add user to input group to run without sudo
Alternative: Run with sudo (may have audio issues)
"""

import os
import sys
import time
import signal
import subprocess
import threading
import tempfile
import grp
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
# Get user home directory (works for both sudo and regular user)
import pwd

if os.geteuid() == 0:
    # Running as root, get original user
    ACTUAL_USER = os.environ.get('SUDO_USER', os.environ.get('USER'))
    USER_HOME = pwd.getpwnam(ACTUAL_USER).pw_dir if ACTUAL_USER else str(Path.home())
else:
    # Running as regular user
    ACTUAL_USER = os.environ.get('USER')
    USER_HOME = str(Path.home())

WHISPER_BIN = Path(USER_HOME) / "workspace/whisper.cpp/build/bin/whisper-cli"
MODEL_PATH = Path(USER_HOME) / "workspace/voice-dictation/data/models/ggml-base.en.bin"
RECORDINGS_DIR = Path(USER_HOME) / "workspace/voice-dictation/data/recordings"

# Key configuration - Just Right Alt (AltGr)
RECORD_KEY = ecodes.KEY_RIGHTALT  # Hold to record, release to transcribe

class PushToTalkDaemon:
    def __init__(self):
        self.recording = False
        self.recording_process = None
        self.temp_audio = None
        self.recording_key_pressed = False
        
        # Ensure recordings directory exists
        RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)
        
        # Find keyboard device
        self.keyboard = self.find_keyboard()
        if not self.keyboard:
            print("Error: No keyboard found. Make sure you're running with sudo.")
            sys.exit(1)
        
        print(f"Using keyboard: {self.keyboard.name}")
        print("")
        print("🎤 Push-to-Talk ready!")
        print("📌 Hold Right Alt (AltGr) to record")
        print("📝 Release to transcribe and type")
        print("❌ Press Ctrl+C to exit")
    
    def find_keyboard(self) -> Optional[InputDevice]:
        """Find the first physical keyboard device (skip virtual devices)"""
        devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
        keyboards = []
        
        for i, device in enumerate(devices):
            capabilities = device.capabilities(verbose=True)
            # Check if device has KEY events and common keyboard keys
            if ('EV_KEY', 1) in capabilities:
                keys = capabilities[('EV_KEY', 1)]
                # Check for alphabetic keys to identify keyboard
                if any('KEY_A' in str(key) for key in keys):
                    # Skip virtual devices like ydotoold
                    if 'virtual' not in device.name.lower():
                        keyboards.append(device)
                        print(f"  [{len(keyboards)}] {device.name}")
        
        # If we found keyboards, ask which one to use
        if keyboards:
            if len(keyboards) == 1:
                return keyboards[0]
            else:
                print(f"\nMultiple keyboards found. Which one are you using?")
                try:
                    choice = input(f"Enter number [1-{len(keyboards)}] (default: 1): ").strip()
                    if not choice:
                        return keyboards[0]
                    idx = int(choice) - 1
                    if 0 <= idx < len(keyboards):
                        return keyboards[idx]
                except (ValueError, IndexError):
                    pass
                return keyboards[0]
        
        # If no physical keyboards found, try any keyboard (but warn)
        print("Warning: No physical keyboard found, trying virtual devices...")
        for device in devices:
            capabilities = device.capabilities(verbose=True)
            if ('EV_KEY', 1) in capabilities:
                keys = capabilities[('EV_KEY', 1)]
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
        
        print("\n🎤 Recording... (release Right Alt to stop)")
        
        # Try multiple recording methods in order of preference
        if os.geteuid() == 0:
            # Running as root - prefer FFmpeg (with corrected syntax)
            recording_methods = [
                {
                    'name': 'FFmpeg (PulseAudio)',
                    'cmd': ['ffmpeg', '-f', 'pulse', '-ac', '1', '-ar', '16000', '-i', 'default', '-y', self.temp_audio.name],
                    'quiet': True
                },
                {
                    'name': 'FFmpeg (ALSA hw:1,0)',
                    'cmd': ['ffmpeg', '-f', 'alsa', '-ac', '1', '-ar', '16000', '-i', 'hw:1,0', '-y', self.temp_audio.name],
                    'quiet': True
                },
                {
                    'name': 'FFmpeg (ALSA default)',
                    'cmd': ['ffmpeg', '-f', 'alsa', '-ac', '1', '-ar', '16000', '-i', 'default', '-y', self.temp_audio.name],
                    'quiet': True
                }
            ]
        else:
            # Running as regular user - prefer native tools
            recording_methods = [
                {
                    'name': 'pw-record (PipeWire)',
                    'cmd': ['pw-record', '--channels=1', '--rate=48000', '--format=s16le', self.temp_audio.name],
                    'quiet': False
                },
                {
                    'name': 'parecord (PulseAudio/PipeWire)',
                    'cmd': ['parecord', '--channels=1', '--rate=48000', '--format=s16le', self.temp_audio.name],
                    'quiet': False
                },
                {
                    'name': 'FFmpeg (PulseAudio/PipeWire)',
                    'cmd': ['ffmpeg', '-f', 'pulse', '-ac', '1', '-ar', '48000', '-i', 'default', '-y', self.temp_audio.name],
                    'quiet': True
                },
                {
                    'name': 'FFmpeg (ALSA hw:1,0)', 
                    'cmd': ['ffmpeg', '-f', 'alsa', '-ac', '1', '-ar', '16000', '-i', 'hw:1,0', '-y', self.temp_audio.name],
                    'quiet': True
                },
                {
                    'name': 'FFmpeg (ALSA default)', 
                    'cmd': ['ffmpeg', '-f', 'alsa', '-ac', '1', '-ar', '16000', '-i', 'default', '-y', self.temp_audio.name],
                    'quiet': True
                },
                {
                    'name': 'arecord (ALSA hw:1,0)',
                    'cmd': ['arecord', '-D', 'hw:1,0', '-f', 'S16_LE', '-r', '48000', '-c', '1', '-q', self.temp_audio.name],
                    'quiet': True
                },
                {
                    'name': 'arecord (ALSA default)',
                    'cmd': ['arecord', '-D', 'default', '-f', 'S16_LE', '-r', '48000', '-c', '1', '-q', self.temp_audio.name],
                    'quiet': True
                }
            ]
        
        self.recording_process = None
        
        for method in recording_methods:
            try:
                # For FFmpeg, add quiet flags
                cmd = method['cmd'].copy()
                if method['quiet'] and 'ffmpeg' in cmd[0]:
                    cmd.extend(['-loglevel', 'quiet'])
                
                self.recording_process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.DEVNULL if method['quiet'] else subprocess.PIPE,
                    stderr=subprocess.DEVNULL if method['quiet'] else subprocess.PIPE
                )
                
                # Give it a moment to start
                time.sleep(0.2)
                
                # Check if it started successfully
                if self.recording_process.poll() is None:
                    print(f"✓ Recording with {method['name']}")
                    break
                else:
                    # Process failed, try next method
                    continue
                    
            except FileNotFoundError:
                # Command not found, try next method
                continue
        
        # If no method worked
        if not self.recording_process or self.recording_process.poll() is not None:
            print("❌ All recording methods failed")
            print("Try: sudo dnf install sox pulseaudio-utils")
            self.recording = False
            self.recording_process = None
    
    def stop_recording_and_transcribe(self):
        """Stop recording and transcribe the audio"""
        if not self.recording or not self.recording_process:
            return
        
        self.recording = False
        
        # Stop recording
        self.recording_process.terminate()
        self.recording_process.communicate(timeout=1)
        
        print("⏹️  Stopped recording")
        
        # Check file size to ensure we have audio
        if self.temp_audio:
            file_size = os.path.getsize(self.temp_audio.name)
            if file_size < 1000:
                print("❌ No audio recorded - speak louder or check microphone")
                return
        
        print("🔄 Transcribing...")
        
        # Check if we need to resample (Whisper expects 16kHz)
        # If we recorded at 48kHz, resample first
        whisper_audio_file = self.temp_audio.name
        if os.path.getsize(self.temp_audio.name) > 1000:
            # Try to resample with ffmpeg if needed
            try:
                import subprocess
                import tempfile
                
                # Create temp file for resampled audio
                resampled_audio = tempfile.NamedTemporaryFile(suffix='.wav', dir=RECORDINGS_DIR, delete=False)
                
                # Resample to 16kHz for Whisper
                resample_cmd = [
                    'ffmpeg', '-i', self.temp_audio.name, 
                    '-ar', '16000', '-ac', '1', '-y', 
                    resampled_audio.name
                ]
                
                result = subprocess.run(resample_cmd, capture_output=True, timeout=5)
                if result.returncode == 0 and os.path.getsize(resampled_audio.name) > 100:
                    whisper_audio_file = resampled_audio.name
                    print("✓ Resampled audio for Whisper")
                else:
                    # Use original file if resampling failed
                    os.unlink(resampled_audio.name)
                    
            except Exception:
                # If resampling fails, use original file
                pass
        
        # Transcribe with whisper
        cmd = [
            str(WHISPER_BIN),
            '-m', str(MODEL_PATH),
            '-f', whisper_audio_file,
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
                
                # Remove all ANSI escape sequences (color codes, etc.)
                import re
                transcription = re.sub(r'\x1b\[[0-9;]*m', '', transcription)
                transcription = re.sub(r'\x1b\[[0-9]*[A-Za-z]', '', transcription)
                transcription = transcription.strip()
                
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
        # Try ydotool first (works on Wayland with daemon)
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
                    
                    # Track Right Alt key state
                    # keycode from categorize is a string like 'KEY_RIGHTALT'
                    if 'KEY_RIGHTALT' in str(key_event.keycode):
                        if key_event.keystate == 1:  # Key down
                            if not self.recording_key_pressed:
                                self.recording_key_pressed = True
                                self.start_recording()
                        elif key_event.keystate == 0:  # Key up
                            if self.recording_key_pressed:
                                self.recording_key_pressed = False
                                self.stop_recording_and_transcribe()
                    
        except KeyboardInterrupt:
            print("\n👋 Exiting push-to-talk daemon")
            if self.recording_process:
                self.recording_process.terminate()
            sys.exit(0)

def check_requirements():
    """Check if all requirements are met"""
    
    # Check if user is in input group (preferred method)
    user_groups = [grp.getgrgid(g).gr_name for g in os.getgroups()]
    if 'input' not in user_groups and os.geteuid() != 0:
        print("Error: This script needs keyboard access.")
        print("")
        print("RECOMMENDED: Add your user to the input group:")
        print("  sudo usermod -a -G input $USER")
        print("  newgrp input  # or log out/in")
        print("  ./bin/voice-ptt  # run WITHOUT sudo")
        print("")
        print("ALTERNATIVE: Run with sudo:")
        print("  sudo ./bin/voice-ptt")
        sys.exit(1)
    
    if os.geteuid() == 0:
        print(f"⚠️  Running as root - audio may not work")
        print(f"✓ User: {ACTUAL_USER} (home: {USER_HOME})")
    else:
        print(f"✓ Running as: {os.environ.get('USER')} (recommended)")
        print(f"✓ Has keyboard access via input group")
    
    if not WHISPER_BIN.exists():
        print(f"Error: Whisper not found at {WHISPER_BIN}")
        print(f"Current user: {ACTUAL_USER}")
        print(f"Looking in: {USER_HOME}/workspace/whisper.cpp/build/bin/")
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