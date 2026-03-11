#!/bin/bash
# ============================================================================
#
#        ██╗███████╗███████╗████████╗███████╗██████╗ ███╗   ██╗███████╗████████╗
#        ██║██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔════╝╚══██╔══╝
#        ██║█████╗  ███████╗   ██║   █████╗  ██████╔╝██╔██╗ ██║█████╗     ██║
#   ██   ██║██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝     ██║
#   ╚█████╔╝███████╗███████║   ██║   ███████╗██║  ██║██║ ╚████║███████╗   ██║
#    ╚════╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝
#
#                    ARCH LINUX INSTALLATION SCRIPT
#                      Quantum Field Medic Edition
#
# ============================================================================
# Deploy from: Ventoy USB | Android ADB | Any Live Environment
# ============================================================================

set -e

# Ensure TERM is set (required for SSH/ADB deployments)
export TERM="${TERM:-xterm}"

# ============================================================================
# Configuration - EDIT THESE FOR YOUR SETUP
# ============================================================================

# Default values (will be overridden by interactive prompts or config file)
HOSTNAME="jesternet"
USERNAME="architect"
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"
KEYMAP="us"

# Partition sizes (in GB) - Set to "auto" for smart sizing based on disk
# These can be overridden in enterprise config files
EFI_SIZE="1"          # 1GB EFI partition (fixed, standard)
SWAP_SIZE="auto"      # Auto-calculated based on disk size (4-32GB)
ROOT_SIZE="auto"      # Auto-calculated based on disk size (30-300GB)
# HOME gets the rest of the disk

# Desktop style: "dock" (macOS) or "taskbar" (Windows)
DESKTOP_STYLE="dock"

# Development stacks to install (space-separated)
# Options: tauri go python zig web android office creator
DEV_STACKS=""

# ============================================================================
# Enterprise Configuration (for mass deployments)
# ============================================================================

# Mirror country (ISO 3166-1 alpha-2 code, e.g., US, DE, GB, AU)
MIRROR_COUNTRY="US"

# Network configuration (leave empty for DHCP)
STATIC_IP=""              # e.g., "192.168.1.100/24"
GATEWAY=""                # e.g., "192.168.1.1"
DNS_SERVERS=""            # e.g., "8.8.8.8,8.8.4.4"

# Proxy configuration (leave empty for no proxy)
HTTP_PROXY=""             # e.g., "http://proxy.corp.com:8080"
HTTPS_PROXY=""

# SSH configuration
SSH_ENABLED="true"        # Enable SSH server
SSH_AUTHORIZED_KEYS=""    # Path to authorized_keys file to inject

# Post-install hook script (runs at end of installation)
POST_INSTALL_HOOK=""      # Path to custom script to run

# Fleet management / domain join preparation
DOMAIN_JOIN_PREP="false"  # Install packages for AD/LDAP join
DOMAIN_REALM=""           # e.g., "CORP.EXAMPLE.COM"

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'

# ============================================================================
# Logging
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
# Smart Partition Sizing
# ============================================================================

calculate_partition_sizes() {
    local disk_gb=$1

    log_step "Calculating optimal partition sizes for ${disk_gb}GB disk..."

    # EFI is always 1GB
    EFI_SIZE=1

    # Swap sizing (if set to "auto")
    # Scale: 4GB for small disks, up to 32GB for very large disks
    if [ "$SWAP_SIZE" = "auto" ]; then
        if [ "$disk_gb" -lt 64 ]; then
            SWAP_SIZE=2
        elif [ "$disk_gb" -lt 128 ]; then
            SWAP_SIZE=4
        elif [ "$disk_gb" -lt 256 ]; then
            SWAP_SIZE=8
        elif [ "$disk_gb" -lt 512 ]; then
            SWAP_SIZE=8
        elif [ "$disk_gb" -lt 1024 ]; then
            SWAP_SIZE=16
        elif [ "$disk_gb" -lt 2048 ]; then
            SWAP_SIZE=16
        else
            SWAP_SIZE=32
        fi
    fi

    # Root sizing (if set to "auto")
    # Scale based on disk size with sensible minimums and maximums
    # Minimum 30GB, maximum 300GB
    if [ "$ROOT_SIZE" = "auto" ]; then
        if [ "$disk_gb" -lt 64 ]; then
            # Tiny disk: minimal root
            ROOT_SIZE=25
        elif [ "$disk_gb" -lt 128 ]; then
            # Small disk (64-128GB): ~30GB root
            ROOT_SIZE=30
        elif [ "$disk_gb" -lt 256 ]; then
            # Medium-small (128-256GB): ~50GB root
            ROOT_SIZE=50
        elif [ "$disk_gb" -lt 512 ]; then
            # Medium (256-512GB): ~80GB root
            ROOT_SIZE=80
        elif [ "$disk_gb" -lt 1024 ]; then
            # Large (512GB-1TB): ~150GB root
            ROOT_SIZE=150
        elif [ "$disk_gb" -lt 2048 ]; then
            # Very large (1-2TB): ~200GB root
            ROOT_SIZE=200
        elif [ "$disk_gb" -lt 4096 ]; then
            # Huge (2-4TB): ~250GB root
            ROOT_SIZE=250
        else
            # Massive (4TB+): ~300GB root (cap)
            ROOT_SIZE=300
        fi
    fi

    log_success "Partition sizing: EFI=${EFI_SIZE}GB, Swap=${SWAP_SIZE}GB, Root=${ROOT_SIZE}GB"
}

