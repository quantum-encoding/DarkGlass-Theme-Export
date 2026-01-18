#!/bin/bash
# ============================================================================
# Android Development Stack Installer
# ============================================================================
# Installs: Android SDK, NDK, Platform Tools, Java JDK, Kotlin, Gradle
# Target: Full Android development environment (native + Flutter/React Native)
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Configuration
ANDROID_HOME="$HOME/Android/Sdk"
ANDROID_SDK_VERSION="34"
ANDROID_BUILD_TOOLS_VERSION="34.0.0"
ANDROID_NDK_VERSION="26.1.10909125"
JAVA_VERSION="17"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            Android Development Stack Installer               ║"
    echo "║       SDK + NDK + Java + Kotlin + Gradle + ADB               ║"
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

log_error() {
    echo -e "${RED}✗${NC} $1"
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        log_error "This script requires Arch Linux (pacman not found)"
        exit 1
    fi
}

# ============================================================================
# Java JDK Installation
# ============================================================================

install_java() {
    log_step "Installing Java JDK $JAVA_VERSION..."

    # Install OpenJDK
    sudo pacman -S --needed --noconfirm \
        jdk${JAVA_VERSION}-openjdk \
        jdk${JAVA_VERSION}-openjdk-doc

    # Set as default
    sudo archlinux-java set java-${JAVA_VERSION}-openjdk

    log_success "Java JDK installed: $(java --version 2>&1 | head -1)"
}

# ============================================================================
# Android Command Line Tools & SDK
# ============================================================================

install_android_sdk() {
    log_step "Setting up Android SDK..."

    # Create SDK directory
    mkdir -p "$ANDROID_HOME/cmdline-tools"

    # Check if command line tools already exist
    if [ -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
        log_success "Android command line tools already installed"
    else
        log_step "Downloading Android command line tools..."

        local cmdline_tools_url="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        local temp_zip="/tmp/android-cmdline-tools.zip"

        download_file "$cmdline_tools_url" "$temp_zip"
        unzip -q "$temp_zip" -d "$ANDROID_HOME/cmdline-tools/"
        mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
        rm "$temp_zip"

        log_success "Command line tools installed"
    fi

    # Setup environment variables for this session
    export ANDROID_HOME="$ANDROID_HOME"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

    # Accept licenses
    log_step "Accepting Android SDK licenses..."
    yes | sdkmanager --licenses > /dev/null 2>&1 || true

    # Install SDK components
    log_step "Installing Android SDK components..."

    sdkmanager --install \
        "platform-tools" \
        "platforms;android-${ANDROID_SDK_VERSION}" \
        "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
        "ndk;${ANDROID_NDK_VERSION}" \
        "extras;google;usb_driver" \
        "emulator" \
        "system-images;android-${ANDROID_SDK_VERSION};google_apis;x86_64" \
        2>/dev/null || {
            log_warning "Some SDK components may have failed to install. Run 'sdkmanager' manually to fix."
        }

    log_success "Android SDK components installed"
}

# ============================================================================
# Kotlin
# ============================================================================

install_kotlin() {
    log_step "Installing Kotlin..."

    sudo pacman -S --needed --noconfirm kotlin

    log_success "Kotlin installed: $(kotlin -version 2>&1 | head -1)"
}

# ============================================================================
# Gradle
# ============================================================================

install_gradle() {
    log_step "Installing Gradle..."

    sudo pacman -S --needed --noconfirm gradle

    log_success "Gradle installed: $(gradle --version 2>&1 | grep Gradle | head -1)"
}

# ============================================================================
# ADB & Fastboot (Platform Tools)
# ============================================================================

setup_adb() {
    log_step "Configuring ADB..."

    # Install Android udev rules for device detection
    if [ -f /etc/udev/rules.d/51-android.rules ]; then
        log_success "Android udev rules already configured"
    else
        log_step "Setting up udev rules for Android devices..."

        # Create udev rules
        sudo tee /etc/udev/rules.d/51-android.rules > /dev/null << 'EOF'
# Google
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
# Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
# OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666", GROUP="plugdev"
# Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"
# Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="plugdev"
# Sony
SUBSYSTEM=="usb", ATTR{idVendor}=="0fce", MODE="0666", GROUP="plugdev"
# LG
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="plugdev"
# Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
# HTC
SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="plugdev"
# ASUS
SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", MODE="0666", GROUP="plugdev"
# Generic
SUBSYSTEM=="usb", ATTR{idVendor}=="*", MODE="0666", GROUP="plugdev"
EOF

        sudo udevadm control --reload-rules
        sudo udevadm trigger

        # Add user to plugdev group
        sudo groupadd -f plugdev
        sudo usermod -aG plugdev "$USER"

        log_success "ADB udev rules configured"
        log_warning "You may need to log out and back in for group changes to take effect"
    fi
}

# ============================================================================
# Flutter (Optional)
# ============================================================================

install_flutter() {
    log_step "Installing Flutter..."

    if command -v flutter &> /dev/null; then
        log_success "Flutter already installed: $(flutter --version 2>&1 | head -1)"
        flutter upgrade
        return
    fi

    # Clone Flutter SDK (git is faster for repos)
    local flutter_dir="$HOME/development/flutter"
    mkdir -p "$(dirname "$flutter_dir")"

    if [ ! -d "$flutter_dir" ]; then
        log_step "Cloning Flutter repository..."
        git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$flutter_dir"
    fi

    # Add to PATH for this session
    export PATH="$flutter_dir/bin:$PATH"

    # Run flutter doctor
    flutter precache
    flutter doctor --android-licenses <<< "y" || true

    log_success "Flutter installed: $(flutter --version 2>&1 | head -1)"
}

# ============================================================================
# Environment Configuration
# ============================================================================

setup_environment() {
    log_step "Configuring environment variables..."

    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    # Check if already configured
    if grep -q "ANDROID_HOME" "$shell_rc" 2>/dev/null; then
        log_success "Environment already configured in $shell_rc"
        return
    fi

    cat >> "$shell_rc" << EOF

# Android Development Environment
export ANDROID_HOME="\$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="\$ANDROID_HOME"
export ANDROID_NDK_HOME="\$ANDROID_HOME/ndk/${ANDROID_NDK_VERSION}"

# Android SDK paths
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH"
export PATH="\$ANDROID_HOME/platform-tools:\$PATH"
export PATH="\$ANDROID_HOME/emulator:\$PATH"
export PATH="\$ANDROID_HOME/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:\$PATH"

# Flutter (if installed)
export PATH="\$HOME/development/flutter/bin:\$PATH"

# Java
export JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk"
EOF

    log_success "Environment variables added to $shell_rc"
    log_warning "Run 'source $shell_rc' or start a new terminal to apply changes"
}

# ============================================================================
# Verification
# ============================================================================

verify_installation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Verification${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Source environment
    export ANDROID_HOME="$ANDROID_HOME"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

    local all_good=true

    # Check components
    for cmd in java javac kotlin gradle; do
        if command -v "$cmd" &> /dev/null; then
            printf "  %-12s ${GREEN}✓${NC} %s\n" "$cmd:" "$($cmd --version 2>&1 | head -1)"
        else
            printf "  %-12s ${RED}✗${NC} not found\n" "$cmd:"
            all_good=false
        fi
    done

    # Check Android tools
    if command -v sdkmanager &> /dev/null; then
        printf "  %-12s ${GREEN}✓${NC} installed\n" "sdkmanager:"
    else
        printf "  %-12s ${RED}✗${NC} not found\n" "sdkmanager:"
        all_good=false
    fi

    if command -v adb &> /dev/null; then
        printf "  %-12s ${GREEN}✓${NC} %s\n" "adb:" "$(adb --version 2>&1 | head -1)"
    else
        printf "  %-12s ${RED}✗${NC} not found\n" "adb:"
        all_good=false
    fi

    # Check Flutter if installed
    if command -v flutter &> /dev/null; then
        printf "  %-12s ${GREEN}✓${NC} %s\n" "flutter:" "$(flutter --version 2>&1 | head -1)"
    fi

    echo ""
    echo "Android SDK Location: $ANDROID_HOME"
    echo ""

    if $all_good; then
        echo -e "${GREEN}All components installed successfully!${NC}"
    else
        echo -e "${YELLOW}Some components may need manual attention.${NC}"
    fi
}

# ============================================================================
# Main
# ============================================================================

print_header

# Parse arguments
INSTALL_FLUTTER=false
SKIP_VERIFY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --flutter)
            INSTALL_FLUTTER=true
            shift
            ;;
        --skip-verify)
            SKIP_VERIFY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --flutter        Also install Flutter SDK"
            echo "  --skip-verify    Skip verification step"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

check_arch

echo ""
log_step "Starting Android development stack installation..."
echo ""

install_java
install_android_sdk
install_kotlin
install_gradle
setup_adb

if $INSTALL_FLUTTER; then
    install_flutter
fi

setup_environment

if ! $SKIP_VERIFY; then
    verify_installation
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Android Development Stack Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  adb devices                  # List connected devices"
echo "  sdkmanager --list            # List available SDK packages"
echo "  avdmanager list device       # List available emulator devices"
echo ""
echo "Create emulator:"
echo "  avdmanager create avd -n test -k 'system-images;android-${ANDROID_SDK_VERSION};google_apis;x86_64'"
echo "  emulator -avd test"
echo ""

if $INSTALL_FLUTTER; then
    echo "Flutter:"
    echo "  flutter doctor              # Check Flutter setup"
    echo "  flutter create my_app       # Create new Flutter app"
    echo ""
fi

echo -e "${YELLOW}Remember to restart your terminal or run:${NC}"
echo "  source ~/.bashrc  (or ~/.zshrc)"
echo ""
