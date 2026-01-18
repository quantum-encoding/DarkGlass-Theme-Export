import GObject from 'gi://GObject';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Slider} from 'resource:///org/gnome/shell/ui/slider.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const DarkGlassIndicator = GObject.registerClass(
class DarkGlassIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'DarkGlass Themer', false);

        let icon = new St.Icon({
            icon_name: 'preferences-color-symbolic',
            style_class: 'system-status-icon',
        });
        this.add_child(icon);

        this._settings = new Gio.Settings({
            schema: 'org.gnome.shell.extensions.blur-my-shell.applications'
        });

        this._colorConfig = this._loadColorConfig();
        this._currentTab = 'effects';
        this._buildMenu();
    }

    _loadColorConfig() {
        return {
            'menu_bg': '#0a0a0f', 'menu_bg_alpha': 165,
            'menu_hover': '#ffffff', 'menu_hover_alpha': 13,
            'menu_active': '#3584e4', 'menu_active_alpha': 77,
            'accent_cyan': '#00ffff', 'accent_magenta': '#ff00ff',
            'window_bg': '#0a0a0f', 'window_bg_alpha': 165,
            'sidebar_bg': '#0a0a0f', 'sidebar_bg_alpha': 165,
            'text_primary': '#ffffff', 'text_secondary': '#cccccc'
        };
    }

    _buildMenu() {
        let tabBox = new St.BoxLayout({
            vertical: false,
            style: 'spacing: 4px; padding: 8px; background-color: rgba(0,0,0,0.3);'
        });

        ['effects', 'colors', 'presets'].forEach(tab => {
            let button = new St.Button({
                label: tab === 'effects' ? '🌀 Effects' : tab === 'colors' ? '🎨 Colors' : '⚡ Presets',
                style: 'background-color: rgba(255,255,255,0.05); border-radius: 8px; padding: 8px 12px;'
            });
            button.connect('clicked', () => this._switchTab(tab));
            tabBox.add_child(button);
        });

        let tabItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        tabItem.add_child(tabBox);
        this.menu.addMenuItem(tabItem);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        this._contentBox = new St.BoxLayout({vertical: true});
        let contentItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        contentItem.add_child(this._contentBox);
        this.menu.addMenuItem(contentItem);

        this._switchTab('effects');
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        this._addButton('💾 Save Theme', () => this._saveTheme());
        this._addButton('🔄 Reset All', () => this._resetAll());
    }

    _switchTab(tabId) {
        this._currentTab = tabId;
        this._contentBox.destroy_all_children();

        if (tabId === 'effects') this._buildEffectsTab();
        else if (tabId === 'colors') this._buildColorsTab();
        else this._buildPresetsTab();
    }

    _buildEffectsTab() {
        this._addSlider('Blur', 0, 100, this._settings.get_int('sigma'),
            v => this._settings.set_int('sigma', v));
        this._addSlider('Transparency', 0, 255, this._settings.get_int('opacity'),
            v => this._settings.set_int('opacity', v));
        this._addSlider('Brightness', 0, 100,
            Math.round(this._settings.get_double('brightness') * 100),
            v => this._settings.set_double('brightness', v / 100));
    }

    _buildColorsTab() {
        let scroll = new St.ScrollView({style: 'max-height: 350px;'});
        let box = new St.BoxLayout({vertical: true, style: 'spacing: 4px;'});

        [
            ['Menu Background', 'menu_bg', true],
            ['Menu Hover', 'menu_hover', true],
            ['Menu Active', 'menu_active', true],
            ['Cyan Accent', 'accent_cyan', false],
            ['Magenta Accent', 'accent_magenta', false],
            ['Window BG', 'window_bg', true],
            ['Sidebar BG', 'sidebar_bg', true]
        ].forEach(([label, id, alpha]) => this._addColor(box, label, id, alpha));

        scroll.add_actor(box);
        this._contentBox.add_child(scroll);
    }

    _addColor(container, label, id, hasAlpha) {
        let row = new St.BoxLayout({style: 'spacing: 8px; padding: 4px;'});
        
        row.add_child(new St.Label({text: label, style: 'min-width: 100px; font-size: 11px;'}));

        let hex = this._colorConfig[id];
        let btn = new St.Button({
            style: `background: ${hex}; width: 30px; height: 20px; border-radius: 4px;`
        });
        btn.connect('clicked', () => {
            let colors = ['#0a0a0f', '#1a1a2e', '#00ffff', '#ff00ff', '#3584e4', '#ffffff'];
            let i = (colors.indexOf(hex) + 1) % colors.length;
            this._colorConfig[id] = colors[i];
            btn.style = `background: ${colors[i]}; width: 30px; height: 20px; border-radius: 4px;`;
        });
        row.add_child(btn);

        if (hasAlpha) {
            let alpha = this._colorConfig[id + '_alpha'];
            let slider = new Slider(alpha / 255);
            slider.set_width(60);
            slider.connect('notify::value', () => {
                this._colorConfig[id + '_alpha'] = Math.round(slider.value * 255);
            });
            row.add_child(slider);
        }

        container.add_child(row);
    }

    _buildPresetsTab() {
        [
            ['Subtle Glass', {sigma: 20, opacity: 200, brightness: 0.7}],
            ['Dark Glass', {sigma: 30, opacity: 150, brightness: 0.6}],
            ['Deep Glass', {sigma: 40, opacity: 100, brightness: 0.5}],
            ['Crystal', {sigma: 50, opacity: 80, brightness: 0.4}]
        ].forEach(([name, cfg]) => {
            let btn = new St.Button({
                label: name,
                style: 'padding: 10px; background: rgba(255,255,255,0.05); border-radius: 8px; margin: 2px;',
                x_expand: true
            });
            btn.connect('clicked', () => {
                this._settings.set_int('sigma', cfg.sigma);
                this._settings.set_int('opacity', cfg.opacity);
                this._settings.set_double('brightness', cfg.brightness);
                Main.notify('DarkGlass', `✓ ${name}`);
            });
            this._contentBox.add_child(btn);
        });
    }

    _addSlider(label, min, max, initial, callback) {
        let box = new St.BoxLayout({style: 'spacing: 10px; padding: 6px;'});
        box.add_child(new St.Label({text: label, style: 'min-width: 100px;'}));

        let slider = new Slider(initial / max);
        slider.set_width(120);

        let valLabel = new St.Label({text: initial.toString(), style: 'min-width: 30px;'});
        box.add_child(valLabel);

        slider.connect('notify::value', () => {
            let v = Math.round(slider.value * max);
            valLabel.text = v.toString();
            callback(v);
        });

        box.add_child(slider);
        this._contentBox.add_child(box);
    }

    _addButton(label, callback) {
        let item = new PopupMenu.PopupMenuItem(label);
        item.connect('activate', callback);
        this.menu.addMenuItem(item);
    }

    _saveTheme() {
        let css = this._generateCss();
        let gtk3 = GLib.get_home_dir() + '/.config/gtk-3.0/gtk.css';
        let gtk4 = GLib.get_home_dir() + '/.config/gtk-4.0/gtk.css';
        try {
            GLib.file_set_contents(gtk3, css);
            GLib.file_set_contents(gtk4, css);
            Main.notify('DarkGlass', '✓ Saved! Restart apps to apply');
        } catch(e) {
            Main.notify('Error', e.message);
        }
    }

    _generateCss() {
        let c = this._colorConfig;
        let rgb = (hex) => {
            let r = parseInt(hex.slice(1,3), 16);
            let g = parseInt(hex.slice(3,5), 16);
            let b = parseInt(hex.slice(5,7), 16);
            return `${r}, ${g}, ${b}`;
        };

        return `/* DarkGlass - Auto-generated */

/* Nautilus */
.nautilus-window .sidebar,
placessidebar {
    background-color: rgba(${rgb(c.sidebar_bg)}, ${c.sidebar_bg_alpha / 255});
}

.nautilus-window scrolledwindow,
.nautilus-window .view {
    background-color: rgba(${rgb(c.window_bg)}, ${c.window_bg_alpha / 255});
}

.nautilus-window .sidebar row:hover {
    background-color: rgba(${rgb(c.menu_hover)}, ${c.menu_hover_alpha / 255});
}

.nautilus-window .sidebar row:selected {
    background-color: rgba(${rgb(c.menu_active)}, ${c.menu_active_alpha / 255});
}

/* Context Menus */
.popup-menu, menu {
    background-color: rgba(${rgb(c.menu_bg)}, ${c.menu_bg_alpha / 255});
}

.popup-menu-item:hover, menuitem:hover {
    background-color: rgba(${rgb(c.menu_hover)}, ${c.menu_hover_alpha / 255});
}
`;
    }

    _resetAll() {
        this._settings.set_int('sigma', 30);
        this._settings.set_int('opacity', 150);
        this._settings.set_double('brightness', 0.6);
        this._colorConfig = this._loadColorConfig();
        this._saveTheme();
        Main.notify('DarkGlass', '✓ Reset complete');
    }

    destroy() {
        super.destroy();
    }
});

export default class DarkGlassThemerExtension extends Extension {
    enable() {
        this._indicator = new DarkGlassIndicator();
        Main.panel.addToStatusArea('darkglass-themer', this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
