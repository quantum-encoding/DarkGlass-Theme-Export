#!/bin/bash
# ============================================================================
# Content Creator Suite Installer
# ============================================================================
# Installs: OBS Studio, DaVinci Resolve, Kdenlive, streaming tools, etc.
# Target: Complete YouTube/Twitch/content creation environment
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            Content Creator Suite Installer                   ║"
    echo "║    OBS + Video Editing + Streaming + Audio Production        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() {
    echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        echo -e "${RED}This script requires Arch Linux${NC}"
        exit 1
    fi
}

# ============================================================================
# Screen Recording & Streaming
# ============================================================================

install_obs() {
    log_step "Installing OBS Studio..."

    sudo pacman -S --needed --noconfirm \
        obs-studio \
        v4l2loopback-dkms \
        linux-headers

    # OBS plugins
    log_step "Installing OBS plugins..."

    # Check for AUR helper
    if command -v yay &> /dev/null; then
        yay -S --needed --noconfirm \
            obs-streamfx \
            obs-pipewire-audio-capture \
            obs-vkcapture \
            2>/dev/null || log_warning "Some OBS plugins may need manual installation"
    elif command -v paru &> /dev/null; then
        paru -S --needed --noconfirm \
            obs-streamfx \
            obs-pipewire-audio-capture \
            obs-vkcapture \
            2>/dev/null || log_warning "Some OBS plugins may need manual installation"
    else
        log_warning "Install yay or paru to get additional OBS plugins from AUR"
    fi

    # Virtual camera setup
    log_step "Configuring virtual camera..."
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf > /dev/null
    echo 'options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1' | \
        sudo tee /etc/modprobe.d/v4l2loopback.conf > /dev/null

    log_success "OBS Studio installed"
}

install_screen_capture() {
    log_step "Installing Screen Capture Tools..."

    sudo pacman -S --needed --noconfirm \
        flameshot \
        grim \
        slurp \
        wf-recorder \
        peek

    log_success "Screen capture tools installed"
}

# ============================================================================
# Video Editing
# ============================================================================

install_video_editors() {
    log_step "Installing Video Editors..."

    # Kdenlive - Professional open source video editor
    sudo pacman -S --needed --noconfirm kdenlive

    # Shotcut - Easy to use video editor
    sudo pacman -S --needed --noconfirm shotcut

    # OpenShot (from AUR if available)
    if command -v yay &> /dev/null; then
        yay -S --needed --noconfirm openshot 2>/dev/null || true
    fi

    log_success "Video editors installed"

    echo ""
    echo -e "${YELLOW}Note: DaVinci Resolve (free pro editor) requires manual installation:${NC}"
    echo "  1. Download from: https://www.blackmagicdesign.com/products/davinciresolve"
    echo "  2. Or from AUR: yay -S davinci-resolve"
    echo ""
}

install_video_tools() {
    log_step "Installing Video Processing Tools..."

    sudo pacman -S --needed --noconfirm \
        ffmpeg \
        handbrake \
        mediainfo \
        mkvtoolnix-cli \
        mkvtoolnix-gui

    log_success "Video tools installed"
}

# ============================================================================
# Audio Production
# ============================================================================

install_audio_production() {
    log_step "Installing Audio Production Tools..."

    # PipeWire (modern audio system)
    sudo pacman -S --needed --noconfirm \
        pipewire \
        pipewire-alsa \
        pipewire-pulse \
        pipewire-jack \
        wireplumber \
        helvum \
        qpwgraph \
        pavucontrol \
        easyeffects

    # Audio editors
    sudo pacman -S --needed --noconfirm \
        audacity \
        ardour

    # Audio tools
    sudo pacman -S --needed --noconfirm \
        sox \
        lame \
        flac \
        opus-tools

    log_success "Audio production tools installed"
}

install_voice_tools() {
    log_step "Installing Voice/Microphone Tools..."

    # Noise suppression
    sudo pacman -S --needed --noconfirm \
        noise-suppression-for-voice

    # Carla (audio plugin host)
    sudo pacman -S --needed --noconfirm carla

    log_success "Voice tools installed"
}

# ============================================================================
# Thumbnails & Graphics
# ============================================================================

install_graphics_tools() {
    log_step "Installing Graphics Tools for Thumbnails..."

    sudo pacman -S --needed --noconfirm \
        gimp \
        inkscape \
        krita

    # For quick edits
    sudo pacman -S --needed --noconfirm \
        imagemagick \
        optipng \
        pngquant

    log_success "Graphics tools installed"
}

# ============================================================================
# Streaming Utilities
# ============================================================================

install_streaming_utils() {
    log_step "Installing Streaming Utilities..."

    # Chat/Communication
    sudo pacman -S --needed --noconfirm \
        discord

    # Streamlink for watching streams
    sudo pacman -S --needed --noconfirm streamlink

    # yt-dlp for downloading videos
    sudo pacman -S --needed --noconfirm yt-dlp

    log_success "Streaming utilities installed"
}

# ============================================================================
# Webcam Tools
# ============================================================================

install_webcam_tools() {
    log_step "Installing Webcam Tools..."

    sudo pacman -S --needed --noconfirm \
        v4l-utils \
        guvcview \
        cheese

    log_success "Webcam tools installed"
}

# ============================================================================
# Performance Optimizations
# ============================================================================

optimize_system() {
    log_step "Applying Performance Optimizations..."

    # Increase file watcher limit (for OBS)
    if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.d/99-sysctl.conf 2>/dev/null; then
        echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.d/99-sysctl.conf > /dev/null
        sudo sysctl -p /etc/sysctl.d/99-sysctl.conf 2>/dev/null || true
    fi

    # Add user to video group for hardware acceleration
    sudo usermod -aG video "$USER"

    log_success "System optimizations applied"
}

