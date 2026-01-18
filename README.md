# JesterNet OS

```
       ▄▄▄██▀▀▀▓█████   ██████ ▄▄▄█████▓▓█████  ██▀███   ███▄    █ ▓█████▄▄▄█████▓
         ▒██   ▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒▓█   ▀ ▓██ ▒ ██▒ ██ ▀█   █ ▓█   ▀▓  ██▒ ▓▒
         ░██   ▒███   ░ ▓██▄   ▒ ▓██░ ▒░▒███   ▓██ ░▄█ ▒▓██  ▀█ ██▒▒███  ▒ ▓██░ ▒░
      ▓██▄██▓  ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ ▒▓█  ▄ ▒██▀▀█▄  ▓██▒  ▐▌██▒▒▓█  ▄░ ▓██▓ ░
       ▓███▒   ░▒████▒▒██████▒▒  ▒██▒ ░ ░▒████▒░██▓ ▒██▒▒██░   ▓██░░▒████▒ ▒██▒ ░
       ▒▓▒▒░   ░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   ░░ ▒░ ░░ ▒▓ ░▒▓░░ ▒░   ▒ ▒ ░░ ▒░ ░ ▒ ░░
```

**A Futuristic Glassmorphic Desktop for Arch Linux**

Welcome to JesterNet OS - a complete desktop transformation for users migrating from Windows or macOS to Arch Linux. This package includes a stunning glassmorphic theme, pre-configured desktop layouts, and one-click installers for development environments.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Desktop Styles](#desktop-styles)
- [Theme Components](#theme-components)
- [Development Stacks](#development-stacks)
- [For Windows Users](#for-windows-users)
- [For macOS Users](#for-macos-users)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## Features

### Glassmorphic Theme
- Frosted glass transparency effects
- Cyan/Magenta cyberpunk color palette
- Custom icons for 40+ applications
- Programming language file-type icons (23 SVG icons)
- GTK3/GTK4 theme integration

### Desktop Layouts
Choose your preferred workflow:

| Style | Description | Best For |
|-------|-------------|----------|
| **Dock Bar** (macOS-style) | Bottom dock with app icons, no taskbar | Users from macOS, clean aesthetic lovers |
| **Start Bar** (Windows-style) | Bottom taskbar with app menu, system tray | Users from Windows, traditional workflow |

### Development Stacks
One-click installation for complete development environments:
- **Tauri** - Rust + Svelte/React desktop apps
- **Android** - Full Android SDK/NDK setup
- **Go** - Go with LSP, linters, and tools
- **Python** - Poetry, Ruff, Pyright
- **Zig** - Zig with ZLS
- **Web** - Node, Bun, Vite, Tailwind

### Productivity Suites
- **Office + Multimedia** - LibreOffice, GIMP, Inkscape, VLC
- **Content Creator** - OBS Studio, Kdenlive, Audacity

---

## Requirements

- **Arch Linux** (or Arch-based: EndeavourOS, Manjaro)
- **GNOME Desktop** (45+)
- **8GB+ RAM** recommended
- **Internet connection** for package downloads

### Required GNOME Extensions
The installer will guide you, but you'll need:
- [Blur My Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)
- [Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/) (for Dock style)
- [Dash to Panel](https://extensions.gnome.org/extension/1160/dash-to-panel/) (for Windows style)
- [User Themes](https://extensions.gnome.org/extension/19/user-themes/)

---

## Quick Start

### 1. Clone or Download

```bash
git clone https://github.com/yourusername/jesternet-os.git
cd jesternet-os
```

Or download and extract the ZIP.

### 2. Run the Installer

```bash
./jesternet-setup.sh
```

This opens an interactive menu where you can:
- Install the DarkGlass theme
- Choose your desktop style (Dock or Taskbar)
- Install development environments
- Install productivity software

### 3. Choose Your Desktop Style

When prompted, select:
- **[D] Dock Bar** - macOS-style bottom dock
- **[W] Windows Bar** - Windows-style taskbar with start menu

### 4. Log Out and Back In

For all changes to take effect, log out of your session and log back in.

---

## Desktop Styles

### Dock Bar (macOS Style)

```
┌─────────────────────────────────────────────────────────────────┐
│  Activities                              🔊 🔋 📶  Mon 12:00    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                                                                 │
│                        Your Desktop                             │
│                                                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│         🦊  📁  💻  🎵  ⚙️   |   📌 Running Apps   |   🗑️       │
│                         ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔                       │
└─────────────────────────────────────────────────────────────────┘
```

**Features:**
- Centered dock at bottom
- Hover to reveal
- App icons with indicators for running apps
- Trash icon on the right
- Clean, minimal top bar

**Best for:** macOS users, those who prefer a clean desktop

### Windows Bar (Taskbar Style)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│                        Your Desktop                             │
│                                                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│ ⬡ Apps │ 🦊 Firefox │ 📁 Files │ 💻 Terminal │    🔊 🔋 12:00  │
└─────────────────────────────────────────────────────────────────┘
```

**Features:**
- Full-width bottom taskbar
- App menu button (like Start menu)
- Window list showing open applications
- System tray with clock
- Familiar Windows workflow

**Best for:** Windows users, those who prefer taskbar workflow

---

## Theme Components

### DarkGlass Theme

The glassmorphic theme includes:

| Component | Description |
|-----------|-------------|
| **Icons** | 40+ custom app icons + 23 file-type icons |
| **GTK Theme** | Frosted glass window decorations |
| **Shell Theme** | Transparent top bar and overview |
| **Blur Effects** | Real-time blur behind windows |

### Color Palette

```
Primary:    #00FFFF (Cyan)
Accent:     #FF00FF (Magenta)
Background: #0a0a0f (Deep Black)
Glass:      rgba(20, 20, 30, 0.7)
```

### Included Icons

**Applications:**
Firefox, Brave, VS Code, Ghostty, OBS Studio, Steam, Inkscape,
GIMP, Calculator, Calendar, System Monitor, and 30+ more

**File Types:**
Python, Rust, Go, Zig, TypeScript, JavaScript, C, C++, C#,
Swift, Julia, Mojo, Docker, YAML, JSON, Markdown, and more

---

## Development Stacks

### Tauri Stack
Build cross-platform desktop apps with web technologies.

```bash
./jesternet-setup.sh tauri
```

**Installs:**
- Rust + Cargo
- Node.js + pnpm + Bun
- Tauri CLI
- WebKit/GTK dependencies

**Quick Start:**
```bash
new-tauri-app my-app          # Creates Svelte + Tauri app
new-tauri-app my-app react    # Creates React + Tauri app
cd my-app && pnpm tauri dev
```

### Android Stack
Full Android development environment.

```bash
./jesternet-setup.sh android
```

**Installs:**
- Java JDK 17
- Android SDK + NDK
- Kotlin + Gradle
- ADB + Fastboot
- Emulator

**Quick Start:**
```bash
adb devices                   # List connected devices
avdmanager create avd ...     # Create emulator
```

### Go Stack
Modern Go development setup.

```bash
./jesternet-setup.sh go
```

**Installs:**
- Go (latest)
- gopls (language server)
- delve (debugger)
- golangci-lint
- air (live reload)

**Quick Start:**
```bash
new-go-project my-app         # Creates Go CLI app
new-go-project my-api api     # Creates Go API server
cd my-app && task run
```

### Python Stack
Python with modern tooling.

```bash
./jesternet-setup.sh python
```

**Installs:**
- Python 3 + pip + pipx
- Poetry (dependency management)
- Ruff (fast linter/formatter)
- Pyright (type checker)
- pyenv (version management)

**Quick Start:**
```bash
new-python-project my-app
cd my-app && poetry shell
```

### Web Frontend Stack
Modern frontend development.

```bash
./jesternet-setup.sh web
```

**Installs:**
- Node.js + npm
- Bun (fast runtime)
- pnpm (fast package manager)
- Vite, TypeScript, ESLint, Prettier
- Tailwind CSS CLI

**Quick Start:**
```bash
new-svelte-app my-app         # SvelteKit + Tailwind
new-react-app my-app          # React + Vite + Tailwind
new-vue-app my-app            # Vue + Vite + Tailwind
```

---

## For Windows Users

Welcome to Linux! Here's what you need to know:

### Familiar Concepts

| Windows | Linux Equivalent |
|---------|-----------------|
| C:\\ drive | `/` (root) |
| C:\\Users\\You | `/home/you` or `~` |
| Program Files | `/usr/bin` or installed via `pacman` |
| Control Panel | Settings app or `gnome-control-center` |
| Task Manager | System Monitor or `htop` |
| CMD/PowerShell | Terminal (Ghostty, Konsole) |
| .exe files | No extension needed, or AppImages |
| Windows Update | `sudo pacman -Syu` |

### Installing Software

Forget downloading .exe files! Use the package manager:

```bash
# Search for software
pacman -Ss firefox

# Install software
sudo pacman -S firefox

# Update everything
sudo pacman -Syu

# Remove software
sudo pacman -R firefox
```

### Keyboard Shortcuts

| Action | Windows | JesterNet |
|--------|---------|-----------|
| Open terminal | - | `Super + T` or click icon |
| Show all apps | `Win` | `Super` (tap) |
| Switch windows | `Alt + Tab` | `Alt + Tab` |
| Close window | `Alt + F4` | `Alt + F4` |
| File manager | `Win + E` | `Super + E` or click icon |
| Lock screen | `Win + L` | `Super + L` |

### Recommended: Windows-Style Taskbar

If you're coming from Windows, choose the **Windows Bar** style during setup. It gives you:
- Familiar taskbar at the bottom
- App menu like the Start button
- System tray with clock
- Window buttons for each open app

---

## For macOS Users

The default **Dock Bar** style will feel familiar:

### Familiar Concepts

| macOS | Linux Equivalent |
|-------|-----------------|
| Finder | Files (Nautilus) |
| Spotlight | `Super` key to search |
| Terminal | Ghostty/Konsole |
| Homebrew | `pacman` |
| .app bundles | Native packages or Flatpaks |
| System Preferences | Settings |

### The Dock

Just like macOS:
- Click icons to launch apps
- Running apps show indicator dots
- Drag to reorder
- Right-click for options

---

## Customization

### Changing Desktop Style Later

Already installed but want to switch styles?

**Switch to Dock (macOS) style:**
```bash
gnome-extensions disable dash-to-panel@jderose9.github.com
gnome-extensions enable dash-to-dock@micxgx.gmail.com
```

**Switch to Taskbar (Windows) style:**
```bash
gnome-extensions disable dash-to-dock@micxgx.gmail.com
gnome-extensions enable dash-to-panel@jderose9.github.com
```

### Adjusting Transparency

Use the DarkGlass Theme Editor extension (color wheel in top bar) to adjust:
- Blur intensity
- Window transparency
- Glass brightness

### Adding More Icons

Place custom icons in:
```
~/.local/share/icons/DarkGlass/apps/scalable/
```

Then refresh:
```bash
gtk-update-icon-cache -f ~/.local/share/icons/DarkGlass/
```

---

## Troubleshooting

### Theme Not Applying

1. Make sure GNOME Extensions are enabled:
   ```bash
   gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
   ```

2. Log out and back in

3. Use GNOME Tweaks to select the theme manually

### Blur Not Working

Install and enable Blur My Shell:
```bash
# From extensions.gnome.org or:
gnome-extensions enable blur-my-shell@aunetx
```

### Icons Not Showing

Rebuild the icon cache:
```bash
gtk-update-icon-cache -f -t ~/.local/share/icons/DarkGlass/
```

### Dock/Taskbar Not Appearing

Make sure the correct extension is enabled:
```bash
# For Dock style:
gnome-extensions enable dash-to-dock@micxgx.gmail.com

# For Windows style:
gnome-extensions enable dash-to-panel@jderose9.github.com
```

### Downloads Are Slow

The installers use aria2 with 16 connections. If downloads fail:
```bash
# Check aria2 is installed
which aria2c

# If not, install it
sudo pacman -S aria2
```

---

## File Structure

```
JesterNet-OS/
├── jesternet-setup.sh        # Main installer (interactive menu)
├── install.sh                # Theme installer
├── optimize-icons.sh         # Compress PNG icons
├── README.md                 # This file
│
├── config/                   # GNOME/Extension configs
│   ├── blur-my-shell.conf
│   └── desktop-interface.conf
│
├── dev-stacks/               # Development environment installers
│   ├── common.sh             # Shared functions (aria2 setup)
│   ├── tauri-stack.sh
│   ├── android-stack.sh
│   ├── go-stack.sh
│   ├── python-stack.sh
│   ├── zig-stack.sh
│   ├── web-stack.sh
│   ├── office-multimedia.sh
│   └── content-creator.sh
│
├── icons/DarkGlass/          # Icon theme
│   ├── apps/                 # Application icons
│   ├── mimetypes/            # File type icons
│   └── places/               # Folder icons
│
├── gtk/                      # GTK theme CSS
├── gnome-shell/              # Shell theme CSS
└── darkglass-themer@.../     # Theme editor extension
```

---

## Credits

Created for the Arch Linux community.

**The Doctrine of Sovereign Artifacts is fulfilled.**

---

## License

MIT License - Free to use, modify, and distribute.

---

## Support

- Issues: [GitHub Issues](https://github.com/yourusername/jesternet-os/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/jesternet-os/discussions)

---

```
    "The future is already here — it's just not evenly distributed."
                                                    - William Gibson
```
