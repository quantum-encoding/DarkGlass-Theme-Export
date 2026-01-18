#!/bin/bash
# ============================================================================
# Desktop Style Selector - JesterNet OS
# ============================================================================
# Choose between macOS-style Dock or Windows-style Taskbar
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_header() {
    echo -e "${MAGENTA}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                   DESKTOP STYLE SELECTOR                         ║
║              Choose Your Preferred Workflow                      ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_dock_preview() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ┌─────────────────────────────────────────────────────────────┐
    │  Activities                          🔊 🔋 📶  Mon 12:00    │
    ├─────────────────────────────────────────────────────────────┤
    │                                                             │
    │                                                             │
    │                      Your Desktop                           │
    │                                                             │
    │                                                             │
    ├─────────────────────────────────────────────────────────────┤
    │       🦊  📁  💻  🎵  ⚙️   |  📌 Running  |   🗑️            │
    │                      ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔                        │
    └─────────────────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
}

print_taskbar_preview() {
    echo -e "${BLUE}"
    cat << 'EOF'
    ┌─────────────────────────────────────────────────────────────┐
    │                                                             │
    │                                                             │
    │                      Your Desktop                           │
    │                                                             │
    │                                                             │
    ├─────────────────────────────────────────────────────────────┤
    │ ⬡ Apps │ 🦊 Firefox │ 📁 Files │ 💻 Term │   🔊 🔋 12:00   │
    └─────────────────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
}

# ============================================================================
# Extension Installation
# ============================================================================

check_gnome_extensions_cli() {
    if ! command -v gnome-extensions &> /dev/null; then
        log_error "gnome-extensions command not found"
        log_step "Installing gnome-shell-extensions..."
        sudo pacman -S --needed --noconfirm gnome-shell-extensions
    fi
}

install_extension_from_url() {
    local name="$1"
    local uuid="$2"
    local url="$3"

    log_step "Installing $name..."

    local ext_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"

    if [ -d "$ext_dir" ]; then
        log_success "$name already installed"
        return 0
    fi

    mkdir -p "$ext_dir"

    # Download extension
    local temp_zip="/tmp/${uuid}.zip"

    if command -v aria2c &> /dev/null; then
        aria2c -x 16 -o "$temp_zip" "$url" 2>/dev/null || curl -sL -o "$temp_zip" "$url"
    else
        curl -sL -o "$temp_zip" "$url"
    fi

    # Extract
    unzip -q "$temp_zip" -d "$ext_dir" 2>/dev/null || {
        log_error "Failed to extract $name"
        return 1
    }

    rm -f "$temp_zip"
    log_success "$name installed"
}

install_dash_to_dock() {
    log_step "Setting up Dash to Dock (macOS-style)..."

    # Check if available in repos first
    if pacman -Qi gnome-shell-extension-dash-to-dock &> /dev/null; then
        log_success "Dash to Dock already installed via pacman"
    else
        # Try to install from repos
        sudo pacman -S --needed --noconfirm gnome-shell-extension-dash-to-dock 2>/dev/null || {
            log_warning "Not in repos, please install from extensions.gnome.org"
            echo ""
            echo -e "  ${CYAN}Visit:${NC} https://extensions.gnome.org/extension/307/dash-to-dock/"
            echo ""
        }
    fi
}

install_dash_to_panel() {
    log_step "Setting up Dash to Panel (Windows-style)..."

    # Check if available in repos first
    if pacman -Qi gnome-shell-extension-dash-to-panel &> /dev/null; then
        log_success "Dash to Panel already installed via pacman"
    else
        # Try to install from repos
        sudo pacman -S --needed --noconfirm gnome-shell-extension-dash-to-panel 2>/dev/null || {
            log_warning "Not in repos, please install from extensions.gnome.org"
            echo ""
            echo -e "  ${CYAN}Visit:${NC} https://extensions.gnome.org/extension/1160/dash-to-panel/"
            echo ""
        }
    fi
}

# ============================================================================
# Configuration
# ============================================================================

configure_dock_style() {
    log_step "Configuring Dock (macOS) style..."

    # Disable Dash to Panel if enabled
    gnome-extensions disable dash-to-panel@jderose9.github.com 2>/dev/null || true

    # Enable Dash to Dock
    gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true

    # Configure Dash to Dock settings
    dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed false
    dconf write /org/gnome/shell/extensions/dash-to-dock/autohide true
    dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide true
    dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false
    dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 48
    dconf write /org/gnome/shell/extensions/dash-to-dock/background-opacity 0.7
    dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'DYNAMIC'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/custom-theme-shrink true
    dconf write /org/gnome/shell/extensions/dash-to-dock/show-trash true
    dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts false
    dconf write /org/gnome/shell/extensions/dash-to-dock/running-indicator-style "'DOTS'"

    # JesterNet colors
    dconf write /org/gnome/shell/extensions/dash-to-dock/custom-background-color true
    dconf write /org/gnome/shell/extensions/dash-to-dock/background-color "'rgba(10, 10, 20, 0.7)'"

    log_success "Dock style configured"
}