# ============================================================================
# Create Helper Scripts
# ============================================================================

create_helpers() {
    mkdir -p "$HOME/.local/bin"

    # Quick video convert script
    cat > "$HOME/.local/bin/vid-convert" << 'SCRIPT'
#!/bin/bash
# Quick video conversion helper

if [ -z "$1" ]; then
    echo "Usage: vid-convert <input> [output] [preset]"
    echo ""
    echo "Presets:"
    echo "  youtube    - YouTube upload ready (1080p, h264)"
    echo "  twitter    - Twitter optimized (720p, smaller)"
    echo "  discord    - Discord (8MB limit, 720p)"
    echo "  gif        - Convert to GIF"
    echo "  audio      - Extract audio only"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-output.mp4}"
PRESET="${3:-youtube}"

case "$PRESET" in
    youtube)
        ffmpeg -i "$INPUT" -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k \
            -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
            -movflags +faststart "$OUTPUT"
        ;;
    twitter)
        ffmpeg -i "$INPUT" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k \
            -vf "scale=1280:720:force_original_aspect_ratio=decrease" \
            -movflags +faststart "$OUTPUT"
        ;;
    discord)
        ffmpeg -i "$INPUT" -c:v libx264 -preset medium -crf 28 -c:a aac -b:a 96k \
            -vf "scale=1280:720:force_original_aspect_ratio=decrease" \
            -fs 8M -movflags +faststart "$OUTPUT"
        ;;
    gif)
        OUTPUT="${OUTPUT%.mp4}.gif"
        ffmpeg -i "$INPUT" -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
            -loop 0 "$OUTPUT"
        ;;
    audio)
        OUTPUT="${OUTPUT%.mp4}.mp3"
        ffmpeg -i "$INPUT" -vn -acodec libmp3lame -b:a 320k "$OUTPUT"
        ;;
    *)
        echo "Unknown preset: $PRESET"
        exit 1
        ;;
esac

echo "Done: $OUTPUT"
SCRIPT

    # Quick thumbnail creator
    cat > "$HOME/.local/bin/make-thumbnail" << 'SCRIPT'
#!/bin/bash
# Quick thumbnail generator from video

if [ -z "$1" ]; then
    echo "Usage: make-thumbnail <video> [timestamp] [output]"
    echo "  timestamp format: HH:MM:SS or SS (default: 00:00:05)"
    exit 1
fi

VIDEO="$1"
TIMESTAMP="${2:-00:00:05}"
OUTPUT="${3:-thumbnail.png}"

ffmpeg -i "$VIDEO" -ss "$TIMESTAMP" -vframes 1 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" "$OUTPUT"

echo "Thumbnail created: $OUTPUT"
SCRIPT

    # OBS virtual camera loader
    cat > "$HOME/.local/bin/obs-virt-cam" << 'SCRIPT'
#!/bin/bash
# Load OBS virtual camera kernel module

if lsmod | grep -q v4l2loopback; then
    echo "Virtual camera already loaded"
else
    sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    echo "Virtual camera loaded on /dev/video10"
fi
SCRIPT

    chmod +x "$HOME/.local/bin/vid-convert"
    chmod +x "$HOME/.local/bin/make-thumbnail"
    chmod +x "$HOME/.local/bin/obs-virt-cam"

    log_success "Helper scripts created"
}

verify_installation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Summary${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}Streaming & Recording:${NC}"
    for app in obs-studio flameshot peek; do
        if pacman -Qi "$app" &> /dev/null 2>&1; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}Video Editing:${NC}"
    for app in kdenlive shotcut handbrake; do
        if pacman -Qi "$app" &> /dev/null 2>&1; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}Audio Production:${NC}"
    for app in audacity ardour easyeffects carla; do
        if pacman -Qi "$app" &> /dev/null 2>&1; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}Graphics:${NC}"
    for app in gimp inkscape krita; do
        if pacman -Qi "$app" &> /dev/null 2>&1; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}Utilities:${NC}"
    for cmd in ffmpeg yt-dlp streamlink; do
        if command -v "$cmd" &> /dev/null; then
            printf "  ${GREEN}✓${NC} %s\n" "$cmd"
        fi
    done

    echo ""
}

# ============================================================================
# Main
# ============================================================================

print_header
check_arch

echo ""
log_step "Starting Content Creator suite installation..."
echo ""

install_obs
install_screen_capture
install_video_editors
install_video_tools
install_audio_production
install_voice_tools
install_graphics_tools
install_streaming_utils
install_webcam_tools
optimize_system
create_helpers
verify_installation

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Content Creator Suite Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo ""
echo "  OBS Studio:        obs"
echo "  Virtual Camera:    obs-virt-cam  (loads kernel module)"
echo ""
echo "  Video Editing:     kdenlive / shotcut"
echo "  Audio Editing:     audacity / ardour"
echo "  Audio Routing:     helvum / qpwgraph"
echo "  Audio Effects:     easyeffects"
echo ""
echo "Helper Scripts:"
echo "  vid-convert video.mp4 output.mp4 youtube   # Convert for YouTube"
echo "  vid-convert video.mp4 output.mp4 discord   # Compress for Discord"
echo "  vid-convert video.mp4 output.gif gif       # Make GIF"
echo "  make-thumbnail video.mp4 00:01:30          # Extract frame"
echo ""
echo "Download Videos:"
echo "  yt-dlp 'https://youtube.com/watch?v=...'   # Download video"
echo "  yt-dlp -f 'bestaudio' --extract-audio ...  # Audio only"
echo ""
echo -e "${YELLOW}Note: Log out and back in for group changes to take effect${NC}"
echo ""
