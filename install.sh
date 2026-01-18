#!/bin/bash
# DarkGlass Theme Installation Script

echo "🎨 DarkGlass Theme Installer"
echo "================================"
echo ""

# Check for required tools
if ! command -v gnome-shell &> /dev/null; then
    echo "❌ Error: GNOME Shell not found. This theme requires GNOME."
    exit 1
fi

echo "📦 Installing DarkGlass Theme..."
echo ""

# 1. Install Icons
echo "🎨 Installing custom icons..."
mkdir -p ~/.local/share/icons
cp -r icons/DarkGlass ~/.local/share/icons/
gtk-update-icon-cache -f -t ~/.local/share/icons/DarkGlass/ 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme 'DarkGlass'
echo "   ✓ Icons installed"

# 2. Install GTK Themes
echo "🎨 Installing GTK themes..."
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cp gtk/gtk-3.0.css ~/.config/gtk-3.0/gtk.css
cp gtk/gtk-4.0.css ~/.config/gtk-4.0/gtk.css
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
echo "   ✓ GTK themes installed"

# 3. Install GNOME Shell Theme
echo "🎨 Installing GNOME Shell theme..."
mkdir -p ~/.themes/DarkGlass/gnome-shell
cp gnome-shell/gnome-shell.css ~/.themes/DarkGlass/gnome-shell/
dconf write /org/gnome/shell/extensions/user-theme/name "'DarkGlass'"
echo "   ✓ Shell theme installed"

# 4. Apply Blur Settings
echo "🌀 Configuring blur effects..."
if [ -f config/blur-my-shell.conf ]; then
    dconf load /org/gnome/shell/extensions/blur-my-shell/ < config/blur-my-shell.conf 2>/dev/null
    echo "   ✓ Blur settings applied"
else
    echo "   ⚠️  Blur config not found, skipping..."
fi

# 5. Apply Desktop Settings
echo "⚙️  Applying desktop configuration..."
if [ -f config/desktop-interface.conf ]; then
    dconf load /org/gnome/desktop/interface/ < config/desktop-interface.conf 2>/dev/null
    echo "   ✓ Desktop settings applied"
fi

# 6. Install Theme Editor Extension
echo "🔧 Installing DarkGlass Theme Editor extension..."
EXTENSION_DIR=~/.local/share/gnome-shell/extensions/darkglass-themer@jesternet.com

if [ -d "$(dirname "$0")/../.local/share/gnome-shell/extensions/darkglass-themer@jesternet.com" ]; then
    cp -r "$(dirname "$0")/../.local/share/gnome-shell/extensions/darkglass-themer@jesternet.com" ~/.local/share/gnome-shell/extensions/
    gnome-extensions enable darkglass-themer@jesternet.com 2>/dev/null
    echo "   ✓ Theme editor installed (look for color wheel in top bar)"
else
    echo "   ⚠️  Extension not found, install manually if needed"
fi

echo ""
echo "================================"
echo "✨ DarkGlass Theme Installation Complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Log out and log back in (or press Alt+F2, type 'r', press Enter on X11)"
echo "   2. Look for the color wheel icon in your top bar to customize"
echo "   3. Enjoy your cyberpunk dark glass aesthetic!"
echo ""
echo "🔧 Customization:"
echo "   - Click the color wheel icon in top bar for live editing"
echo "   - Adjust blur, transparency, and brightness with sliders"
echo "   - Try quick presets for different looks"
echo ""
echo "📖 Documentation: See README.md for manual configuration"
echo ""