configure_taskbar_style() {
    log_step "Configuring Taskbar (Windows) style..."

    # Disable Dash to Dock if enabled
    gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null || true

    # Enable Dash to Panel
    gnome-extensions enable dash-to-panel@jderose9.github.com 2>/dev/null || true

    # Configure Dash to Panel settings
    dconf write /org/gnome/shell/extensions/dash-to-panel/panel-positions '{"0":"BOTTOM"}'
    dconf write /org/gnome/shell/extensions/dash-to-panel/panel-sizes '{"0":42}'
    dconf write /org/gnome/shell/extensions/dash-to-panel/panel-element-positions '{"0":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'

    # Appearance
    dconf write /org/gnome/shell/extensions/dash-to-panel/trans-use-custom-bg true
    dconf write /org/gnome/shell/extensions/dash-to-panel/trans-bg-color "'#0a0a14'"
    dconf write /org/gnome/shell/extensions/dash-to-panel/trans-use-custom-opacity true
    dconf write /org/gnome/shell/extensions/dash-to-panel/trans-panel-opacity 0.7

    # Taskbar behavior
    dconf write /org/gnome/shell/extensions/dash-to-panel/group-apps true
    dconf write /org/gnome/shell/extensions/dash-to-panel/group-apps-label-font-size 12
    dconf write /org/gnome/shell/extensions/dash-to-panel/group-apps-use-launchers false
    dconf write /org/gnome/shell/extensions/dash-to-panel/isolate-workspaces true

    # App button (like Start menu)
    dconf write /org/gnome/shell/extensions/dash-to-panel/show-apps-icon-file "'/usr/share/icons/hicolor/scalable/apps/start-here.svg'"
    dconf write /org/gnome/shell/extensions/dash-to-panel/animate-appicon-hover true

    # Running indicators
    dconf write /org/gnome/shell/extensions/dash-to-panel/dot-style-focused "'DASHES'"
    dconf write /org/gnome/shell/extensions/dash-to-panel/dot-style-unfocused "'DOTS'"
    dconf write /org/gnome/shell/extensions/dash-to-panel/dot-color-override true
    dconf write /org/gnome/shell/extensions/dash-to-panel/dot-color-1 "'#00ffff'"
    dconf write /org/gnome/shell/extensions/dash-to-panel/dot-color-2 "'#ff00ff'"

    log_success "Taskbar style configured"
}

# ============================================================================
# Main Selection Menu
# ============================================================================

show_selection_menu() {
    clear
    print_header

    echo -e "${CYAN}Choose your desktop style:${NC}"
    echo ""
    echo -e "  ${GREEN}[D]${NC} Dock Bar ${CYAN}(macOS-style)${NC}"
    echo "      - Centered dock at bottom"
    echo "      - Auto-hide when windows overlap"
    echo "      - Clean, minimal top bar"
    echo "      - Best for: macOS users, aesthetic lovers"
    echo ""
    print_dock_preview
    echo ""
    echo -e "  ${BLUE}[W]${NC} Windows Bar ${CYAN}(Taskbar-style)${NC}"
    echo "      - Full-width taskbar at bottom"
    echo "      - App menu (like Start button)"
    echo "      - Window list with labels"
    echo "      - Best for: Windows users, productivity focus"
    echo ""
    print_taskbar_preview
    echo ""
    echo -e "  ${YELLOW}[S]${NC} Skip - Keep current desktop style"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    local choice="$1"

    # If no argument, show interactive menu
    if [ -z "$choice" ]; then
        show_selection_menu
        read -p "  Select style [D/W/S]: " choice
    fi

    case "${choice^^}" in
        D|DOCK|MAC|MACOS)
            echo ""
            log_step "Installing Dock (macOS) style..."
            check_gnome_extensions_cli
            install_dash_to_dock
            configure_dock_style
            echo ""
            log_success "Dock style installed!"
            echo ""
            echo -e "${YELLOW}Please log out and back in for changes to take effect.${NC}"
            echo ""
            ;;

        W|WINDOWS|TASKBAR|PANEL)
            echo ""
            log_step "Installing Taskbar (Windows) style..."
            check_gnome_extensions_cli
            install_dash_to_panel
            configure_taskbar_style
            echo ""
            log_success "Taskbar style installed!"
            echo ""
            echo -e "${YELLOW}Please log out and back in for changes to take effect.${NC}"
            echo ""
            ;;

        S|SKIP)
            echo ""
            log_success "Keeping current desktop style"
            echo ""
            ;;

        *)
            log_error "Invalid choice: $choice"
            echo "Usage: $0 [dock|windows|skip]"
            exit 1
            ;;
    esac
}

# Run
main "$1"
