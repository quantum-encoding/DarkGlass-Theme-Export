#!/bin/bash
# ============================================================================
# Tauri Development Stack Installer
# ============================================================================
# Installs: Rust, Node.js, Tauri CLI, Svelte/SvelteKit, React (optional)
# Target: Full Tauri app development environment
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Tauri Development Stack Installer               ║"
    echo "║         Rust + Node.js + Tauri CLI + Svelte/React            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================================================================
# Core Dependencies
# ============================================================================

install_system_deps() {
    log_step "Installing system dependencies..."

    # Tauri requires these system libraries
    local packages=(
        # Build essentials
        base-devel
        gcc
        pkg-config
        openssl

        # Webkit/GTK for Tauri
        webkit2gtk-4.1
        gtk3
        libappindicator-gtk3

        # Additional Tauri deps
        librsvg
        libsoup3
        glib2

        # Development tools
        git
        curl
        wget
    )

    sudo pacman -S --needed --noconfirm "${packages[@]}"
    log_success "System dependencies installed"
}

# ============================================================================
# Rust Installation
# ============================================================================

install_rust() {
    log_step "Checking Rust installation..."

    if command -v rustc &> /dev/null; then
        local rust_version=$(rustc --version | awk '{print $2}')
        log_success "Rust already installed: v$rust_version"

        # Update if needed
        log_step "Updating Rust..."
        rustup update stable
    else
        log_step "Installing Rust via rustup..."
        download_pipe "https://sh.rustup.rs" | sh -s -- -y --default-toolchain stable

        # Source cargo env
        source "$HOME/.cargo/env"
        log_success "Rust installed: $(rustc --version)"
    fi

    # Ensure wasm target is available for potential web builds
    log_step "Adding WebAssembly target..."
    rustup target add wasm32-unknown-unknown
    log_success "WASM target added"
}

# ============================================================================
# Node.js Installation
# ============================================================================

install_nodejs() {
    log_step "Checking Node.js installation..."

    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_success "Node.js already installed: $node_version"
    else
        log_step "Installing Node.js LTS..."

        # Install via pacman (or use nvm if preferred)
        sudo pacman -S --needed --noconfirm nodejs npm

        log_success "Node.js installed: $(node --version)"
    fi

    # Install pnpm (faster, better than npm)
    if ! command -v pnpm &> /dev/null; then
        log_step "Installing pnpm..."
        npm install -g pnpm
        log_success "pnpm installed"
    else
        log_success "pnpm already installed"
    fi

    # Install bun (blazing fast JS runtime/bundler)
    if ! command -v bun &> /dev/null; then
        log_step "Installing Bun..."
        download_pipe "https://bun.sh/install" | bash
        export PATH="$HOME/.bun/bin:$PATH"
        log_success "Bun installed: $(bun --version)"
    else
        log_success "Bun already installed: $(bun --version)"
    fi
}

# ============================================================================
# Tauri CLI Installation
# ============================================================================

install_tauri_cli() {
    log_step "Installing Tauri CLI..."

    # Install via cargo (most reliable)
    if ! command -v cargo-tauri &> /dev/null && ! cargo tauri --version &> /dev/null 2>&1; then
        cargo install tauri-cli
        log_success "Tauri CLI installed"
    else
        log_success "Tauri CLI already installed"
        # Update to latest
        cargo install tauri-cli --force 2>/dev/null || true
    fi

    # Install create-tauri-app for scaffolding
    log_step "Installing create-tauri-app..."
    cargo install create-tauri-app
    log_success "create-tauri-app installed"
}

# ============================================================================
# Frontend Frameworks
# ============================================================================

setup_svelte() {
    log_step "Setting up SvelteKit globals..."

    # Global Svelte tools (optional, projects usually have local deps)
    npm install -g svelte-language-server
    log_success "Svelte language server installed"
}

# ============================================================================
# VS Code / Editor Extensions (Optional)
# ============================================================================

suggest_vscode_extensions() {
    echo ""
    echo -e "${CYAN}Recommended VS Code Extensions:${NC}"
    echo "  - rust-analyzer (Rust)"
    echo "  - Svelte for VS Code"
    echo "  - Tauri"
    echo "  - Even Better TOML"
    echo "  - Error Lens"
    echo ""
    echo "Install via: code --install-extension <extension-id>"
}

# ============================================================================
# Project Scaffolding Helper
# ============================================================================

create_project_helper() {
    local helper_script="$HOME/.local/bin/new-tauri-app"

    mkdir -p "$HOME/.local/bin"

    cat > "$helper_script" << 'SCRIPT'
#!/bin/bash
# Quick Tauri project scaffolding

if [ -z "$1" ]; then
    echo "Usage: new-tauri-app <project-name> [template]"
    echo ""
    echo "Templates:"
    echo "  svelte     - SvelteKit + Tauri (default)"
    echo "  react      - React + Vite + Tauri"
    echo "  vue        - Vue + Vite + Tauri"
    echo "  vanilla    - Vanilla JS + Tauri"
    exit 1
fi

PROJECT_NAME="$1"
TEMPLATE="${2:-svelte}"

echo "Creating Tauri project: $PROJECT_NAME (template: $TEMPLATE)"

case "$TEMPLATE" in
    svelte)
        pnpm create tauri-app "$PROJECT_NAME" --template svelte-ts
        ;;
    react)
        pnpm create tauri-app "$PROJECT_NAME" --template react-ts
        ;;
    vue)
        pnpm create tauri-app "$PROJECT_NAME" --template vue-ts
        ;;
    vanilla)
        pnpm create tauri-app "$PROJECT_NAME" --template vanilla-ts
        ;;
    *)
        echo "Unknown template: $TEMPLATE"
        exit 1
        ;;
esac

cd "$PROJECT_NAME"
pnpm install
echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  pnpm tauri dev"
SCRIPT

    chmod +x "$helper_script"
    log_success "Helper script created: new-tauri-app"
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

    local all_good=true

    # Check each component
    for cmd in rustc cargo node npm pnpm; do
        if command -v "$cmd" &> /dev/null; then
            printf "  %-12s ${GREEN}✓${NC} %s\n" "$cmd:" "$($cmd --version 2>/dev/null | head -1)"
        else
            printf "  %-12s ${RED}✗${NC} not found\n" "$cmd:"
            all_good=false
        fi
    done

    # Check tauri specifically
    if cargo tauri --version &> /dev/null 2>&1; then
        printf "  %-12s ${GREEN}✓${NC} %s\n" "tauri-cli:" "$(cargo tauri --version 2>/dev/null)"
    else
        printf "  %-12s ${RED}✗${NC} not found\n" "tauri-cli:"
        all_good=false
    fi

    # Check bun
    if command -v bun &> /dev/null; then
        printf "  %-12s ${GREEN}✓${NC} %s\n" "bun:" "$(bun --version 2>/dev/null)"
    fi

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
SKIP_VERIFY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-verify)
            SKIP_VERIFY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-verify    Skip verification step"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo ""
log_step "Starting Tauri stack installation..."
echo ""

install_system_deps
install_rust
install_nodejs
install_tauri_cli
setup_svelte
create_project_helper

if ! $SKIP_VERIFY; then
    verify_installation
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tauri Development Stack Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  new-tauri-app my-app          # Create new Svelte + Tauri app"
echo "  new-tauri-app my-app react    # Create new React + Tauri app"
echo ""
echo "Or manually:"
echo "  pnpm create tauri-app"
echo ""
suggest_vscode_extensions
