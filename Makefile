# Voice Dictation Makefile
# Professional build and installation system

.PHONY: all install uninstall test clean help check-deps setup-gnome

# Installation directories
PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib/voice-dictation
DATADIR = $(PREFIX)/share/voice-dictation

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# Default target
all: help

# Download Whisper model
download-model:
	@echo "Downloading Whisper model..."
	@bash setup/download-model.sh

# Help message
help:
	@echo "Voice Dictation - Make Targets"
	@echo "=============================="
	@echo ""
	@echo "  make install      - Install to ~/.local (user installation)"
	@echo "  make install-system - Install to /usr/local (system-wide, needs sudo)"
	@echo "  make uninstall    - Remove installation"
	@echo "  make test         - Run tests"
	@echo "  make check-deps   - Check dependencies"
	@echo "  make setup-gnome  - Set up GNOME keyboard shortcut"
	@echo "  make clean        - Clean temporary files"
	@echo ""
	@echo "Quick start:"
	@echo "  make check-deps && make install"

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@which parecord >/dev/null 2>&1 || (echo "$(RED)✗ parecord not found$(NC) - Install: sudo dnf install pulseaudio-utils" && false)
	@which python3 >/dev/null 2>&1 || (echo "$(RED)✗ python3 not found$(NC)" && false)
	@test -f data/models/ggml-base.en.bin || (echo "$(YELLOW)⚠ Whisper model not found$(NC) - Download required" && false)
	@test -f $(HOME)/workspace/whisper.cpp/build/bin/whisper-cli || (echo "$(RED)✗ whisper-cli not found$(NC) - Build whisper.cpp first" && false)
	@echo "$(GREEN)✓ All required dependencies found$(NC)"
	@echo ""
	@echo "Optional tools:"
	@which ydotool >/dev/null 2>&1 && echo "$(GREEN)✓ ydotool (Wayland typing)$(NC)" || echo "$(YELLOW)○ ydotool not installed$(NC)"
	@which wl-copy >/dev/null 2>&1 && echo "$(GREEN)✓ wl-clipboard (Wayland clipboard)$(NC)" || echo "$(YELLOW)○ wl-clipboard not installed$(NC)"
	@python3 -c "import evdev" 2>/dev/null && echo "$(GREEN)✓ python3-evdev (push-to-talk)$(NC)" || echo "$(YELLOW)○ python3-evdev not installed$(NC)"

# Install to user directory
install: check-deps
	@echo "Installing to $(PREFIX)..."
	@mkdir -p $(BINDIR)
	@mkdir -p $(LIBDIR)/core
	@mkdir -p $(DATADIR)/models
	@mkdir -p $(DATADIR)/recordings
	
	# Install binaries
	@cp -v bin/* $(BINDIR)/
	@chmod +x $(BINDIR)/dictate $(BINDIR)/voice-toggle $(BINDIR)/voice-ptt $(BINDIR)/ptt
	
	# Install libraries
	@cp -rv lib/* $(LIBDIR)/
	
	# Copy data (models)
	@if [ -f data/models/ggml-base.en.bin ]; then \
		cp -v data/models/ggml-base.en.bin $(DATADIR)/models/; \
	fi
	
	# Update paths in installed scripts
	@sed -i "s|PROJECT_ROOT=\".*\"|PROJECT_ROOT=\"$(PREFIX)\"|g" $(BINDIR)/dictate
	@sed -i "s|PROJECT_ROOT=\".*\"|PROJECT_ROOT=\"$(PREFIX)\"|g" $(BINDIR)/voice-toggle
	@sed -i "s|PROJECT_ROOT=\".*\"|PROJECT_ROOT=\"$(PREFIX)\"|g" $(BINDIR)/voice-ptt
	
	@echo ""
	@echo "$(GREEN)✓ Installation complete!$(NC)"
	@echo ""
	@echo "Add $(BINDIR) to your PATH if not already:"
	@echo "  echo 'export PATH=\"$(BINDIR):\$$PATH\"' >> ~/.bashrc"
	@echo ""
	@echo "Commands available:"
	@echo "  dictate        - Manual voice dictation"
	@echo "  voice-toggle   - Toggle recording mode"
	@echo "  ptt            - Push-to-talk (secure wrapper)"
	@echo "  voice-ptt      - Push-to-talk daemon (direct)"

# System-wide installation
install-system:
	@$(MAKE) install PREFIX=/usr/local

# Uninstall
uninstall:
	@echo "Removing installation from $(PREFIX)..."
	@rm -f $(BINDIR)/dictate
	@rm -f $(BINDIR)/voice-toggle
	@rm -f $(BINDIR)/voice-ptt
	@rm -f $(BINDIR)/ptt
	@rm -rf $(LIBDIR)
	@rm -rf $(DATADIR)
	@echo "$(GREEN)✓ Uninstalled$(NC)"

# Run tests
test:
	@echo "Running tests..."
	@echo ""
	@echo "1. Testing microphone..."
	@bash test/test-pulse.sh || true
	@echo ""
	@echo "2. Testing Whisper model..."
	@test -f data/recordings/debug_audio.wav && \
		$(HOME)/workspace/whisper.cpp/build/bin/whisper-cli \
		-m data/models/ggml-base.en.bin \
		-f data/recordings/debug_audio.wav \
		--no-timestamps 2>/dev/null | tail -5 || \
		echo "No test audio found. Record something first with: bin/voice-toggle"

# Set up GNOME shortcut
setup-gnome:
	@echo "Opening GNOME Settings to add keyboard shortcut..."
	@echo ""
	@echo "Add custom shortcut with:"
	@echo "  Name: Voice Dictation"
	@echo "  Command: $(BINDIR)/voice-toggle"
	@echo "  Shortcut: Super+V (or your preference)"
	@echo ""
	@read -p "Press Enter to open Settings..." dummy
	@gnome-control-center keyboard &

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@rm -f data/recordings/*.wav
	@rm -f /tmp/voice_dictation.*
	@rm -rf scripts/  # Remove old scripts directory if empty
	@echo "$(GREEN)✓ Cleaned$(NC)"

# Development targets
.PHONY: dev-test dev-install

# Quick test without installation
dev-test:
	@./bin/voice-toggle

# Install for development (symlinks instead of copies)
dev-install:
	@echo "Creating development symlinks..."
	@mkdir -p $(BINDIR)
	@ln -sf $(PWD)/bin/dictate $(BINDIR)/dictate
	@ln -sf $(PWD)/bin/voice-toggle $(BINDIR)/voice-toggle
	@ln -sf $(PWD)/bin/voice-ptt $(BINDIR)/voice-ptt
	@ln -sf $(PWD)/bin/ptt $(BINDIR)/ptt
	@echo "$(GREEN)✓ Development links created$(NC)"