#!/bin/bash
# ============================================================================
# Common Functions for JesterNet Dev Stack Installers
# ============================================================================
# Source this file at the top of each installer script:
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# ============================================================================

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export YELLOW='\033[1;33m'
export MAGENTA='\033[0;35m'
export NC='\033[0m'

# Aria2 configuration
ARIA2_CONNECTIONS=16
ARIA2_RETRIES=5
ARIA2_RETRY_WAIT=3
ARIA2_TIMEOUT=60

# ============================================================================
# Logging Functions
# ============================================================================

log_step() {
    echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# ============================================================================
# System Checks
# ============================================================================

check_arch() {
    if ! command -v pacman &> /dev/null; then
        log_error "This script requires Arch Linux (pacman not found)"
        exit 1
    fi
}

# ============================================================================
# Aria2 Setup - MUST BE CALLED FIRST IN EVERY SCRIPT
# ============================================================================

setup_aria2() {
    if command -v aria2c &> /dev/null; then
        log_success "aria2 already installed: $(aria2c --version | head -1)"
        return 0
    fi

    log_step "Installing aria2 (fast parallel downloader)..."
    sudo pacman -S --needed --noconfirm aria2

    if command -v aria2c &> /dev/null; then
        log_success "aria2 installed: $(aria2c --version | head -1)"
    else
        log_error "Failed to install aria2, falling back to curl"
        return 1
    fi
}

# ============================================================================
# Download Function - Uses aria2 with x16 connections and auto-retry
# ============================================================================

# Download a file with aria2 (falls back to curl if aria2 unavailable)
# Usage: download_file <url> <output_path>
download_file() {
    local url="$1"
    local output="$2"
    local output_dir=$(dirname "$output")
    local output_file=$(basename "$output")

    # Create output directory if needed
    mkdir -p "$output_dir"

    if command -v aria2c &> /dev/null; then
        log_step "Downloading with aria2 (x${ARIA2_CONNECTIONS} connections)..."
        aria2c \
            --max-connection-per-server=${ARIA2_CONNECTIONS} \
            --min-split-size=1M \
            --split=${ARIA2_CONNECTIONS} \
            --max-tries=${ARIA2_RETRIES} \
            --retry-wait=${ARIA2_RETRY_WAIT} \
            --timeout=${ARIA2_TIMEOUT} \
            --connect-timeout=10 \
            --continue=true \
            --auto-file-renaming=false \
            --allow-overwrite=true \
            --console-log-level=warn \
            --summary-interval=0 \
            --dir="$output_dir" \
            --out="$output_file" \
            "$url"
    else
        log_warning "aria2 not available, using curl..."
        curl -L --retry ${ARIA2_RETRIES} --retry-delay ${ARIA2_RETRY_WAIT} \
            -o "$output" "$url"
    fi
}

# Download and extract an archive
# Usage: download_and_extract <url> <output_dir> [strip_components]
download_and_extract() {
    local url="$1"
    local output_dir="$2"
    local strip="${3:-0}"
    local temp_file="/tmp/download_$(date +%s).tmp"

    # Determine file type from URL
    local ext="${url##*.}"

    download_file "$url" "$temp_file"

    mkdir -p "$output_dir"

    case "$ext" in
        zip)
            unzip -q "$temp_file" -d "$output_dir"
            ;;
        gz|tgz)
            tar -xzf "$temp_file" -C "$output_dir" --strip-components="$strip"
            ;;
        xz)
            tar -xJf "$temp_file" -C "$output_dir" --strip-components="$strip"
            ;;
        bz2)
            tar -xjf "$temp_file" -C "$output_dir" --strip-components="$strip"
            ;;
        *)
            log_warning "Unknown archive type: $ext"
            mv "$temp_file" "$output_dir/"
            return 1
            ;;
    esac

    rm -f "$temp_file"
    log_success "Extracted to $output_dir"
}

# Download with aria2 using a specific number of connections
# Usage: download_fast <url> <output_path> [connections]
download_fast() {
    local url="$1"
    local output="$2"
    local connections="${3:-$ARIA2_CONNECTIONS}"
    local output_dir=$(dirname "$output")
    local output_file=$(basename "$output")

    mkdir -p "$output_dir"

    if command -v aria2c &> /dev/null; then
        aria2c \
            --max-connection-per-server=${connections} \
            --min-split-size=1M \
            --split=${connections} \
            --max-tries=${ARIA2_RETRIES} \
            --retry-wait=${ARIA2_RETRY_WAIT} \
            --timeout=${ARIA2_TIMEOUT} \
            --connect-timeout=10 \
            --continue=true \
            --auto-file-renaming=false \
            --allow-overwrite=true \
            --console-log-level=warn \
            --dir="$output_dir" \
            --out="$output_file" \
            "$url"
    else
        curl -L --retry ${ARIA2_RETRIES} -o "$output" "$url"
    fi
}

# Pipe download to stdout (for curl | bash style installs)
# Falls back to curl since aria2 doesn't support piping
# Usage: download_pipe <url> | bash
download_pipe() {
    local url="$1"
    curl -fsSL --retry ${ARIA2_RETRIES} --retry-delay ${ARIA2_RETRY_WAIT} "$url"
}

# ============================================================================
# Package Installation Helpers
# ============================================================================

# Install packages if not already installed
# Usage: install_packages pkg1 pkg2 pkg3...
install_packages() {
    local packages=("$@")
    local to_install=()

    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        log_step "Installing: ${to_install[*]}"
        sudo pacman -S --needed --noconfirm "${to_install[@]}"
    else
        log_success "All packages already installed"
    fi
}

# ============================================================================
# Environment Helpers
# ============================================================================

# Add lines to shell rc file if not already present
# Usage: add_to_shellrc "export FOO=bar"
add_to_shellrc() {
    local line="$1"
    local shell_rc=""

    if [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    if ! grep -qF "$line" "$shell_rc" 2>/dev/null; then
        echo "$line" >> "$shell_rc"
        return 0
    fi
    return 1
}

# Get the appropriate shell rc file
get_shell_rc() {
    if [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

# ============================================================================
# Initialization
# ============================================================================

# Auto-setup aria2 when this file is sourced
_common_init() {
    check_arch
    setup_aria2
}

# Only run init if being sourced (not executed directly)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    _common_init
fi
