#!/bin/bash
# ============================================================================
# Office & Multimedia Suite Installer
# ============================================================================
# Installs: LibreOffice, GIMP, Inkscape, Kdenlive, OBS, Audacity, etc.
# Target: Complete productivity and creative suite
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           Office & Multimedia Suite Installer                ║"
    echo "║   Office + Graphics + Video + Audio + Image Tools            ║"
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
# Office Suite
# ============================================================================

install_office() {
    log_step "Installing Office Suite..."

    # LibreOffice Fresh (latest features)
    sudo pacman -S --needed --noconfirm \
        libreoffice-fresh \
        libreoffice-fresh-en-us

    # PDF tools
    sudo pacman -S --needed --noconfirm \
        okular \
        pdfarranger \
        poppler

    # Note taking
    sudo pacman -S --needed --noconfirm \
        xournalpp

    # Markdown
    sudo pacman -S --needed --noconfirm \
        ghostwriter

    log_success "Office suite installed"
}

# ============================================================================
# Graphics & Image Tools
# ============================================================================

install_graphics() {
    log_step "Installing Graphics & Image Tools..."

    # Raster graphics
    sudo pacman -S --needed --noconfirm \
        gimp \
        krita

    # Vector graphics
    sudo pacman -S --needed --noconfirm \
        inkscape

    # Image viewers
    sudo pacman -S --needed --noconfirm \
        loupe \
        feh \
        imv

    # Screenshots
    sudo pacman -S --needed --noconfirm \
        flameshot \
        grim \
        slurp

    # Image optimization & conversion
    sudo pacman -S --needed --noconfirm \
        imagemagick \
        optipng \
        pngquant \
        jpegoptim \
        webp

    # RAW image support
    sudo pacman -S --needed --noconfirm \
        darktable \
        rawtherapee

    log_success "Graphics tools installed"
}

# ============================================================================
# Video Tools
# ============================================================================

install_video() {
    log_step "Installing Video Tools..."

    # Video editors
    sudo pacman -S --needed --noconfirm \
        kdenlive \
        shotcut

    # Screen recording
    sudo pacman -S --needed --noconfirm \
        obs-studio

    # Video players
    sudo pacman -S --needed --noconfirm \
        vlc \
        mpv \
        celluloid

    # Video conversion & processing
    sudo pacman -S --needed --noconfirm \
        ffmpeg \
        handbrake

    # DVD/Blu-ray tools
    sudo pacman -S --needed --noconfirm \
        libdvdcss \
        libbluray

    log_success "Video tools installed"
}

# ============================================================================
# Audio Tools
# ============================================================================

install_audio() {
    log_step "Installing Audio Tools..."

    # Audio editors
    sudo pacman -S --needed --noconfirm \
        audacity \
        ardour

    # Audio players
    sudo pacman -S --needed --noconfirm \
        rhythmbox \
        lollypop

    # Audio tools
    sudo pacman -S --needed --noconfirm \
        sox \
        lame \
        flac \
        opus-tools \
        vorbis-tools

    # PipeWire audio (modern audio stack)
    sudo pacman -S --needed --noconfirm \
        pipewire \
        pipewire-alsa \
        pipewire-pulse \
        pipewire-jack \
        wireplumber \
        pavucontrol

    log_success "Audio tools installed"
}

# ============================================================================
# 3D & Animation (Optional)
# ============================================================================

install_3d() {
    log_step "Installing 3D & Animation Tools..."

    sudo pacman -S --needed --noconfirm \
        blender

    log_success "3D tools installed"
}

# ============================================================================
# Utilities
# ============================================================================

install_utilities() {
    log_step "Installing Utilities..."

    # Archive tools
    sudo pacman -S --needed --noconfirm \
        p7zip \
        unrar \
        unzip \
        zip \
        file-roller

    # Color picker
    sudo pacman -S --needed --noconfirm \
        gpick

    # Font tools
    sudo pacman -S --needed --noconfirm \
        fontforge \
        font-manager

    # Disk tools
    sudo pacman -S --needed --noconfirm \
        gparted \
        baobab

    log_success "Utilities installed"
}