# ============================================================================
# Banner
# ============================================================================

print_banner() {
    clear
    echo -e "${MAGENTA}"
    cat << 'EOF'

     ██╗███████╗███████╗████████╗███████╗██████╗ ███╗   ██╗███████╗████████╗
     ██║██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔════╝╚══██╔══╝
     ██║█████╗  ███████╗   ██║   █████╗  ██████╔╝██╔██╗ ██║█████╗     ██║
██   ██║██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝     ██║
╚█████╔╝███████╗███████║   ██║   ███████╗██║  ██║██║ ╚████║███████╗   ██║
 ╚════╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝

                 ╔═══════════════════════════════════════╗
                 ║   ARCH LINUX INSTALLATION SCRIPT      ║
                 ║     Quantum Field Medic Edition       ║
                 ╚═══════════════════════════════════════╝

EOF
    echo -e "${NC}"
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

preflight_checks() {
    log_step "Running pre-flight checks..."

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        echo "Run: sudo $0"
        exit 1
    fi

    # Check if booted in UEFI mode
    if [ ! -d /sys/firmware/efi ]; then
        log_error "System not booted in UEFI mode"
        echo "Please boot in UEFI mode to continue"
        exit 1
    fi
    log_success "UEFI mode detected"

    # Check internet connectivity (use IP to avoid DNS issues)
    if ! ping -c 1 -W 5 8.8.8.8 &> /dev/null; then
        log_error "No internet connection"
        echo "Please connect to the internet first"
        echo "  For WiFi: iwctl station wlan0 connect <SSID>"
        exit 1
    fi
    log_success "Internet connection active"

    # Ensure DNS is working (use Cloudflare as fallback)
    if ! getent hosts archlinux.org &> /dev/null; then
        log_warning "DNS not configured, setting up fallback..."
        echo "nameserver 1.1.1.1" > /etc/resolv.conf
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    fi

    # Check if arch-chroot is available
    if ! command -v arch-chroot &> /dev/null; then
        log_error "arch-chroot not found. Are you in the Arch live environment?"
        exit 1
    fi
    log_success "Arch live environment detected"

    # Sync time
    log_step "Syncing system clock..."
    timedatectl set-ntp true
    log_success "System clock synced"

    # Update pacman keyring (critical for older ISOs)
    log_step "Updating pacman keyring (required for older installation media)..."
    pacman-key --init 2>/dev/null || true
    pacman-key --populate archlinux 2>/dev/null || true
    pacman -Sy --noconfirm archlinux-keyring 2>/dev/null || true
    log_success "Keyring updated"
}

# ============================================================================
# Disk Selection
# ============================================================================

list_disks() {
    echo ""
    echo -e "${CYAN}Available disks:${NC}"
    echo ""
    lsblk -d -p -n -o NAME,SIZE,MODEL | grep -E "^/dev/(sd|nvme|vd|mmcblk)" | while read line; do
        echo "  $line"
    done
    echo ""
}

select_disk() {
    list_disks

    echo -e "${YELLOW}WARNING: The selected disk will be COMPLETELY ERASED!${NC}"
    echo ""

    # If TARGET_DISK already set from config, use it
    if [ -n "$TARGET_DISK" ] && [ -b "$TARGET_DISK" ]; then
        log_step "Using disk from config: $TARGET_DISK"
    else
        read -p "Enter disk to install to (e.g., /dev/nvme0n1 or /dev/sda): " TARGET_DISK
    fi

    # Validate disk exists
    if [ ! -b "$TARGET_DISK" ]; then
        log_error "Disk $TARGET_DISK does not exist"
        exit 1
    fi

    # Get disk size in GB
    DISK_SIZE_BYTES=$(lsblk -b -d -n -o SIZE "$TARGET_DISK")
    DISK_SIZE_GB=$((DISK_SIZE_BYTES / 1024 / 1024 / 1024))

    echo ""
    echo -e "Selected disk: ${GREEN}$TARGET_DISK${NC} (${DISK_SIZE_GB}GB)"
    echo ""

    # Calculate optimal partition sizes based on disk size
    calculate_partition_sizes "$DISK_SIZE_GB"

    # Calculate home size (gets remaining space)
    HOME_SIZE=$((DISK_SIZE_GB - EFI_SIZE - SWAP_SIZE - ROOT_SIZE - 1))

    if [ "$HOME_SIZE" -lt 5 ]; then
        log_error "Disk too small. Need at least $((EFI_SIZE + SWAP_SIZE + ROOT_SIZE + 5))GB (minimum ~40GB recommended)"
        exit 1
    fi

    echo "Partition layout:"
    echo "  EFI:  ${EFI_SIZE}GB"
    echo "  SWAP: ${SWAP_SIZE}GB"
    echo "  ROOT: ${ROOT_SIZE}GB  (/)"
    echo "  HOME: ${HOME_SIZE}GB  (/home)"
    echo ""

    # If config file provided, auto-confirm
    if [ -n "$CONFIG_FILE" ]; then
        log_step "Auto-confirming from config file..."
    else
        read -p "Proceed with installation? This will ERASE ALL DATA on $TARGET_DISK [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            exit 0
        fi
    fi
}

# ============================================================================
# User Configuration
# ============================================================================

configure_user() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    USER CONFIGURATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # If using config file, skip interactive prompts (but require password)
    if [ -n "$CONFIG_FILE" ]; then
        log_step "Using configuration from $CONFIG_FILE"
        echo "  Hostname: $HOSTNAME"
        echo "  Username: $USERNAME"
        echo "  Timezone: $TIMEZONE"

        # Password must still be set - prompt if missing from config
        if [ -z "$USER_PASSWORD" ]; then
            while true; do
                read -s -p "Password: " USER_PASSWORD
                echo ""
                read -s -p "Confirm password: " USER_PASSWORD_CONFIRM
                echo ""
                if [ "$USER_PASSWORD" = "$USER_PASSWORD_CONFIRM" ]; then
                    break
                else
                    log_error "Passwords do not match. Try again."
                fi
            done
        fi

        log_success "Configuration loaded from file"
        return
    fi

    read -p "Hostname [$HOSTNAME]: " input
    HOSTNAME="${input:-$HOSTNAME}"

    read -p "Username [$USERNAME]: " input
    USERNAME="${input:-$USERNAME}"

    while true; do
        read -s -p "Password: " USER_PASSWORD
        echo ""
        read -s -p "Confirm password: " USER_PASSWORD_CONFIRM
        echo ""

        if [ "$USER_PASSWORD" = "$USER_PASSWORD_CONFIRM" ]; then
            break
        else
            log_error "Passwords do not match. Try again."
        fi
    done

    # Timezone selection
    echo ""
    echo "Common timezones:"
    echo "  1) America/New_York"
    echo "  2) America/Los_Angeles"
    echo "  3) America/Chicago"
    echo "  4) Europe/London"
    echo "  5) Europe/Berlin"
    echo "  6) Asia/Tokyo"
    echo "  7) Australia/Sydney"
    echo "  8) Other (manual entry)"
    echo ""
    read -p "Select timezone [1]: " tz_choice

    case "${tz_choice:-1}" in
        1) TIMEZONE="America/New_York" ;;
        2) TIMEZONE="America/Los_Angeles" ;;
        3) TIMEZONE="America/Chicago" ;;
        4) TIMEZONE="Europe/London" ;;
        5) TIMEZONE="Europe/Berlin" ;;
        6) TIMEZONE="Asia/Tokyo" ;;
        7) TIMEZONE="Australia/Sydney" ;;
        8) read -p "Enter timezone: " TIMEZONE ;;
    esac

    log_success "Configuration complete"
}

