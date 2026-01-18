#!/bin/bash
# ============================================================================
# JesterNet OS - Local AUR Package Build/Test Script
# ============================================================================
# This script builds and optionally installs the package locally for testing
# before publishing to AUR.
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
PKGNAME="jesternet-os"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           JesterNet OS - Local Package Builder                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --build      Build package only (no install)"
    echo "  -i, --install    Build and install package"
    echo "  -c, --clean      Clean build artifacts"
    echo "  -s, --srcinfo    Generate .SRCINFO only"
    echo "  -t, --test       Build in clean chroot (requires devtools)"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --build       # Build package"
    echo "  $0 --install     # Build and install"
    echo "  $0 --srcinfo     # Generate .SRCINFO for AUR submission"
    echo ""
}

create_source_tarball() {
    print_step "Creating source tarball from parent directory..."

    local version=$(grep "pkgver=" "$SCRIPT_DIR/PKGBUILD" | cut -d= -f2)
    local tarball="${PKGNAME}-${version}.tar.gz"

    # Create tarball from parent directory (the actual source)
    cd "$PARENT_DIR/.."
    tar --exclude='aur-package' \
        --exclude='.git' \
        --exclude='*.tar.gz' \
        --exclude='pkg' \
        --exclude='src' \
        -czf "$SCRIPT_DIR/$tarball" \
        "$(basename "$PARENT_DIR")"

    cd "$SCRIPT_DIR"

    # Update PKGBUILD to use local source for testing
    print_step "Updating PKGBUILD for local build..."

    # Create a temporary PKGBUILD for local testing
    cp PKGBUILD PKGBUILD.local

    # Modify source to use local tarball
    sed -i "s|source=(.*)|source=(\"$tarball\")|" PKGBUILD.local

    # Update the extraction directory name
    sed -i "s|cd \"\${srcdir}/\${pkgname}-\${pkgver}\"|cd \"\${srcdir}/$(basename "$PARENT_DIR")\"|" PKGBUILD.local

    print_success "Created $tarball"
}

generate_srcinfo() {
    print_step "Generating .SRCINFO..."

    cd "$SCRIPT_DIR"

    if command -v makepkg &> /dev/null; then
        makepkg --printsrcinfo > .SRCINFO
        print_success ".SRCINFO generated"
    else
        print_error "makepkg not found - cannot generate .SRCINFO"
        exit 1
    fi
}

clean_build() {
    print_step "Cleaning build artifacts..."

    cd "$SCRIPT_DIR"

    rm -rf pkg/ src/ *.tar.zst *.tar.gz PKGBUILD.local 2>/dev/null || true

    print_success "Build artifacts cleaned"
}

build_package() {
    local install_flag="$1"

    print_step "Building package..."

    cd "$SCRIPT_DIR"

    # Create local source tarball
    create_source_tarball

    # Build using the local PKGBUILD
    if [[ "$install_flag" == "install" ]]; then
        makepkg -sf -p PKGBUILD.local -i
    else
        makepkg -sf -p PKGBUILD.local
    fi

    # Clean up temporary PKGBUILD
    rm -f PKGBUILD.local

    print_success "Package built successfully"

    # Show the built package
    echo ""
    print_step "Built package:"
    ls -lh *.pkg.tar.zst 2>/dev/null || ls -lh *.pkg.tar.xz 2>/dev/null || true
}

build_in_chroot() {
    print_step "Building in clean chroot (requires devtools)..."

    if ! command -v extra-x86_64-build &> /dev/null; then
        print_error "devtools not installed. Install with: sudo pacman -S devtools"
        exit 1
    fi

    cd "$SCRIPT_DIR"
    create_source_tarball

    # Use clean chroot build
    extra-x86_64-build -p PKGBUILD.local

    rm -f PKGBUILD.local

    print_success "Clean chroot build completed"
}

# Main
print_header

case "${1:-}" in
    -b|--build)
        build_package
        ;;
    -i|--install)
        build_package "install"
        ;;
    -c|--clean)
        clean_build
        ;;
    -s|--srcinfo)
        generate_srcinfo
        ;;
    -t|--test)
        build_in_chroot
        ;;
    -h|--help|"")
        show_help
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

echo ""