# ============================================================================
# Fonts
# ============================================================================

install_fonts() {
    log_step "Installing Fonts..."

    sudo pacman -S --needed --noconfirm \
        ttf-dejavu \
        ttf-liberation \
        noto-fonts \
        noto-fonts-emoji \
        ttf-fira-code \
        ttf-jetbrains-mono \
        ttf-roboto \
        ttf-opensans \
        adobe-source-code-pro-fonts \
        adobe-source-sans-fonts \
        adobe-source-serif-fonts

    # Refresh font cache
    fc-cache -f

    log_success "Fonts installed"
}

# ============================================================================
# Codecs
# ============================================================================

install_codecs() {
    log_step "Installing Multimedia Codecs..."

    sudo pacman -S --needed --noconfirm \
        gst-plugins-base \
        gst-plugins-good \
        gst-plugins-bad \
        gst-plugins-ugly \
        gst-libav \
        gstreamer-vaapi

    log_success "Codecs installed"
}

verify_installation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Summary${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}Office:${NC}"
    for app in libreoffice okular xournalpp ghostwriter; do
        if pacman -Qi "$app" &> /dev/null 2>&1 || command -v "$app" &> /dev/null; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}Graphics:${NC}"
    for app in gimp inkscape krita darktable flameshot; do
        if pacman -Qi "$app" &> /dev/null 2>&1 || command -v "$app" &> /dev/null; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}Video:${NC}"
    for app in kdenlive obs-studio vlc mpv ffmpeg handbrake; do
        if pacman -Qi "$app" &> /dev/null 2>&1 || command -v "$app" &> /dev/null; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}Audio:${NC}"
    for app in audacity ardour rhythmbox pavucontrol; do
        if pacman -Qi "$app" &> /dev/null 2>&1 || command -v "$app" &> /dev/null; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
    echo -e "${CYAN}3D:${NC}"
    for app in blender; do
        if pacman -Qi "$app" &> /dev/null 2>&1 || command -v "$app" &> /dev/null; then
            printf "  ${GREEN}✓${NC} %s\n" "$app"
        fi
    done

    echo ""
}

# ============================================================================
# Main
# ============================================================================

print_header
check_arch

# Parse arguments
SKIP_3D=false
MINIMAL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-3d)
            SKIP_3D=true
            shift
            ;;
        --minimal)
            MINIMAL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-3d    Skip Blender installation"
            echo "  --minimal    Install minimal set (office + basic graphics)"
            echo "  -h, --help   Show this help"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo ""
log_step "Starting Office & Multimedia suite installation..."
echo ""

if $MINIMAL; then
    log_warning "Installing minimal set..."
    install_office
    install_codecs
    install_fonts
    sudo pacman -S --needed --noconfirm gimp inkscape vlc ffmpeg imagemagick
else
    install_office
    install_graphics
    install_video
    install_audio
    if ! $SKIP_3D; then
        install_3d
    fi
    install_utilities
    install_fonts
    install_codecs
fi

verify_installation

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Office & Multimedia Suite Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Installed Applications:"
echo ""
echo "  Office:      LibreOffice, Okular, Xournal++, Ghostwriter"
echo "  Graphics:    GIMP, Inkscape, Krita, Darktable"
echo "  Video:       Kdenlive, OBS Studio, VLC, HandBrake"
echo "  Audio:       Audacity, Ardour, Rhythmbox"
echo "  3D:          Blender"
echo ""
echo "Image Tools (CLI):"
echo "  magick convert input.png -resize 50% output.png"
echo "  optipng -o7 image.png"
echo "  pngquant --quality=65-80 image.png"
echo "  ffmpeg -i video.mp4 -vf scale=1280:720 output.mp4"
echo ""