# ============================================================================
# Desktop Style Selection
# ============================================================================

select_desktop_style() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    DESKTOP STYLE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # If using config file with DESKTOP_STYLE set, skip prompt
    if [ -n "$CONFIG_FILE" ] && [ -n "$DESKTOP_STYLE" ]; then
        log_step "Using desktop style from config: $DESKTOP_STYLE"
        return
    fi

    echo -e "  ${GREEN}[D]${NC} Dock Bar ${CYAN}(macOS-style)${NC}"
    echo "      Bottom dock, auto-hide, clean top bar"
    echo ""
    echo -e "  ${BLUE}[W]${NC} Windows Bar ${CYAN}(Taskbar-style)${NC}"
    echo "      Full taskbar, app menu, system tray"
    echo ""

    read -p "Select style [D/W]: " style_choice

    case "${style_choice^^}" in
        W|WINDOWS) DESKTOP_STYLE="taskbar" ;;
        *) DESKTOP_STYLE="dock" ;;
    esac

    log_success "Desktop style: $DESKTOP_STYLE"
}

# ============================================================================
# Development Stacks Selection
# ============================================================================

select_dev_stacks() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              DEVELOPMENT STACKS (Optional)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # If using config file, skip prompt and use DEV_STACKS from config
    if [ -n "$CONFIG_FILE" ]; then
        if [ -n "$DEV_STACKS" ]; then
            log_step "Using dev stacks from config: $DEV_STACKS"
        else
            log_step "No dev stacks selected in config"
        fi
        return
    fi

    echo "Select development environments to install (space-separated numbers):"
    echo ""
    echo "  1) Tauri      - Rust + Svelte/React desktop apps"
    echo "  2) Android    - SDK + NDK + Kotlin + Gradle"
    echo "  3) Go         - Go + tools + LSP"
    echo "  4) Python     - Poetry + Ruff + Pyright"
    echo "  5) Zig        - Zig + ZLS"
    echo "  6) Web        - Node + Bun + Vite + Tailwind"
    echo "  7) Office     - LibreOffice + GIMP + VLC"
    echo "  8) Creator    - OBS + Kdenlive + Audacity"
    echo "  9) ALL        - Install everything"
    echo "  0) NONE       - Skip (can install later)"
    echo ""

    read -p "Enter choices (e.g., '1 3 6' or '9' for all) [0]: " stack_choices

    DEV_STACKS=""
    for choice in $stack_choices; do
        case "$choice" in
            1) DEV_STACKS="$DEV_STACKS tauri" ;;
            2) DEV_STACKS="$DEV_STACKS android" ;;
            3) DEV_STACKS="$DEV_STACKS go" ;;
            4) DEV_STACKS="$DEV_STACKS python" ;;
            5) DEV_STACKS="$DEV_STACKS zig" ;;
            6) DEV_STACKS="$DEV_STACKS web" ;;
            7) DEV_STACKS="$DEV_STACKS office" ;;
            8) DEV_STACKS="$DEV_STACKS creator" ;;
            9) DEV_STACKS="tauri android go python zig web office creator" ;;
            0|"") DEV_STACKS="" ;;
        esac
    done

    if [ -n "$DEV_STACKS" ]; then
        log_success "Selected stacks:$DEV_STACKS"
    else
        log_success "No development stacks selected"
    fi
}

