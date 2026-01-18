#!/bin/bash
# ============================================================================
#       ██╗███████╗███████╗████████╗███████╗██████╗ ███╗   ██╗███████╗████████╗
#       ██║██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔════╝╚══██╔══╝
#       ██║█████╗  ███████╗   ██║   █████╗  ██████╔╝██╔██╗ ██║█████╗     ██║
#  ██   ██║██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝     ██║
#  ╚█████╔╝███████╗███████║   ██║   ███████╗██║  ██║██║ ╚████║███████╗   ██║
#   ╚════╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝
#                         OS Setup & Configuration
# ============================================================================
# Master installer for JesterNet OS theme and development environments
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_STACKS_DIR="$SCRIPT_DIR/dev-stacks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'

# ============================================================================
# UI Functions
# ============================================================================

clear_screen() {
    clear
}

print_banner() {
    echo -e "${MAGENTA}"
    cat << 'EOF'
       ╔═══════════════════════════════════════════════════════════════════╗
       ║                                                                   ║
       ║        ▄▄▄██▀▀▀▓█████   ██████ ▄▄▄█████▓▓█████  ██▀███          ║
       ║          ▒██   ▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒▓█   ▀ ▓██ ▒ ██▒        ║
       ║          ░██   ▒███   ░ ▓██▄   ▒ ▓██░ ▒░▒███   ▓██ ░▄█ ▒        ║
       ║       ▓██▄██▓  ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ ▒▓█  ▄ ▒██▀▀█▄          ║
       ║        ▓███▒   ░▒████▒▒██████▒▒  ▒██▒ ░ ░▒████▒░██▓ ▒██▒        ║
       ║        ▒▓▒▒░   ░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   ░░ ▒░ ░░ ▒▓ ░▒▓░        ║
       ║        ▒ ░▒░    ░ ░  ░░ ░▒  ░ ░    ░     ░ ░  ░  ░▒ ░ ▒░        ║
       ║        ░ ░ ░      ░   ░  ░  ░    ░         ░     ░░   ░         ║
       ║        ░   ░      ░  ░      ░              ░  ░   ░             ║
       ║                         N  E  T                                 ║
       ║                                                                 ║
       ║           Glassmorphic Theme + Development Stacks               ║
       ╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_menu() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                        MAIN MENU${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${MAGENTA}[T]${NC}  Install DarkGlass Theme      ${CYAN}(Glassmorphic desktop theme)${NC}"
    echo -e "  ${MAGENTA}[D]${NC}  Desktop Style                ${CYAN}(Choose Dock or Taskbar)${NC}"
    echo -e "  ${MAGENTA}[O]${NC}  Optimize Icons               ${CYAN}(Compress PNG icons)${NC}"
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}                    DEVELOPMENT STACKS${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC}  Tauri Stack                   ${CYAN}(Rust + Svelte + Tauri CLI)${NC}"
    echo -e "  ${GREEN}[2]${NC}  Android Stack                 ${CYAN}(SDK + NDK + Kotlin + Gradle)${NC}"
    echo -e "  ${GREEN}[3]${NC}  Go Stack                      ${CYAN}(Go + Tools + Protobuf)${NC}"
    echo -e "  ${GREEN}[4]${NC}  Python Stack                  ${CYAN}(Poetry + Ruff + Pyright)${NC}"
    echo -e "  ${GREEN}[5]${NC}  Zig Stack                     ${CYAN}(Zig + ZLS)${NC}"
    echo -e "  ${GREEN}[6]${NC}  Web Frontend Stack            ${CYAN}(Node + Bun + Vite + Tailwind)${NC}"
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}                    PRODUCTIVITY SUITES${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${BLUE}[7]${NC}  Office + Multimedia           ${CYAN}(LibreOffice + GIMP + VLC)${NC}"
    echo -e "  ${BLUE}[8]${NC}  Content Creator               ${CYAN}(OBS + Kdenlive + Audio)${NC}"
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}                      QUICK INSTALLS${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${YELLOW}[A]${NC}  Full Developer Setup          ${CYAN}(Theme + All Dev Stacks)${NC}"
    echo -e "  ${YELLOW}[C]${NC}  Creator Setup                 ${CYAN}(Theme + Office + Creator)${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${RED}[Q]${NC}  Quit"
    echo ""
}

# ============================================================================
# Installation Functions
# ============================================================================

run_script() {
    local script="$1"
    local name="$2"

    if [ -f "$script" ]; then
        echo ""
        echo -e "${CYAN}Starting: $name${NC}"
        echo ""
        chmod +x "$script"
        bash "$script"
        echo ""
        echo -e "${GREEN}Completed: $name${NC}"
        echo ""
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Script not found: $script${NC}"
        read -p "Press Enter to continue..."
    fi
}

install_theme() {
    run_script "$SCRIPT_DIR/install.sh" "DarkGlass Theme Installation"
    # Prompt for desktop style after theme install
    echo ""
    read -p "Would you like to choose a desktop style now? [y/N] " style_choice
    if [[ "$style_choice" =~ ^[Yy]$ ]]; then
        select_desktop_style
    fi
}

select_desktop_style() {
    run_script "$SCRIPT_DIR/desktop-style.sh" "Desktop Style Selection"
}

optimize_icons() {
    run_script "$SCRIPT_DIR/optimize-icons.sh" "Icon Optimization"
}

install_tauri() {
    run_script "$DEV_STACKS_DIR/tauri-stack.sh" "Tauri Development Stack"
}

install_android() {
    run_script "$DEV_STACKS_DIR/android-stack.sh" "Android Development Stack"
}

install_go() {
    run_script "$DEV_STACKS_DIR/go-stack.sh" "Go Development Stack"
}

install_python() {
    run_script "$DEV_STACKS_DIR/python-stack.sh" "Python Development Stack"
}

install_zig() {
    run_script "$DEV_STACKS_DIR/zig-stack.sh" "Zig Development Stack"
}

install_web() {
    run_script "$DEV_STACKS_DIR/web-stack.sh" "Web Frontend Development Stack"
}

install_office() {
    run_script "$DEV_STACKS_DIR/office-multimedia.sh" "Office & Multimedia Suite"
}

install_creator() {
    run_script "$DEV_STACKS_DIR/content-creator.sh" "Content Creator Suite"
}

install_full_dev() {
    echo ""
    echo -e "${YELLOW}Installing Full Developer Setup...${NC}"
    echo -e "${CYAN}This will install: Theme + Tauri + Go + Python + Zig + Web${NC}"
    echo ""
    read -p "Continue? [y/N] " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        install_theme
        install_tauri
        install_go
        install_python
        install_zig
        install_web
        echo ""
        echo -e "${GREEN}Full Developer Setup Complete!${NC}"
        read -p "Press Enter to continue..."
    fi
}

install_creator_setup() {
    echo ""
    echo -e "${YELLOW}Installing Creator Setup...${NC}"
    echo -e "${CYAN}This will install: Theme + Office/Multimedia + Content Creator${NC}"
    echo ""
    read -p "Continue? [y/N] " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        install_theme
        install_office
        install_creator
        echo ""
        echo -e "${GREEN}Creator Setup Complete!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# ============================================================================
# CLI Mode
# ============================================================================

show_cli_help() {
    echo "JesterNet OS Setup"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  theme           Install DarkGlass theme"
    echo "  dock            Install macOS-style dock"
    echo "  windows         Install Windows-style taskbar"
    echo "  optimize        Optimize/compress icons"
    echo "  tauri           Install Tauri development stack"
    echo "  android         Install Android development stack"
    echo "  go              Install Go development stack"
    echo "  python          Install Python development stack"
    echo "  zig             Install Zig development stack"
    echo "  web             Install Web frontend stack"
    echo "  office          Install Office & Multimedia suite"
    echo "  creator         Install Content Creator suite"
    echo "  full-dev        Install theme + all dev stacks"
    echo "  full-creator    Install theme + office + creator"
    echo "  menu            Show interactive menu (default)"
    echo ""
    echo "Examples:"
    echo "  $0 theme        # Install just the theme"
    echo "  $0 tauri go     # Install Tauri and Go stacks"
    echo "  $0 full-dev     # Install everything for development"
}

run_cli() {
    case "$1" in
        theme)
            bash "$SCRIPT_DIR/install.sh"
            ;;
        dock|mac|macos)
            bash "$SCRIPT_DIR/desktop-style.sh" dock
            ;;
        windows|taskbar|panel)
            bash "$SCRIPT_DIR/desktop-style.sh" windows
            ;;
        optimize)
            bash "$SCRIPT_DIR/optimize-icons.sh"
            ;;
        tauri)
            bash "$DEV_STACKS_DIR/tauri-stack.sh"
            ;;
        android)
            bash "$DEV_STACKS_DIR/android-stack.sh"
            ;;
        go)
            bash "$DEV_STACKS_DIR/go-stack.sh"
            ;;
        python)
            bash "$DEV_STACKS_DIR/python-stack.sh"
            ;;
        zig)
            bash "$DEV_STACKS_DIR/zig-stack.sh"
            ;;
        web)
            bash "$DEV_STACKS_DIR/web-stack.sh"
            ;;
        office)
            bash "$DEV_STACKS_DIR/office-multimedia.sh"
            ;;
        creator)
            bash "$DEV_STACKS_DIR/content-creator.sh"
            ;;
        full-dev)
            bash "$SCRIPT_DIR/install.sh"
            bash "$DEV_STACKS_DIR/tauri-stack.sh"
            bash "$DEV_STACKS_DIR/go-stack.sh"
            bash "$DEV_STACKS_DIR/python-stack.sh"
            bash "$DEV_STACKS_DIR/zig-stack.sh"
            bash "$DEV_STACKS_DIR/web-stack.sh"
            ;;
        full-creator)
            bash "$SCRIPT_DIR/install.sh"
            bash "$DEV_STACKS_DIR/office-multimedia.sh"
            bash "$DEV_STACKS_DIR/content-creator.sh"
            ;;
        -h|--help|help)
            show_cli_help
            ;;
        menu|"")
            return 1  # Signal to run interactive menu
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run '$0 --help' for usage"
            exit 1
            ;;
    esac
    return 0
}

# ============================================================================
# Main Interactive Menu
# ============================================================================

main_menu() {
    while true; do
        clear_screen
        print_banner
        print_menu

        read -p "  Select option: " choice

        case "${choice^^}" in
            T) install_theme ;;
            D) select_desktop_style ;;
            O) optimize_icons ;;
            1) install_tauri ;;
            2) install_android ;;
            3) install_go ;;
            4) install_python ;;
            5) install_zig ;;
            6) install_web ;;
            7) install_office ;;
            8) install_creator ;;
            A) install_full_dev ;;
            C) install_creator_setup ;;
            Q)
                echo ""
                echo -e "${CYAN}Thanks for using JesterNet OS Setup!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option: $choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# Entry Point
# ============================================================================

# Check for Arch Linux
if ! command -v pacman &> /dev/null; then
    echo -e "${RED}Error: This script requires Arch Linux (pacman not found)${NC}"
    exit 1
fi

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
chmod +x "$DEV_STACKS_DIR"/*.sh 2>/dev/null || true

# Handle CLI arguments or run interactive menu
if [ $# -gt 0 ]; then
    # Process multiple CLI commands
    for cmd in "$@"; do
        run_cli "$cmd" || main_menu
    done
else
    main_menu
fi
