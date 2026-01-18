#!/bin/bash
# ============================================================================
# Zig Development Stack Installer
# ============================================================================
# Installs: Zig, ZLS (language server), common tools
# Target: Full Zig development environment
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               Zig Development Stack Installer                ║"
    echo "║                   Zig + ZLS + Tools                          ║"
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

install_zig() {
    log_step "Installing Zig..."

    # Zig is in the official repos
    sudo pacman -S --needed --noconfirm zig

    log_success "Zig installed: $(zig version)"
}

install_zls() {
    log_step "Installing ZLS (Zig Language Server)..."

    # ZLS is in community repos
    sudo pacman -S --needed --noconfirm zls

    log_success "ZLS installed: $(zls --version 2>&1 | head -1)"
}

install_tools() {
    log_step "Installing development tools..."

    # Build essentials
    sudo pacman -S --needed --noconfirm \
        base-devel \
        git \
        gdb \
        lldb \
        valgrind

    log_success "Development tools installed"
}

create_project_helper() {
    local helper_script="$HOME/.local/bin/new-zig-project"

    mkdir -p "$HOME/.local/bin"

    cat > "$helper_script" << 'SCRIPT'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: new-zig-project <project-name> [type]"
    echo ""
    echo "Types:"
    echo "  exe     - Executable (default)"
    echo "  lib     - Library"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_TYPE="${2:-exe}"

echo "Creating Zig project: $PROJECT_NAME (type: $PROJECT_TYPE)"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize Zig project
zig init

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
zig-cache/
zig-out/
.zig-cache/
*.o
*.a
*.so
*.dll
GITIGNORE

echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  zig build"
echo "  zig build run"
SCRIPT

    chmod +x "$helper_script"
    log_success "Helper script created: new-zig-project"
}

verify_installation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Verification${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    for cmd in zig zls gdb; do
        if command -v "$cmd" &> /dev/null; then
            printf "  %-12s ${GREEN}✓${NC} %s\n" "$cmd:" "$($cmd --version 2>&1 | head -1)"
        else
            printf "  %-12s ${YELLOW}⚠${NC} not found\n" "$cmd:"
        fi
    done

    echo ""
}

# Main
print_header
check_arch

log_step "Starting Zig development stack installation..."
echo ""

install_zig
install_zls
install_tools
create_project_helper
verify_installation

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Zig Development Stack Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  new-zig-project my-app       # Create new executable"
echo "  new-zig-project my-lib lib   # Create new library"
echo ""
echo "Development commands:"
echo "  zig build                    # Build project"
echo "  zig build run                # Build and run"
echo "  zig build test               # Run tests"
echo "  zig fmt src/                 # Format code"
echo ""