# ============================================================================
# Partitioning
# ============================================================================

partition_disk() {
    log_step "Partitioning disk $TARGET_DISK..."

    # Determine partition naming (nvme vs sda)
    if [[ "$TARGET_DISK" == *"nvme"* ]] || [[ "$TARGET_DISK" == *"mmcblk"* ]]; then
        PART_PREFIX="${TARGET_DISK}p"
    else
        PART_PREFIX="${TARGET_DISK}"
    fi

    # Wipe existing partitions
    wipefs -a "$TARGET_DISK"

    # Create GPT partition table
    parted -s "$TARGET_DISK" mklabel gpt

    # Calculate partition boundaries
    local efi_end=$((EFI_SIZE * 1024))
    local swap_end=$((efi_end + SWAP_SIZE * 1024))
    local root_end=$((swap_end + ROOT_SIZE * 1024))

    # Create partitions
    parted -s "$TARGET_DISK" mkpart "EFI" fat32 1MiB ${efi_end}MiB
    parted -s "$TARGET_DISK" set 1 esp on
    parted -s "$TARGET_DISK" mkpart "SWAP" linux-swap ${efi_end}MiB ${swap_end}MiB
    parted -s "$TARGET_DISK" mkpart "ROOT" ext4 ${swap_end}MiB ${root_end}MiB
    parted -s "$TARGET_DISK" mkpart "HOME" ext4 ${root_end}MiB 100%

    # Wait for kernel to recognize partitions
    sleep 2
    partprobe "$TARGET_DISK"
    sleep 2

    # Set partition variables
    EFI_PART="${PART_PREFIX}1"
    SWAP_PART="${PART_PREFIX}2"
    ROOT_PART="${PART_PREFIX}3"
    HOME_PART="${PART_PREFIX}4"

    log_success "Partitions created"

    # Format partitions
    log_step "Formatting partitions..."

    mkfs.fat -F32 "$EFI_PART"
    log_success "EFI partition formatted (FAT32)"

    mkswap "$SWAP_PART"
    log_success "Swap partition formatted"

    mkfs.ext4 -F "$ROOT_PART"
    log_success "Root partition formatted (ext4)"

    mkfs.ext4 -F "$HOME_PART"
    log_success "Home partition formatted (ext4)"

    # Mount partitions
    log_step "Mounting partitions..."

    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot/efi
    mkdir -p /mnt/home
    mount "$EFI_PART" /mnt/boot/efi
    mount "$HOME_PART" /mnt/home
    swapon "$SWAP_PART"

    log_success "Partitions mounted"
}

# ============================================================================
# Base System Installation
# ============================================================================

install_base_system() {
    log_step "Installing base system (this may take a while)..."

    # Update mirrorlist for faster downloads
    log_step "Optimizing mirror list..."

    # Always prepend the official geo-load-balanced mirror (fastest, most reliable)
    local geo_mirror="Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch"

    if [ -n "$MIRROR_COUNTRY" ] && command -v reflector &> /dev/null; then
        # Use reflector to find country-specific mirrors, but prepend geo mirror
        reflector --country "$MIRROR_COUNTRY" --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || {
            log_warning "reflector failed, using fallback mirrors"
        }
        # Prepend geo mirror to the list
        sed -i "1i $geo_mirror" /etc/pacman.d/mirrorlist
    else
        # Use reliable fallback mirrors (geo-balanced + major US mirrors)
        cat > /etc/pacman.d/mirrorlist << 'MIRRORS'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.rit.edu/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.lty.me/archlinux/$repo/os/$arch
MIRRORS
    fi
    log_success "Mirror list optimized"

    # Create vconsole.conf BEFORE pacstrap to avoid mkinitcpio warnings
    mkdir -p /mnt/etc
    echo "KEYMAP=${KEYMAP}" > /mnt/etc/vconsole.conf
    log_success "vconsole.conf pre-created"

    # Install base system with download timeout disabled for slow connections
    log_step "Running pacstrap (downloading ~800MB)..."
    pacstrap -K /mnt \
        base \
        base-devel \
        linux \
        linux-firmware \
        linux-headers \
        intel-ucode \
        amd-ucode \
        networkmanager \
        grub \
        efibootmgr \
        os-prober \
        sudo \
        vim \
        nano \
        git \
        curl \
        wget \
        aria2 \
        htop \
        fastfetch \
        zsh \
        man-db \
        man-pages \
        texinfo \
        openssh \
        reflector

    log_success "Base system installed"

    # Copy optimized mirrorlist to new system
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

    # Generate fstab
    log_step "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    log_success "fstab generated"
}

# ============================================================================
# System Configuration (chroot)
# ============================================================================

configure_system() {
    log_step "Configuring system..."

    # Create configuration script to run inside chroot
    cat > /mnt/root/chroot-setup.sh << CHROOT_EOF
#!/bin/bash
set -e

# Timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
if [ "${LOCALE}" != "en_US.UTF-8" ]; then
    echo "${LOCALE} UTF-8" >> /etc/locale.gen
fi
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf

# Keymap
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Hostname
echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
HOSTS

# Root password (same as user for simplicity)
echo "root:${USER_PASSWORD}" | chpasswd

# Create user
useradd -m -G wheel,audio,video,storage,optical -s /bin/zsh ${USERNAME}
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# Sudo access
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Enable services
systemctl enable NetworkManager
systemctl enable fstrim.timer

# Install GRUB (--removable ensures compatibility with Ventoy and various UEFI implementations)
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=JesterNet --removable
grub-mkconfig -o /boot/grub/grub.cfg

# Create initial ramdisk
mkinitcpio -P

echo "Base configuration complete"
CHROOT_EOF

    chmod +x /mnt/root/chroot-setup.sh
    arch-chroot /mnt /bin/bash /root/chroot-setup.sh

    log_success "System configured"
}

# ============================================================================
# GNOME Desktop Installation
# ============================================================================

install_desktop() {
    log_step "Installing GNOME desktop environment..."

    cat > /mnt/root/install-desktop.sh << 'DESKTOP_EOF'
#!/bin/bash
set -e

# Install GNOME and essentials
pacman -S --noconfirm --needed \
    gnome \
    gnome-tweaks \
    gnome-shell-extensions \
    gdm \
    gnome-browser-connector \
    dconf-editor \
    file-roller \
    evince \
    gnome-calculator \
    gnome-calendar \
    gnome-clocks \
    gnome-font-viewer \
    gnome-logs \
    gnome-system-monitor \
    gnome-weather \
    gnome-disk-utility \
    baobab \
    loupe \
    gedit

# Audio (PipeWire)
pacman -S --noconfirm --needed \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pavucontrol

# Fonts
pacman -S --noconfirm --needed \
    ttf-dejavu \
    ttf-liberation \
    noto-fonts \
    noto-fonts-emoji \
    ttf-fira-code \
    ttf-jetbrains-mono

# Essential apps
pacman -S --noconfirm --needed \
    firefox \
    kitty \
    thunar \
    nautilus \
    gnome-terminal

# GTK Themes (Orchis)
pacman -S --noconfirm --needed \
    gtk-engine-murrine \
    sassc

# Enable GDM
systemctl enable gdm

echo "Desktop installation complete"
DESKTOP_EOF

    chmod +x /mnt/root/install-desktop.sh
    arch-chroot /mnt /bin/bash /root/install-desktop.sh

    log_success "GNOME desktop installed"
}

# ============================================================================
# JesterNet Theme Installation
# ============================================================================

install_jesternet_theme() {
    log_step "Installing JesterNet DarkGlass theme..."

    # Copy theme files to new system
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    THEME_DIR="$(dirname "$SCRIPT_DIR")"

    # Copy entire theme package
    mkdir -p /mnt/home/${USERNAME}/JesterNet
    cp -r "$THEME_DIR"/* /mnt/home/${USERNAME}/JesterNet/ 2>/dev/null || {
        log_warning "Theme files not found locally, will need manual installation"
        return
    }

    # Install DarkGlass icon theme system-wide
    if [ -d "$THEME_DIR/icons/DarkGlass" ]; then
        mkdir -p /mnt/usr/share/icons
        cp -r "$THEME_DIR/icons/DarkGlass" /mnt/usr/share/icons/
        log_success "DarkGlass icons installed"
    fi

    # Install GTK theme if present
    if [ -d "$THEME_DIR/gtk" ]; then
        mkdir -p /mnt/usr/share/themes
        cp -r "$THEME_DIR/gtk"/* /mnt/usr/share/themes/ 2>/dev/null || true
    fi

    # Install GNOME Shell theme if present
    if [ -d "$THEME_DIR/gnome-shell" ]; then
        mkdir -p /mnt/usr/share/gnome-shell/theme
        cp -r "$THEME_DIR/gnome-shell"/* /mnt/usr/share/gnome-shell/theme/ 2>/dev/null || true
    fi

    # Set up default wallpaper
    if [ -f "$THEME_DIR/config/wallpaper.jpg" ]; then
        mkdir -p /mnt/home/${USERNAME}/.config
        cp "$THEME_DIR/config/wallpaper.jpg" /mnt/home/${USERNAME}/.config/background
        log_success "Wallpaper installed"
    fi

    # Install GNOME extensions (user-level)
    mkdir -p /mnt/home/${USERNAME}/.local/share/gnome-shell/extensions

    # Copy all bundled extensions
    if [ -d "$THEME_DIR/extensions" ]; then
        cp -r "$THEME_DIR/extensions"/* /mnt/home/${USERNAME}/.local/share/gnome-shell/extensions/
        log_success "GNOME extensions installed"
    fi

    # Also copy darkglass-themer if in root (legacy location)
    if [ -d "$THEME_DIR/darkglass-themer@jesternet.com" ]; then
        cp -r "$THEME_DIR/darkglass-themer@jesternet.com" /mnt/home/${USERNAME}/.local/share/gnome-shell/extensions/
    fi

    # Create first-login setup script
    cat > /mnt/home/${USERNAME}/setup-theme.sh << 'THEME_EOF'
#!/bin/bash
# JesterNet Theme Setup - Run after first login

echo "Setting up JesterNet DarkGlass theme..."

# Install Orchis GTK theme from AUR (if yay is installed)
if command -v yay &> /dev/null; then
    yay -S --noconfirm orchis-theme 2>/dev/null || true
fi

# Install GNOME extensions from AUR
if command -v yay &> /dev/null; then
    yay -S --noconfirm --needed \
        gnome-shell-extension-dash-to-dock \
        gnome-shell-extension-blur-my-shell \
        gnome-shell-extension-just-perfection-desktop \
        2>/dev/null || true
fi

# Apply GNOME settings
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'DarkGlass' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.config/background"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.config/background"

# Enable all installed extensions
echo "Enabling extensions..."
for ext_dir in ~/.local/share/gnome-shell/extensions/*/; do
    ext_name=$(basename "$ext_dir")
    gnome-extensions enable "$ext_name" 2>/dev/null && echo "  ✓ $ext_name" || true
done

# Also enable system extensions
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true

echo ""
echo "Theme setup complete!"
echo "Please log out and back in for all changes to take effect."
THEME_EOF

    chmod +x /mnt/home/${USERNAME}/setup-theme.sh
    arch-chroot /mnt chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/JesterNet
    arch-chroot /mnt chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.local
    arch-chroot /mnt chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config
    arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/setup-theme.sh

    # Create autostart entry for first login (runs setup-theme.sh once then disables itself)
    mkdir -p /mnt/home/${USERNAME}/.config/autostart
    cat > /mnt/home/${USERNAME}/.config/autostart/jesternet-first-login.desktop << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Name=JesterNet First Login Setup
Comment=Sets up JesterNet theme on first login
Exec=/bin/bash -c 'if [ -f "$HOME/setup-theme.sh" ]; then gnome-terminal -- bash -c "$HOME/setup-theme.sh; echo Press Enter to close; read"; rm -f "$HOME/.config/autostart/jesternet-first-login.desktop"; fi'
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
AUTOSTART_EOF

    arch-chroot /mnt chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config/autostart

    log_success "JesterNet theme files installed (will auto-setup on first login)"
}

# ============================================================================
# Development Stacks Installation
# ============================================================================

install_dev_stacks() {
    if [ -z "$DEV_STACKS" ]; then
        return
    fi

    log_step "Installing development stacks..."

    # Create installation script
    cat > /mnt/home/${USERNAME}/install-dev-stacks.sh << STACKS_EOF
#!/bin/bash
# Run this after first login to install development stacks
cd ~/JesterNet

STACKS_EOF

    for stack in $DEV_STACKS; do
        case "$stack" in
            tauri)   echo "./dev-stacks/tauri-stack.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
            android) echo "./dev-stacks/android-stack.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
            go)      echo "./dev-stacks/go-stack.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
            python)  echo "./dev-stacks/python-stack.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
            zig)     echo "./dev-stacks/zig-stack.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
            web)     echo "./dev-stacks/web-stack.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
            office)  echo "./dev-stacks/office-multimedia.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
            creator) echo "./dev-stacks/content-creator.sh" >> /mnt/home/${USERNAME}/install-dev-stacks.sh ;;
        esac
    done

    chmod +x /mnt/home/${USERNAME}/install-dev-stacks.sh
    arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/install-dev-stacks.sh

    log_success "Development stack installer created"
}

# ============================================================================
# Enterprise Configuration
# ============================================================================

configure_enterprise() {
    log_step "Applying enterprise configuration..."

    # Static IP configuration
    if [ -n "$STATIC_IP" ] && [ -n "$GATEWAY" ]; then
        log_step "Configuring static IP: $STATIC_IP"

        # Get the primary network interface
        local iface=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(en|eth)' | head -1)

        cat > /mnt/etc/NetworkManager/system-connections/static.nmconnection << NMEOF
[connection]
id=static
type=ethernet
interface-name=${iface}
autoconnect=true

[ipv4]
method=manual
addresses=${STATIC_IP}
gateway=${GATEWAY}
dns=${DNS_SERVERS:-8.8.8.8;8.8.4.4}

[ipv6]
method=auto
NMEOF
        chmod 600 /mnt/etc/NetworkManager/system-connections/static.nmconnection
        log_success "Static IP configured"
    fi

    # Proxy configuration
    if [ -n "$HTTP_PROXY" ]; then
        log_step "Configuring proxy..."
        cat >> /mnt/etc/environment << PROXYEOF
http_proxy=${HTTP_PROXY}
https_proxy=${HTTPS_PROXY:-$HTTP_PROXY}
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY:-$HTTP_PROXY}
no_proxy=localhost,127.0.0.1,::1
PROXYEOF
        log_success "Proxy configured"
    fi

    # SSH configuration
    if [ "$SSH_ENABLED" = "true" ]; then
        log_step "Enabling SSH server..."
        arch-chroot /mnt systemctl enable sshd

        # Inject authorized keys if provided
        if [ -n "$SSH_AUTHORIZED_KEYS" ] && [ -f "$SSH_AUTHORIZED_KEYS" ]; then
            mkdir -p /mnt/home/${USERNAME}/.ssh
            cp "$SSH_AUTHORIZED_KEYS" /mnt/home/${USERNAME}/.ssh/authorized_keys
            chmod 700 /mnt/home/${USERNAME}/.ssh
            chmod 600 /mnt/home/${USERNAME}/.ssh/authorized_keys
            arch-chroot /mnt chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh
            log_success "SSH authorized keys injected"
        fi
        log_success "SSH server enabled"
    fi

    # Domain join preparation (AD/LDAP)
    if [ "$DOMAIN_JOIN_PREP" = "true" ]; then
        log_step "Installing domain join packages..."
        arch-chroot /mnt pacman -S --noconfirm --needed \
            sssd \
            realmd \
            krb5 \
            samba \
            oddjob \
            oddjob-mkhomedir \
            adcli \
            openldap-clients

        # Pre-configure realm if provided
        if [ -n "$DOMAIN_REALM" ]; then
            cat > /mnt/etc/krb5.conf.d/domain.conf << KRBEOF
[realms]
${DOMAIN_REALM} = {
    kdc = ${DOMAIN_REALM,,}
    admin_server = ${DOMAIN_REALM,,}
}

