#!/bin/bash
# ============================================================================
# Icon Optimization Script - JesterNet Theme System
# ============================================================================
# Compresses PNG icons while maintaining visual quality.
# Target: Reduce 89MB icon set to ~5-10MB
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$SCRIPT_DIR/icons/DarkGlass"
BACKUP_DIR="$SCRIPT_DIR/icons-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          JesterNet Icon Optimization Engine                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_dependencies() {
    local missing=()

    for cmd in pngquant optipng; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Installing missing dependencies...${NC}"
        sudo pacman -S --needed --noconfirm "${missing[@]}"
    fi

    echo -e "${GREEN}✓ All dependencies available${NC}"
}

get_size() {
    du -sb "$1" 2>/dev/null | cut -f1
}

format_size() {
    local bytes=$1
    if [ "$bytes" -gt 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc)MB"
    elif [ "$bytes" -gt 1024 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc)KB"
    else
        echo "${bytes}B"
    fi
}

optimize_png() {
    local file="$1"
    local original_size=$(get_size "$file")

    # Stage 1: pngquant - lossy compression with quality preservation
    # 256 colors is plenty for icons, quality 65-80 is visually lossless
    pngquant --quality=65-80 --speed 1 --force --ext .png "$file" 2>/dev/null || true

    # Stage 2: optipng - lossless optimization of the result
    optipng -o2 -quiet "$file" 2>/dev/null || true

    local new_size=$(get_size "$file")
    local saved=$((original_size - new_size))
    local percent=0
    if [ "$original_size" -gt 0 ]; then
        percent=$((saved * 100 / original_size))
    fi

    echo "$saved"
}

backup_icons() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Creating backup...${NC}"
        cp -r "$ICONS_DIR" "$BACKUP_DIR"
        echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"
    else
        echo -e "${CYAN}Backup already exists, skipping...${NC}"
    fi
}

restore_backup() {
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Restoring from backup...${NC}"
        rm -rf "$ICONS_DIR"
        cp -r "$BACKUP_DIR" "$ICONS_DIR"
        echo -e "${GREEN}✓ Icons restored from backup${NC}"
    else
        echo -e "${RED}No backup found!${NC}"
        exit 1
    fi
}

optimize_all() {
    local total_saved=0
    local file_count=0
    local original_total=$(get_size "$ICONS_DIR")

    echo ""
    echo -e "${CYAN}Starting optimization...${NC}"
    echo ""

    # Find all PNG files
    while IFS= read -r -d '' png_file; do
        local filename=$(basename "$png_file")
        local dir=$(dirname "$png_file" | sed "s|$ICONS_DIR/||")

        printf "  %-50s" "$dir/$filename"

        local saved=$(optimize_png "$png_file")
        total_saved=$((total_saved + saved))
        file_count=$((file_count + 1))

        if [ "$saved" -gt 0 ]; then
            echo -e "${GREEN}saved $(format_size $saved)${NC}"
        else
            echo -e "${YELLOW}already optimal${NC}"
        fi

    done < <(find "$ICONS_DIR" -name "*.png" -type f -print0)

    local new_total=$(get_size "$ICONS_DIR")

    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Optimization Complete!${NC}"
    echo ""
    echo "  Files processed:  $file_count"
    echo "  Original size:    $(format_size $original_total)"
    echo "  New size:         $(format_size $new_total)"
    echo "  Total saved:      $(format_size $total_saved)"

    if [ "$original_total" -gt 0 ]; then
        local percent=$((total_saved * 100 / original_total))
        echo "  Reduction:        ${percent}%"
    fi
    echo ""
}

# Resize icons to standard sizes (optional aggressive mode)
resize_icons() {
    local target_size="${1:-256}"

    echo -e "${YELLOW}Resizing icons to ${target_size}x${target_size}...${NC}"

    while IFS= read -r -d '' png_file; do
        # Get current dimensions
        local dims=$(identify -format "%wx%h" "$png_file" 2>/dev/null)
        local width=$(echo "$dims" | cut -dx -f1)

        if [ "$width" -gt "$target_size" ]; then
            convert "$png_file" -resize "${target_size}x${target_size}" "$png_file"
            printf "  Resized: %s\n" "$(basename "$png_file")"
        fi
    done < <(find "$ICONS_DIR" -name "*.png" -type f -print0)

    echo -e "${GREEN}✓ Resize complete${NC}"
}

show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  optimize    Compress all PNG icons (default)"
    echo "  resize      Resize icons to 256x256 (aggressive)"
    echo "  resize512   Resize icons to 512x512 (moderate)"
    echo "  restore     Restore icons from backup"
    echo "  status      Show current icon sizes"
    echo ""
    echo "Examples:"
    echo "  $0              # Run optimization"
    echo "  $0 resize       # Resize to 256x256 then optimize"
    echo "  $0 restore      # Undo changes"
}

show_status() {
    echo -e "${CYAN}Current Icon Status:${NC}"
    echo ""

    local total_size=$(get_size "$ICONS_DIR")
    local png_count=$(find "$ICONS_DIR" -name "*.png" -type f | wc -l)
    local svg_count=$(find "$ICONS_DIR" -name "*.svg" -type f | wc -l)

    echo "  Total size:   $(format_size $total_size)"
    echo "  PNG files:    $png_count"
    echo "  SVG files:    $svg_count"
    echo ""

    echo "  By directory:"
    for dir in apps mimetypes places; do
        if [ -d "$ICONS_DIR/$dir" ]; then
            local dir_size=$(get_size "$ICONS_DIR/$dir")
            printf "    %-12s %s\n" "$dir:" "$(format_size $dir_size)"
        fi
    done

    if [ -d "$BACKUP_DIR" ]; then
        echo ""
        echo -e "  ${GREEN}Backup available at: $BACKUP_DIR${NC}"
    fi
}

# Main
print_header

case "${1:-optimize}" in
    optimize)
        check_dependencies
        backup_icons
        optimize_all
        ;;
    resize)
        check_dependencies
        backup_icons
        resize_icons 256
        optimize_all
        ;;
    resize512)
        check_dependencies
        backup_icons
        resize_icons 512
        optimize_all
        ;;
    restore)
        restore_backup
        ;;
    status)
        show_status
        ;;
    -h|--help|help)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac
