#!/bin/bash
# ============================================================================
# Web Frontend Development Stack Installer
# ============================================================================
# Installs: Node.js, Bun, pnpm, TypeScript, Vite, Tailwind, etc.
# Target: Modern frontend development environment
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            Web Frontend Development Stack                    ║"
    echo "║     Node.js + Bun + TypeScript + Vite + Tailwind             ║"
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

install_nodejs() {
    log_step "Installing Node.js LTS..."

    sudo pacman -S --needed --noconfirm nodejs npm

    log_success "Node.js installed: $(node --version)"
}

install_bun() {
    log_step "Installing Bun..."

    if command -v bun &> /dev/null; then
        log_success "Bun already installed: $(bun --version)"
        return
    fi

    download_pipe "https://bun.sh/install" | bash

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    log_success "Bun installed: $(bun --version)"
}

install_pnpm() {
    log_step "Installing pnpm..."

    if command -v pnpm &> /dev/null; then
        log_success "pnpm already installed"
        return
    fi

    npm install -g pnpm

    log_success "pnpm installed: $(pnpm --version)"
}

install_global_tools() {
    log_step "Installing global tools..."

    # TypeScript
    npm install -g typescript
    log_success "TypeScript installed"

    # tsx - Run TypeScript directly
    npm install -g tsx
    log_success "tsx installed"

    # Vite
    npm install -g vite
    log_success "Vite installed"

    # ESLint
    npm install -g eslint
    log_success "ESLint installed"

    # Prettier
    npm install -g prettier
    log_success "Prettier installed"

    # Tailwind CSS standalone CLI
    log_step "Installing Tailwind CSS CLI..."
    local tailwind_url="https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64"
    download_file "$tailwind_url" "/tmp/tailwindcss"
    sudo mv /tmp/tailwindcss /usr/local/bin/tailwindcss
    sudo chmod +x /usr/local/bin/tailwindcss
    log_success "Tailwind CSS CLI installed"

    # Serve - static file server
    npm install -g serve
    log_success "serve installed"

    # http-server
    npm install -g http-server
    log_success "http-server installed"
}

install_browsers() {
    log_step "Installing browsers for development..."

    # Firefox Developer Edition
    if ! pacman -Qi firefox-developer-edition &> /dev/null 2>&1; then
        log_step "Installing Firefox Developer Edition..."
        sudo pacman -S --needed --noconfirm firefox-developer-edition
        log_success "Firefox Developer Edition installed"
    else
        log_success "Firefox Developer Edition already installed"
    fi

    # Chromium (for testing)
    if ! pacman -Qi chromium &> /dev/null 2>&1; then
        log_step "Installing Chromium..."
        sudo pacman -S --needed --noconfirm chromium
        log_success "Chromium installed"
    else
        log_success "Chromium already installed"
    fi
}

setup_environment() {
    log_step "Configuring environment..."

    local shell_rc=""
    if [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    if grep -q "BUN_INSTALL" "$shell_rc" 2>/dev/null; then
        log_success "Environment already configured"
        return
    fi

    cat >> "$shell_rc" << 'EOF'

# Web Development Environment
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
EOF

    log_success "Environment configured in $shell_rc"
}

create_project_helpers() {
    mkdir -p "$HOME/.local/bin"

    # Svelte project helper
    cat > "$HOME/.local/bin/new-svelte-app" << 'SCRIPT'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: new-svelte-app <project-name>"
    exit 1
fi

PROJECT_NAME="$1"
echo "Creating SvelteKit project: $PROJECT_NAME"

pnpm create svelte@latest "$PROJECT_NAME"
cd "$PROJECT_NAME"
pnpm install
pnpm add -D tailwindcss postcss autoprefixer
pnpm exec tailwindcss init -p

echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  pnpm dev"
SCRIPT

    # React project helper
    cat > "$HOME/.local/bin/new-react-app" << 'SCRIPT'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: new-react-app <project-name>"
    exit 1
fi

PROJECT_NAME="$1"
echo "Creating React + Vite project: $PROJECT_NAME"

pnpm create vite "$PROJECT_NAME" --template react-ts
cd "$PROJECT_NAME"
pnpm install
pnpm add -D tailwindcss postcss autoprefixer
pnpm exec tailwindcss init -p

echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  pnpm dev"
SCRIPT

    # Vue project helper
    cat > "$HOME/.local/bin/new-vue-app" << 'SCRIPT'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: new-vue-app <project-name>"
    exit 1
fi

PROJECT_NAME="$1"
echo "Creating Vue + Vite project: $PROJECT_NAME"

pnpm create vite "$PROJECT_NAME" --template vue-ts
cd "$PROJECT_NAME"
pnpm install
pnpm add -D tailwindcss postcss autoprefixer
pnpm exec tailwindcss init -p

echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  pnpm dev"
SCRIPT

    # Vanilla project helper
    cat > "$HOME/.local/bin/new-web-app" << 'SCRIPT'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: new-web-app <project-name>"
    exit 1
fi

PROJECT_NAME="$1"
echo "Creating vanilla TypeScript + Vite project: $PROJECT_NAME"

pnpm create vite "$PROJECT_NAME" --template vanilla-ts
cd "$PROJECT_NAME"
pnpm install
pnpm add -D tailwindcss postcss autoprefixer
pnpm exec tailwindcss init -p

echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  pnpm dev"
SCRIPT

    chmod +x "$HOME/.local/bin/new-svelte-app"
    chmod +x "$HOME/.local/bin/new-react-app"
    chmod +x "$HOME/.local/bin/new-vue-app"
    chmod +x "$HOME/.local/bin/new-web-app"

    log_success "Project helper scripts created"
}

verify_installation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Verification${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"

    for cmd in node npm pnpm bun tsc vite eslint prettier tailwindcss; do
        if command -v "$cmd" &> /dev/null; then
            printf "  %-14s ${GREEN}✓${NC} %s\n" "$cmd:" "$($cmd --version 2>&1 | head -1)"
        else
            printf "  %-14s ${YELLOW}⚠${NC} not found\n" "$cmd:"
        fi
    done

    echo ""
}

# Main
print_header
check_arch

log_step "Starting web frontend development stack installation..."
echo ""

install_nodejs
install_bun
install_pnpm
install_global_tools
install_browsers
setup_environment
create_project_helpers
verify_installation

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Web Frontend Development Stack Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start - Create Projects:"
echo "  new-svelte-app my-app        # SvelteKit + Tailwind"
echo "  new-react-app my-app         # React + Vite + Tailwind"
echo "  new-vue-app my-app           # Vue + Vite + Tailwind"
echo "  new-web-app my-app           # Vanilla TS + Vite + Tailwind"
echo ""
echo "Development commands:"
echo "  pnpm dev                     # Start dev server"
echo "  pnpm build                   # Production build"
echo "  bun run dev                  # Alternative: Use Bun"
echo "  serve dist/                  # Serve production build"
echo ""
echo "Tailwind standalone:"
echo "  tailwindcss -i input.css -o output.css --watch"
echo ""