[domain_realm]
.${DOMAIN_REALM,,} = ${DOMAIN_REALM}
${DOMAIN_REALM,,} = ${DOMAIN_REALM}
KRBEOF
        fi
        log_success "Domain join packages installed"
    fi

    # Run post-install hook if provided
    if [ -n "$POST_INSTALL_HOOK" ] && [ -f "$POST_INSTALL_HOOK" ]; then
        log_step "Running post-install hook..."
        cp "$POST_INSTALL_HOOK" /mnt/root/post-install-hook.sh
        chmod +x /mnt/root/post-install-hook.sh
        arch-chroot /mnt /bin/bash /root/post-install-hook.sh
        rm -f /mnt/root/post-install-hook.sh
        log_success "Post-install hook completed"
    fi

    log_success "Enterprise configuration applied"
}

# ============================================================================
# AUR Helper Installation
# ============================================================================

install_aur_helper() {
    log_step "Installing yay (AUR helper)..."

    # yay must be built as a regular user, so create a first-boot script
    cat > /mnt/home/${USERNAME}/install-yay.sh << 'YAY_USER_EOF'
#!/bin/bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay
echo "yay installed successfully!"
YAY_USER_EOF

    chmod +x /mnt/home/${USERNAME}/install-yay.sh
    arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/install-yay.sh

    log_success "AUR helper installer created"
}

# ============================================================================
# Final Cleanup
# ============================================================================

cleanup() {
    log_step "Cleaning up..."

    # Remove temporary scripts
    rm -f /mnt/root/chroot-setup.sh
    rm -f /mnt/root/install-desktop.sh

    # Create first-boot instruction file
    cat > /mnt/home/${USERNAME}/FIRST_BOOT_README.txt << README_EOF
╔══════════════════════════════════════════════════════════════════════════╗
║                    WELCOME TO JESTERNET OS                               ║
╚══════════════════════════════════════════════════════════════════════════╝

Congratulations! Your JesterNet OS installation is complete.

After logging in, run these commands to complete your setup:

1. Install yay (AUR helper):
   ./install-yay.sh

2. Apply the JesterNet theme:
   ./setup-theme.sh

3. Install development stacks (optional):
   ./install-dev-stacks.sh

4. Reboot to apply all changes:
   reboot

Enjoy your new system!

─────────────────────────────────────────────────────────────────────────────
The Doctrine of Sovereign Artifacts is fulfilled.
README_EOF

    arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/FIRST_BOOT_README.txt

    # Unmount
    log_step "Unmounting partitions..."
    umount -R /mnt
    swapoff -a

    log_success "Installation complete!"
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}            INSTALLATION COMPLETE!${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Hostname:      $HOSTNAME"
    echo "  Username:      $USERNAME"
    echo "  Timezone:      $TIMEZONE"
    echo "  Desktop:       $DESKTOP_STYLE style"
    echo "  Dev Stacks:    ${DEV_STACKS:-none}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Remove the installation media"
    echo "  2. Reboot: ${GREEN}reboot${NC}"
    echo "  3. Log in as $USERNAME"
    echo "  4. Run: ${GREEN}./setup-theme.sh${NC}"
    echo ""
    echo -e "${YELLOW}Read ~/FIRST_BOOT_README.txt for complete instructions${NC}"
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_banner
    preflight_checks
    select_disk
    configure_user
    select_desktop_style
    select_dev_stacks

    # Confirmation
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    INSTALLATION SUMMARY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Target Disk:   $TARGET_DISK"
    echo "  Hostname:      $HOSTNAME"
    echo "  Username:      $USERNAME"
    echo "  Timezone:      $TIMEZONE"
    echo "  Desktop:       $DESKTOP_STYLE"
    echo "  Dev Stacks:    ${DEV_STACKS:-none}"
    echo ""
    echo -e "${RED}WARNING: This will ERASE ALL DATA on $TARGET_DISK${NC}"
    echo ""

    # Auto-confirm if using config file, otherwise prompt
    if [ -n "$CONFIG_FILE" ]; then
        log_step "Auto-confirming installation from config file..."
        sleep 2
    else
        read -p "Begin installation? [y/N]: " final_confirm
        if [[ ! "$final_confirm" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            exit 0
        fi
    fi

    # Run installation
    partition_disk
    install_base_system
    configure_system
    install_desktop
    install_jesternet_theme
    install_dev_stacks
    configure_enterprise
    install_aur_helper
    cleanup
    print_summary
}

# ============================================================================
# Entry Point
# ============================================================================

# Check for config file argument
if [ -n "$1" ] && [ -f "$1" ]; then
    CONFIG_FILE="$1"
    log_step "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
fi

main
