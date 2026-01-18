import GObject from 'gi://GObject';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Slider} from 'resource:///org/gnome/shell/ui/slider.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const DarkGlassIndicator = GObject.registerClass(
class DarkGlassIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'DarkGlass Themer', false);

        // Top bar icon
        let icon = new St.Icon({
            icon_name: 'preferences-color-symbolic',
            style_class: 'system-status-icon',
        });
        this.add_child(icon);

        // Settings
        this._settings = new Gio.Settings({
            schema: 'org.gnome.shell.extensions.blur-my-shell.applications'
        });

        // Build menu
        this._buildMenu();
    }

    _buildMenu() {
        // Header
        let header = new PopupMenu.PopupMenuItem('🎨 DarkGlass Theme Editor', {
            reactive: false,
            can_focus: false
        });
        header.label.style = 'font-weight: bold;';
        this.menu.addMenuItem(header);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Blur Intensity Slider
        this._addSlider('Blur Intensity', 0, 100,
            this._settings.get_int('sigma'),
            (value) => {
                this._settings.set_int('sigma', value);
                Main.notify('DarkGlass', `Blur: ${value}`);
            }
        );

        // Transparency Slider
        this._addSlider('Transparency', 0, 255,
            this._settings.get_int('opacity'),
            (value) => {
                this._settings.set_int('opacity', value);
                Main.notify('DarkGlass', `Transparency: ${value}`);
            }
        );

        // Brightness Slider
        this._addSlider('Brightness', 0, 100,
            Math.round(this._settings.get_double('brightness') * 100),
            (value) => {
                this._settings.set_double('brightness', value / 100);
                Main.notify('DarkGlass', `Brightness: ${value}%`);
            }
        );

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Quick presets
        let presetsHeader = new PopupMenu.PopupMenuItem('⚡ Quick Presets', {
            reactive: false,
            can_focus: false
        });
        presetsHeader.label.style = 'font-weight: bold;';
        this.menu.addMenuItem(presetsHeader);

        this._addPreset('Subtle Glass', {sigma: 20, opacity: 200, brightness: 0.7});
        this._addPreset('Dark Glass (Default)', {sigma: 30, opacity: 150, brightness: 0.6});
        this._addPreset('Deep Glass', {sigma: 40, opacity: 100, brightness: 0.5});
        this._addPreset('Crystal Clear', {sigma: 50, opacity: 80, brightness: 0.4});

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Action buttons
        this._addButton('💾 Export Theme Config', () => this._exportTheme());
        this._addButton('🔄 Reset to Default', () => this._resetToDefault());
    }

    _addSlider(label, min, max, initial, callback) {
        let item = new PopupMenu.PopupBaseMenuItem({activate: false});

        let box = new St.BoxLayout({
            vertical: false,
            x_expand: true,
            style: 'spacing: 12px;'
        });

        let labelWidget = new St.Label({
            text: label,
            style: 'min-width: 120px;'
        });
        box.add_child(labelWidget);

        let slider = new Slider(initial / max);
        slider.set_width(150);

        let valueLabel = new St.Label({
            text: initial.toString(),
            style: 'min-width: 40px; text-align: right;'
        });
        box.add_child(valueLabel);

        slider.connect('notify::value', () => {
            let value = Math.round(slider.value * max);
            valueLabel.set_text(value.toString());
            callback(value);
        });

        box.add_child(slider);
        item.add_child(box);
        this.menu.addMenuItem(item);
    }

    _addPreset(name, config) {
        let item = new PopupMenu.PopupMenuItem(`  ${name}`);
        item.connect('activate', () => {
            this._settings.set_int('sigma', config.sigma);
            this._settings.set_int('opacity', config.opacity);
            this._settings.set_double('brightness', config.brightness);
            Main.notify('DarkGlass', `✓ Applied: ${name}`);
        });
        this.menu.addMenuItem(item);
    }

    _addButton(label, callback) {
        let item = new PopupMenu.PopupMenuItem(label);
        item.connect('activate', callback);
        this.menu.addMenuItem(item);
    }

    _exportTheme() {
        let exportPath = GLib.get_home_dir() + '/DarkGlass-Theme-Export';
        let sigma = this._settings.get_int('sigma');
        let opacity = this._settings.get_int('opacity');
        let brightness = this._settings.get_double('brightness');

        Main.notify('DarkGlass',
            `Current Config:\nBlur: ${sigma}\nOpacity: ${opacity}\nBrightness: ${Math.round(brightness * 100)}%`
        );
    }

    _resetToDefault() {
        this._settings.set_int('sigma', 30);
        this._settings.set_int('opacity', 150);
        this._settings.set_double('brightness', 0.6);
        Main.notify('DarkGlass', '✓ Reset to DarkGlass defaults');
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
