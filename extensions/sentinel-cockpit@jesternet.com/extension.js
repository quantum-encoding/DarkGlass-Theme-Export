// Sentinel Cockpit - The Conductor's Real-Time Strategic Intelligence Dashboard
// Purpose: Real-time D-Bus integration with The Conductor's behavioral analysis
// Doctrine: "From The Oracle's Gaze to The Sentinel's Cockpit"

import GObject from 'gi://GObject';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

// D-Bus Configuration
const SENTINEL_SERVICE = 'org.jesternet.LogSentinel';
const SENTINEL_PATH = '/org/jesternet/LogSentinel';
const SENTINEL_INTERFACE = 'org.jesternet.LogSentinel';

// Cognitive Oracle Configuration (for Cognitive Telemetry)
const ORACLE_SERVICE = 'org.jesternet.CognitiveOracle';
const ORACLE_PATH = '/org/jesternet/CognitiveOracle';
const ORACLE_INTERFACE = 'org.jesternet.CognitiveOracle';

// Memory Pressure Monitor Configuration
const MEMORY_SERVICE = 'org.jesternet.memory.Monitor';
const MEMORY_PATH = '/org/jesternet/memory/Monitor';
const MEMORY_INTERFACE = 'org.jesternet.memory.Monitor';

// Process Diagnostician Configuration
const PROCESS_SERVICE = 'org.jesternet.process.Diagnostician';
const PROCESS_PATH = '/org/jesternet/process/Diagnostician';
const PROCESS_INTERFACE = 'org.jesternet.process.Diagnostician';

// Temperature Sentinel Configuration
const THERMAL_SERVICE = 'org.jesternet.thermal.Sentinel';
const THERMAL_PATH = '/org/jesternet/thermal/Sentinel';
const THERMAL_INTERFACE = 'org.jesternet.thermal.Sentinel';

// Network Flow Analyzer Configuration
const NETFLOW_SERVICE = 'org.jesternet.network.FlowAnalyzer';
const NETFLOW_PATH = '/org/jesternet/network/FlowAnalyzer';
const NETFLOW_INTERFACE = 'org.jesternet.network.FlowAnalyzer';

// CPU Sentinel Configuration
const CPU_SERVICE = 'org.jesternet.cpu.Sentinel';
const CPU_PATH = '/org/jesternet/cpu/Sentinel';
const CPU_INTERFACE = 'org.jesternet.cpu.Sentinel';

// GPU Sentinel Configuration
const GPU_SERVICE = 'org.jesternet.gpu.Sentinel';
const GPU_PATH = '/org/jesternet/gpu/Sentinel';
const GPU_INTERFACE = 'org.jesternet.gpu.Sentinel';

// Disk IO Sentinel Configuration
const DISK_SERVICE = 'org.jesternet.disk.Sentinel';
const DISK_PATH = '/org/jesternet/disk/Sentinel';
const DISK_INTERFACE = 'org.jesternet.disk.Sentinel';

// Filesystem Sentinel Configuration
const FS_SERVICE = 'org.jesternet.filesystem.Sentinel';
const FS_PATH = '/org/jesternet/filesystem/Sentinel';
const FS_INTERFACE = 'org.jesternet.filesystem.Sentinel';

// Cockpit Configuration
const COCKPIT_WIDTH = 520;
const COCKPIT_HEIGHT = 400;
const REFRESH_INTERVAL = 3; // seconds for status updates

// Detect available terminal emulator
function findAvailableTerminal() {
    const terminals = [
        { name: 'ghostty', cmd: 'ghostty -e' },
        { name: 'wezterm', cmd: 'wezterm start --' },
        { name: 'konsole', cmd: 'konsole -e' },
        { name: 'kgx', cmd: 'kgx -e' },  // GNOME Console
        { name: 'gnome-terminal', cmd: 'gnome-terminal --' },
        { name: 'xterm', cmd: 'xterm -e' },
    ];

    for (let terminal of terminals) {
        try {
            let [ok, stdout] = GLib.spawn_sync(
                null,
                ['which', terminal.name],
                null,
                GLib.SpawnFlags.SEARCH_PATH,
                null
            );
            if (ok && stdout && stdout.length > 0) {
                log(`[Sentinel Cockpit] Found terminal: ${terminal.name}`);
                return terminal.cmd;
            }
        } catch (e) {
            // Terminal not found, continue
        }
    }

    log('[Sentinel Cockpit] No terminal found, defaulting to xterm');
    return 'xterm -e';
}

const SentinelCockpit = GObject.registerClass(
class SentinelCockpit extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Sentinel Cockpit');

        // Detect available terminal
        this._terminalCmd = findAvailableTerminal();

        // Top bar icon with animated alert state
        this._icon = new St.Icon({
            icon_name: 'security-high-symbolic',
            style_class: 'system-status-icon sentinel-icon',
        });

        // Alert badge for critical behavioral alerts
        this._alertBadge = new St.Label({
            text: '',
            style_class: 'sentinel-alert-badge',
            visible: false,
        });

        let box = new St.BoxLayout();
        box.add_child(this._icon);
        box.add_child(this._alertBadge);
        this.add_child(box);

        // Create wider cockpit menu
        this._createCockpitInterface();

        // D-Bus connections
        this._dbusConnection = null;
        this._oracleConnection = null;
        this._signalHandlers = [];

        // Initialize D-Bus and start monitoring
        this._initDbus();
        this._initOracleDbus();
        this._startMonitoring();
    }

    _createCockpitInterface() {
        // Set menu to wider dimensions
        this.menu.box.set_width(COCKPIT_WIDTH);

        // Header section
        let headerBox = new St.BoxLayout({
            vertical: true,
            style_class: 'sentinel-header',
        });

        // Title
        let title = new St.Label({
            text: '🛡️ SENTINEL COMMAND CENTER',
            style_class: 'sentinel-title',
        });
        headerBox.add_child(title);

        // Status line
        this._statusLabel = new St.Label({
            text: '🟢 CONDUCTOR ONLINE - BEHAVIORAL ANALYSIS ACTIVE',
            style_class: 'sentinel-status',
        });
        headerBox.add_child(this._statusLabel);

        let headerItem = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        headerItem.add_child(headerBox);
        this.menu.addMenuItem(headerItem);

        // ═══════════════════════════════════════════════════════════════════════════
        // QUICK ACCESS BUTTON GRID (3 rows)
        // ═══════════════════════════════════════════════════════════════════════════

        // Store button references for dynamic updates
        this._quickButtons = {};

        let gridContainer = new St.BoxLayout({
            vertical: true,
            style_class: 'sentinel-button-grid',
        });

        // Row 1: Hardware - CPU, GPU, Thermal, Memory
        let row1Label = new St.Label({
            text: 'HARDWARE',
            style_class: 'sentinel-row-label',
        });
        gridContainer.add_child(row1Label);

        let row1 = new St.BoxLayout({
            style_class: 'sentinel-button-row',
            x_expand: true,
            x_align: Clutter.ActorAlign.CENTER,
        });

        this._quickButtons.cpu = this._createQuickButton('CPU', 'cpu-symbolic', '--', () => this._showCpuDetails());
        this._quickButtons.gpu = this._createQuickButton('GPU', 'video-display-symbolic', '--', () => this._showGpuDetails());
        this._quickButtons.thermal = this._createQuickButton('Thermal', 'sensors-temperature-symbolic', '--', () => this._runThermalAiScan());
        this._quickButtons.memory = this._createQuickButton('Memory', 'drive-harddisk-symbolic', '--', () => this._runMemoryAiScan());

        row1.add_child(this._quickButtons.cpu.actor);
        row1.add_child(this._quickButtons.gpu.actor);
        row1.add_child(this._quickButtons.thermal.actor);
        row1.add_child(this._quickButtons.memory.actor);
        gridContainer.add_child(row1);

        // Row 2: Network & Connectivity - Network, Bluetooth, Disk, Filesystem
        let row2Label = new St.Label({
            text: 'CONNECTIVITY & STORAGE',
            style_class: 'sentinel-row-label',
        });
        gridContainer.add_child(row2Label);

        let row2 = new St.BoxLayout({
            style_class: 'sentinel-button-row',
            x_expand: true,
            x_align: Clutter.ActorAlign.CENTER,
        });

        this._quickButtons.network = this._createQuickButton('Network', 'network-wired-symbolic', '--', () => this._runNetworkAiScan());
        this._quickButtons.bluetooth = this._createQuickButton('Bluetooth', 'bluetooth-symbolic', '--', () => this._showBluetoothStatus());
        this._quickButtons.disk = this._createQuickButton('Disk I/O', 'drive-harddisk-system-symbolic', '--', () => this._showDiskDetails());
        this._quickButtons.filesystem = this._createQuickButton('Filesystem', 'folder-symbolic', '--', () => this._showFilesystemDetails());

        row2.add_child(this._quickButtons.network.actor);
        row2.add_child(this._quickButtons.bluetooth.actor);
        row2.add_child(this._quickButtons.disk.actor);
        row2.add_child(this._quickButtons.filesystem.actor);
        gridContainer.add_child(row2);

        // Row 3: Processes & Logs - Processes, Logs, Cognitive, Security
        let row3Label = new St.Label({
            text: 'ANALYSIS & SECURITY',
            style_class: 'sentinel-row-label',
        });
        gridContainer.add_child(row3Label);

        let row3 = new St.BoxLayout({
            style_class: 'sentinel-button-row',
            x_expand: true,
            x_align: Clutter.ActorAlign.CENTER,
        });

        this._quickButtons.processes = this._createQuickButton('Processes', 'utilities-system-monitor-symbolic', '--', () => this._runProcessAiScan());
        this._quickButtons.logs = this._createQuickButton('Logs', 'accessories-text-editor-symbolic', '--', () => this._openLogSentinel());
        this._quickButtons.cognitive = this._createQuickButton('Cognitive', 'face-monkey-symbolic', '--', () => this._openCognitiveStateLog());
        this._quickButtons.security = this._createQuickButton('Security', 'security-high-symbolic', '--', () => this._openGrimoireLog());

        row3.add_child(this._quickButtons.processes.actor);
        row3.add_child(this._quickButtons.logs.actor);
        row3.add_child(this._quickButtons.cognitive.actor);
        row3.add_child(this._quickButtons.security.actor);
        gridContainer.add_child(row3);

        let gridItem = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        gridItem.add_child(gridContainer);
        this.menu.addMenuItem(gridItem);

        // Separator
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // ═══════════════════════════════════════════════════════════════════════════
        // DETAILED SECTIONS (collapsed by default, expand on click)
        // ═══════════════════════════════════════════════════════════════════════════

        // Behavioral Alerts Section
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('🚨 ALERTS'));
        this._alertsSection = new PopupMenu.PopupMenuSection();
        this.menu.addMenuItem(this._alertsSection);

        // Hidden sections for data - we'll use these for button updates
        this._processSection = new PopupMenu.PopupMenuSection();
        this._statusSection = new PopupMenu.PopupMenuSection();
        this._cognitiveSection = new PopupMenu.PopupMenuSection();
        this._grimoireSection = new PopupMenu.PopupMenuSection();
        this._memorySection = new PopupMenu.PopupMenuSection();
        this._processdiagSection = new PopupMenu.PopupMenuSection();
        this._thermalSection = new PopupMenu.PopupMenuSection();
        this._netflowSection = new PopupMenu.PopupMenuSection();

        // Quick Actions Row
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('⚡ QUICK ACTIONS'));

        let actionsRow = new St.BoxLayout({
            style_class: 'sentinel-button-row',
            x_expand: true,
            x_align: Clutter.ActorAlign.CENTER,
        });

        let refreshBtn = this._createQuickButton('Refresh', 'view-refresh-symbolic', '', () => this._refreshStrategicIntelligence());
        let clearBtn = this._createQuickButton('Clear', 'edit-clear-all-symbolic', '', () => this._clearAlerts());
        let reportsBtn = this._createQuickButton('Reports', 'folder-documents-symbolic', '', () => this._openScanReports());
        let settingsBtn = this._createQuickButton('Settings', 'emblem-system-symbolic', '', () => this._openSettings());

        actionsRow.add_child(refreshBtn.actor);
        actionsRow.add_child(clearBtn.actor);
        actionsRow.add_child(reportsBtn.actor);
        actionsRow.add_child(settingsBtn.actor);

        let actionsItem = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        actionsItem.add_child(actionsRow);
        this.menu.addMenuItem(actionsItem);
    }

    _createQuickButton(label, iconName, value, callback) {
        let button = new St.Button({
            style_class: 'sentinel-quick-button',
            can_focus: true,
            x_expand: true,
        });

        let buttonContent = new St.BoxLayout({
            vertical: true,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
        });

        let icon = new St.Icon({
            icon_name: iconName,
            style_class: 'sentinel-button-icon',
        });
        buttonContent.add_child(icon);

        let labelWidget = new St.Label({
            text: label,
            style_class: 'sentinel-button-label',
            x_align: Clutter.ActorAlign.CENTER,
        });
        buttonContent.add_child(labelWidget);

        let valueWidget = new St.Label({
            text: value,
            style_class: 'sentinel-button-value',
            x_align: Clutter.ActorAlign.CENTER,
        });
        buttonContent.add_child(valueWidget);

        button.set_child(buttonContent);
        button.connect('clicked', callback);

        return {
            actor: button,
            icon: icon,
            label: labelWidget,
            value: valueWidget,
            setStatus: (status) => {
                button.remove_style_class_name('sentinel-button-normal');
                button.remove_style_class_name('sentinel-button-warning');
                button.remove_style_class_name('sentinel-button-critical');
                button.remove_style_class_name('sentinel-button-offline');
                button.add_style_class_name(`sentinel-button-${status}`);
            },
            setValue: (val) => {
                valueWidget.text = val;
            }
        };
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // QUICK BUTTON CLICK HANDLERS
    // ═══════════════════════════════════════════════════════════════════════════

    _showCpuDetails() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '🖥️ CPU Status'; echo '═══════════════════════════════════════'; echo ''; busctl call org.jesternet.cpu.Sentinel /org/jesternet/cpu/Sentinel org.jesternet.cpu.Sentinel GenerateReport 2>/dev/null | sed 's/^s \"//' | sed 's/\"$//' | sed 's/\\\\n/\\n/g' || echo 'CPU Sentinel offline'; echo ''; echo 'Press Enter to close...'; read"`;
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to show CPU details: ' + e.message);
        }
    }

    _showGpuDetails() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '🎮 GPU Status'; echo '═══════════════════════════════════════'; echo ''; busctl call org.jesternet.gpu.Sentinel /org/jesternet/gpu/Sentinel org.jesternet.gpu.Sentinel GenerateReport 2>/dev/null | sed 's/^s \"//' | sed 's/\"$//' | sed 's/\\\\n/\\n/g' || nvidia-smi 2>/dev/null || echo 'GPU Sentinel offline'; echo ''; echo 'Press Enter to close...'; read"`;
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to show GPU details: ' + e.message);
        }
    }

    _showBluetoothStatus() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '📶 Bluetooth Status'; echo '═══════════════════════════════════════'; echo ''; bluetoothctl show 2>/dev/null || echo 'Bluetooth unavailable'; echo ''; echo 'Connected devices:'; bluetoothctl devices Connected 2>/dev/null || echo 'None'; echo ''; echo 'Press Enter to close...'; read"`;
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to show Bluetooth status: ' + e.message);
        }
    }

    _showDiskDetails() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '💾 Disk I/O Status'; echo '═══════════════════════════════════════'; echo ''; busctl call org.jesternet.disk.Sentinel /org/jesternet/disk/Sentinel org.jesternet.disk.Sentinel GenerateReport 2>/dev/null | sed 's/^s \"//' | sed 's/\"$//' | sed 's/\\\\n/\\n/g' || iostat -xh 2>/dev/null || echo 'Disk Sentinel offline'; echo ''; echo 'Press Enter to close...'; read"`;
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to show Disk details: ' + e.message);
        }
    }

    _showFilesystemDetails() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '📁 Filesystem Status'; echo '═══════════════════════════════════════'; echo ''; busctl call org.jesternet.filesystem.Sentinel /org/jesternet/filesystem/Sentinel org.jesternet.filesystem.Sentinel GenerateReport 2>/dev/null | sed 's/^s \"//' | sed 's/\"$//' | sed 's/\\\\n/\\n/g' || df -h 2>/dev/null; echo ''; echo 'Press Enter to close...'; read"`;
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to show Filesystem details: ' + e.message);
        }
    }

    _openLogSentinel() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '📋 Log Sentinel'; echo '═══════════════════════════════════════'; echo ''; journalctl -u log-sentinel -n 100 --no-pager 2>/dev/null || echo 'Log Sentinel offline'; echo ''; echo 'Press Enter to close...'; read"`;
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to open Log Sentinel: ' + e.message);
        }
    }

    _openSettings() {
        try {
            GLib.spawn_command_line_async('gnome-extensions prefs sentinel-cockpit@jesternet.com');
        } catch (e) {
            log('[Sentinel Cockpit] Failed to open settings: ' + e.message);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BUTTON VALUE UPDATERS (fetch live data from sentinels)
    // ═══════════════════════════════════════════════════════════════════════════

    _updateAllButtonValues() {
        this._updateCpuButton();
        this._updateGpuButton();
        this._updateThermalButton();
        this._updateMemoryButton();
        this._updateNetworkButton();
        this._updateBluetoothButton();
        this._updateDiskButton();
        this._updateFilesystemButton();
        this._updateProcessButton();
    }

    _updateCpuButton() {
        if (!this._quickButtons?.cpu) return;

        try {
            Gio.DBus.system.call(
                CPU_SERVICE, CPU_PATH, CPU_INTERFACE, 'GetLoad',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const json = reply.deepUnpack()[0];
                        const data = JSON.parse(json);
                        const pct = Math.round(data.utilization_percent || 0);
                        this._quickButtons.cpu.setValue(`${pct}%`);
                        this._quickButtons.cpu.setStatus(pct > 90 ? 'critical' : pct > 70 ? 'warning' : 'normal');
                    } catch (e) {
                        this._quickButtons.cpu.setValue('--');
                        this._quickButtons.cpu.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.cpu.setValue('--');
            this._quickButtons.cpu.setStatus('offline');
        }
    }

    _updateGpuButton() {
        if (!this._quickButtons?.gpu) return;

        try {
            Gio.DBus.system.call(
                GPU_SERVICE, GPU_PATH, GPU_INTERFACE, 'GetUtilization',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const json = reply.deepUnpack()[0];
                        const data = JSON.parse(json);
                        const pct = data.gpu_utilization_pct || 0;
                        this._quickButtons.gpu.setValue(`${pct}%`);
                        this._quickButtons.gpu.setStatus(pct > 95 ? 'critical' : pct > 80 ? 'warning' : 'normal');
                    } catch (e) {
                        this._quickButtons.gpu.setValue('--');
                        this._quickButtons.gpu.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.gpu.setValue('--');
            this._quickButtons.gpu.setStatus('offline');
        }
    }

    _updateThermalButton() {
        if (!this._quickButtons?.thermal) return;

        try {
            Gio.DBus.system.call(
                THERMAL_SERVICE, THERMAL_PATH, THERMAL_INTERFACE, 'GetAlertLevel',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const json = reply.deepUnpack()[0];
                        const data = JSON.parse(json);
                        const maxTemp = Math.round((data.hottest?.current_temp || 0) / 1000);
                        this._quickButtons.thermal.setValue(`${maxTemp}°C`);
                        const level = data.alert_level || 'Normal';
                        this._quickButtons.thermal.setStatus(
                            level === 'Critical' || level === 'Throttling' ? 'critical' :
                            level === 'Warning' ? 'warning' : 'normal'
                        );
                    } catch (e) {
                        this._quickButtons.thermal.setValue('--');
                        this._quickButtons.thermal.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.thermal.setValue('--');
            this._quickButtons.thermal.setStatus('offline');
        }
    }

    _updateMemoryButton() {
        if (!this._quickButtons?.memory) return;

        try {
            Gio.DBus.system.call(
                MEMORY_SERVICE, MEMORY_PATH, MEMORY_INTERFACE, 'GetMemoryPercent',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const pct = Math.round(reply.deepUnpack()[0]);
                        this._quickButtons.memory.setValue(`${pct}%`);
                        this._quickButtons.memory.setStatus(pct > 90 ? 'critical' : pct > 70 ? 'warning' : 'normal');
                    } catch (e) {
                        this._quickButtons.memory.setValue('--');
                        this._quickButtons.memory.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.memory.setValue('--');
            this._quickButtons.memory.setStatus('offline');
        }
    }

    _updateNetworkButton() {
        if (!this._quickButtons?.network) return;

        try {
            Gio.DBus.system.call(
                NETFLOW_SERVICE, NETFLOW_PATH, NETFLOW_INTERFACE, 'GetSnapshot',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const json = reply.deepUnpack()[0];
                        const data = JSON.parse(json);
                        const conns = data.total_connections || 0;
                        this._quickButtons.network.setValue(`${conns} conn`);
                        this._quickButtons.network.setStatus('normal');
                    } catch (e) {
                        this._quickButtons.network.setValue('--');
                        this._quickButtons.network.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.network.setValue('--');
            this._quickButtons.network.setStatus('offline');
        }
    }

    _updateBluetoothButton() {
        if (!this._quickButtons?.bluetooth) return;

        try {
            let [ok, stdout] = GLib.spawn_command_line_sync('bluetoothctl show');
            if (ok && stdout) {
                const output = new TextDecoder().decode(stdout);
                const powered = output.includes('Powered: yes');
                this._quickButtons.bluetooth.setValue(powered ? 'On' : 'Off');
                this._quickButtons.bluetooth.setStatus(powered ? 'normal' : 'offline');
            } else {
                this._quickButtons.bluetooth.setValue('--');
                this._quickButtons.bluetooth.setStatus('offline');
            }
        } catch (e) {
            this._quickButtons.bluetooth.setValue('--');
            this._quickButtons.bluetooth.setStatus('offline');
        }
    }

    _updateDiskButton() {
        if (!this._quickButtons?.disk) return;

        try {
            Gio.DBus.system.call(
                DISK_SERVICE, DISK_PATH, DISK_INTERFACE, 'GetAlertLevel',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const level = reply.deepUnpack()[0];
                        this._quickButtons.disk.setValue(level);
                        this._quickButtons.disk.setStatus(
                            level === 'Critical' ? 'critical' :
                            level === 'Warning' ? 'warning' : 'normal'
                        );
                    } catch (e) {
                        this._quickButtons.disk.setValue('--');
                        this._quickButtons.disk.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.disk.setValue('--');
            this._quickButtons.disk.setStatus('offline');
        }
    }

    _updateFilesystemButton() {
        if (!this._quickButtons?.filesystem) return;

        try {
            Gio.DBus.system.call(
                FS_SERVICE, FS_PATH, FS_INTERFACE, 'GetAlertLevel',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const level = reply.deepUnpack()[0];
                        this._quickButtons.filesystem.setValue(level);
                        this._quickButtons.filesystem.setStatus(
                            level === 'Critical' ? 'critical' :
                            level === 'Warning' ? 'warning' : 'normal'
                        );
                    } catch (e) {
                        this._quickButtons.filesystem.setValue('--');
                        this._quickButtons.filesystem.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.filesystem.setValue('--');
            this._quickButtons.filesystem.setStatus('offline');
        }
    }

    _updateProcessButton() {
        if (!this._quickButtons?.processes) return;

        try {
            Gio.DBus.system.call(
                PROCESS_SERVICE, PROCESS_PATH, PROCESS_INTERFACE, 'GetAlertLevel',
                null, null, Gio.DBusCallFlags.NONE, 3000, null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const level = reply.deepUnpack()[0];
                        this._quickButtons.processes.setValue(level);
                        this._quickButtons.processes.setStatus(
                            level === 'Critical' ? 'critical' :
                            level === 'Warning' ? 'warning' : 'normal'
                        );
                    } catch (e) {
                        this._quickButtons.processes.setValue('--');
                        this._quickButtons.processes.setStatus('offline');
                    }
                }
            );
        } catch (e) {
            this._quickButtons.processes.setValue('--');
            this._quickButtons.processes.setStatus('offline');
        }
    }

    async _initDbus() {
        try {
            this._dbusConnection = Gio.DBus.session;

            // Initial fetch of events and summary
            this._fetchLogSentinelData();

            this._updateStatus('🟢 LOG SENTINEL CONNECTED - REAL-TIME MONITORING');
        } catch (e) {
            log('[Sentinel Cockpit] D-Bus connection failed: ' + e.message);
            this._updateStatus('🔴 LOG SENTINEL OFFLINE - FALLBACK MODE');
        }
    }

    async _initOracleDbus() {
        try {
            this._oracleConnection = Gio.DBus.session;
            log('[Sentinel Cockpit] Connected to Cognitive Oracle for instant telemetry');

            // Initial cognitive state fetch
            this._updateCognitiveState();
        } catch (e) {
            log('[Sentinel Cockpit] Oracle D-Bus connection failed: ' + e.message);
        }
    }

    async _fetchLogSentinelData() {
        if (!this._dbusConnection) return;

        try {
            // Fetch events from LogSentinel
            this._dbusConnection.call(
                SENTINEL_SERVICE,
                SENTINEL_PATH,
                SENTINEL_INTERFACE,
                'GetEvents',
                null,
                null,
                Gio.DBusCallFlags.NONE,
                -1,
                null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const eventsJson = reply.deepUnpack()[0];
                        const events = JSON.parse(eventsJson);
                        this._displayEvents(events);
                    } catch (e) {
                        log('[Sentinel Cockpit] Error getting events: ' + e.message);
                    }
                }
            );

            // Fetch summary from LogSentinel
            this._dbusConnection.call(
                SENTINEL_SERVICE,
                SENTINEL_PATH,
                SENTINEL_INTERFACE,
                'GetSummary',
                null,
                null,
                Gio.DBusCallFlags.NONE,
                -1,
                null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const summaryJson = reply.deepUnpack()[0];
                        const summary = JSON.parse(summaryJson);
                        this._displaySummary(summary);
                    } catch (e) {
                        log('[Sentinel Cockpit] Error getting summary: ' + e.message);
                    }
                }
            );
        } catch (e) {
            log('[Sentinel Cockpit] Error fetching LogSentinel data: ' + e.message);
        }
    }

    _displayEvents(events) {
        // Clear alerts section
        this._alertsSection.removeAll();

        if (!events || events.length === 0) {
            let noEventsItem = new PopupMenu.PopupMenuItem('No events logged');
            noEventsItem.reactive = false;
            this._alertsSection.addMenuItem(noEventsItem);
            return;
        }

        // Display most recent events (up to 10)
        events.slice(0, 10).forEach(event => {
            let eventText = `${event.timestamp || 'unknown'}\n`;
            eventText += `${event.level || 'INFO'}: ${event.message || 'No message'}`;

            let eventItem = new PopupMenu.PopupMenuItem(eventText);
            eventItem.connect('activate', () => {
                try {
                    const command = `${this._terminalCmd} bash -c "journalctl -f | grep -i '${event.message.substring(0, 30)}'; exec bash"`;
                    log('[Sentinel Cockpit] Opening event logs');
                    GLib.spawn_command_line_async(command);
                } catch (e) {
                    log('[Sentinel Cockpit] Failed to open logs: ' + e.message);
                }
            });
            this._alertsSection.addMenuItem(eventItem);
        });
    }

    _displaySummary(summary) {
        // Clear status section
        this._statusSection.removeAll();

        if (!summary) {
            let noSummaryItem = new PopupMenu.PopupMenuItem('No summary available');
            noSummaryItem.reactive = false;
            this._statusSection.addMenuItem(noSummaryItem);
            return;
        }

        // Display summary stats
        Object.entries(summary).forEach(([key, value]) => {
            let summaryItem = new PopupMenu.PopupMenuItem(`${key}: ${value}`);
            summaryItem.connect('activate', () => {
                try {
                    const command = `${this._terminalCmd} bash -c "journalctl -f -u log-sentinel-v2; exec bash"`;
                    log('[Sentinel Cockpit] Opening sentinel logs');
                    GLib.spawn_command_line_async(command);
                } catch (e) {
                    log('[Sentinel Cockpit] Failed to open logs: ' + e.message);
                }
            });
            this._statusSection.addMenuItem(summaryItem);
        });
    }


    _updateStatus(status) {
        this._statusLabel.text = status;
    }

    _getSeverityIcon(severity) {
        switch (severity) {
            case 'CRITICAL': return '🔴';
            case 'HIGH': return '🟠';
            case 'MEDIUM': return '🟡';
            default: return '⚪';
        }
    }

    async _updateCognitiveState() {
        try {
            // Read cognitive states directly from journalctl logs
            let [ok, stdout, stderr, exitStatus] = GLib.spawn_command_line_sync(
                'journalctl -u cognitive-watcher -n 500 --no-pager'
            );

            if (!ok || exitStatus !== 0) {
                log('[Sentinel Cockpit] Error reading cognitive-watcher logs');
                return;
            }

            const output = new TextDecoder().decode(stdout);
            const states = this._parseStatesFromJournal(output);

            if (states.length > 0) {
                this._displayCognitiveState(states[0]);
                this._displayCognitiveHistory(states.slice(0, 20));
            }
        } catch (e) {
            log('[Sentinel Cockpit] Error updating cognitive state: ' + e.message);
        }
    }

    _parseStatesFromJournal(journalOutput) {
        const lines = journalOutput.split('\n');
        const states = [];
        const seenStates = new Set();

        // Parse lines looking for state patterns
        for (let line of lines.reverse()) {
            let stateName = null;

            // Pattern 1: "⏭️  * StateName (continuing, Xs elapsed)"
            let match = line.match(/⏭️\s+\*\s+([A-Za-z\s]+)\s+\(continuing/);
            if (match) {
                stateName = match[1].trim();
            }

            // Pattern 2: "🔄 NEW STATE: * StateName"
            if (!stateName) {
                match = line.match(/🔄 NEW STATE:\s+\*\s+([A-Za-z\s]+)/);
                if (match) {
                    stateName = match[1].trim();
                }
            }

            // Pattern 3: "📊 STATE TRANSITION: * StateName (duration:"
            if (!stateName) {
                match = line.match(/📊 STATE TRANSITION:\s+\*\s+([A-Za-z\s]+)\s+\(duration/);
                if (match) {
                    stateName = match[1].trim();
                }
            }

            // Add unique states only
            if (stateName && !seenStates.has(stateName)) {
                seenStates.add(stateName);
                states.push({ state: stateName, pid: 'claude' });
            }

            // Stop after collecting 20 unique states
            if (states.length >= 20) break;
        }

        return states;
    }

    _displayCognitiveState(stateObj) {
        // Clear cognitive section
        this._cognitiveSection.removeAll();

        // Display current cognitive state with emoji
        let stateEmoji = this._getCognitiveStateEmoji(stateObj.state);
        let currentStateItem = new PopupMenu.PopupMenuItem(`${stateEmoji} Current: ${stateObj.state}`);
        currentStateItem.style_class = 'sentinel-cognitive-current';
        this._cognitiveSection.addMenuItem(currentStateItem);
    }

    _displayCognitiveHistory(states) {
        // Display last 20 unique cognitive states
        if (states.length > 0) {
            let historyItem = new PopupMenu.PopupMenuItem('📜 Recent States (click to view log):');
            historyItem.reactive = false;
            this._cognitiveSection.addMenuItem(historyItem);

            // Display simple list of state names
            states.forEach(stateObj => {
                let emoji = this._getCognitiveStateEmoji(stateObj.state);
                let stateText = `  ${emoji} ${stateObj.state}`;

                let item = new PopupMenu.PopupMenuItem(stateText);
                item.connect('activate', () => {
                    this._openCognitiveStateLog();
                });
                this._cognitiveSection.addMenuItem(item);
            });
        }
    }

    _openCognitiveStateLog() {
        try {
            // Create a log showing the last 20 cognitive states in clean format
            const command = `${this._terminalCmd} bash -c "echo '🧠 Cognitive State Log - Last 20 States'; echo '═══════════════════════════════════════'; echo ''; journalctl -u cognitive-watcher -n 500 --no-pager | grep -E '⏭️.*continuing|🔄 NEW STATE|📊 STATE TRANSITION' | grep -oP '(?<=\\* )[A-Za-z ]+(?= \\()' | awk '!seen[\\$0]++' | head -20 | nl -w2 -s'. '; echo ''; echo ''; echo 'Press Enter to close...'; read"`;
            log('[Sentinel Cockpit] Opening cognitive state log');
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to open cognitive state log: ' + e.message);
        }
    }

    _updateGrimoireAlerts() {
        try {
            // Read grimoire alerts from file
            let file = Gio.File.new_for_path('/var/log/zig-sentinel/grimoire_alerts.json');
            if (!file.query_exists(null)) {
                let noAlertsItem = new PopupMenu.PopupMenuItem('No grimoire alerts');
                noAlertsItem.reactive = false;
                this._grimoireSection.addMenuItem(noAlertsItem);
                return;
            }

            // Get file modification time
            let fileInfo = file.query_info('time::modified', Gio.FileQueryInfoFlags.NONE, null);
            let modTime = fileInfo.get_modification_date_time();
            let modTimeStr = modTime.format('%Y-%m-%d %H:%M');

            // Count alerts by pattern
            let [ok, contents] = file.load_contents(null);
            if (!ok) return;

            const text = new TextDecoder().decode(contents);
            const lines = text.trim().split('\n');
            const patternCounts = {};
            let totalAlerts = 0;

            lines.forEach(line => {
                try {
                    const alert = JSON.parse(line);
                    patternCounts[alert.pattern_name] = (patternCounts[alert.pattern_name] || 0) + 1;
                    totalAlerts++;
                } catch (e) {}
            });

            // Display summary
            let summaryItem = new PopupMenu.PopupMenuItem(`📊 ${totalAlerts} alerts (last: ${modTimeStr})`);
            summaryItem.reactive = false;
            this._grimoireSection.addMenuItem(summaryItem);

            // Display pattern counts (clickable to view log)
            Object.entries(patternCounts).sort((a, b) => b[1] - a[1]).forEach(([pattern, count]) => {
                let emoji = pattern.includes('reverse_shell') ? '🔓' : pattern.includes('fork_bomb') ? '💣' : '⚠️';
                let item = new PopupMenu.PopupMenuItem(`  ${emoji} ${pattern}: ${count}`);
                item.connect('activate', () => {
                    this._openGrimoireLog();
                });
                this._grimoireSection.addMenuItem(item);
            });
        } catch (e) {
            log('[Sentinel Cockpit] Error loading grimoire alerts: ' + e.message);
        }
    }

    _openGrimoireLog() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '📖 Grimoire Alerts Log'; echo '═══════════════════════════════════════'; echo ''; echo 'File: /var/log/zig-sentinel/grimoire_alerts.json'; echo 'Last modified:'; ls -lh /var/log/zig-sentinel/grimoire_alerts.json; echo ''; echo 'Alert Summary:'; cat /var/log/zig-sentinel/grimoire_alerts.json | jq -r .pattern_name | sort | uniq -c | sort -rn; echo ''; echo 'Last 20 Alerts:'; tail -20 /var/log/zig-sentinel/grimoire_alerts.json | jq -r '\"[\\(.pattern_name)] PID=\\(.pid) Action=\\(.action)\"' | nl; echo ''; echo 'Press Enter to close...'; read"`;
            log('[Sentinel Cockpit] Opening grimoire alerts log');
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to open grimoire log: ' + e.message);
        }
    }

    _getCognitiveStateEmoji(state) {
        // Map cognitive states to emojis
        const stateMap = {
            'Thinking': '🤔',
            'Pondering': '💭',
            'Channelling': '🌀',
            'Precipitating': '💧',
            'Composing': '✍️',
            'Contemplating': '🧘',
            'Julienning': '🔪',
            'Discombobulating': '😵',
            'Verifying': '✅',
            'Active': '⚡',
            'Reading': '📖',
            'Writing': '📝',
            'Executing': '⚙️',
            'Marinating': '🥘',
            'Booping': '👆',
            'Honking': '📯',
            'Percolating': '☕',
            'Synthesizing': '🧪',
            'Crystallizing': '💎'
        };

        // Try to match the state with known patterns
        for (const [key, emoji] of Object.entries(stateMap)) {
            if (state.includes(key)) {
                return emoji;
            }
        }

        return '🧠'; // Default brain emoji
    }

    // Memory Pressure Monitor Integration
    async _fetchMemoryPressure() {
        this._memorySection.removeAll();

        try {
            // Use system bus for memory monitor
            Gio.DBus.system.call(
                MEMORY_SERVICE,
                MEMORY_PATH,
                MEMORY_INTERFACE,
                'GetSnapshot',
                null,
                null,
                Gio.DBusCallFlags.NONE,
                5000,
                null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const snapshotJson = reply.deepUnpack()[0];
                        const snapshot = JSON.parse(snapshotJson);
                        this._displayMemorySnapshot(snapshot);
                    } catch (e) {
                        log('[Sentinel Cockpit] Error getting memory snapshot: ' + e.message);
                        this._displayMemoryOffline();
                    }
                }
            );
        } catch (e) {
            log('[Sentinel Cockpit] Memory pressure fetch error: ' + e.message);
            this._displayMemoryOffline();
        }
    }

    _displayMemorySnapshot(snapshot) {
        this._memorySection.removeAll();

        // Alert level with emoji
        const alertEmoji = {
            'Normal': '🟢',
            'Warning': '🟡',
            'Critical': '🟠',
            'Emergency': '🔴'
        };
        const emoji = alertEmoji[snapshot.alert_level] || '⚪';

        // Memory usage header
        const usedGb = (snapshot.used_bytes / 1073741824).toFixed(1);
        const totalGb = (snapshot.total_bytes / 1073741824).toFixed(1);
        const pct = snapshot.percent_used.toFixed(0);
        let headerItem = new PopupMenu.PopupMenuItem(`${emoji} ${usedGb}/${totalGb} GB (${pct}%) | Alert: ${snapshot.alert_level}`);
        headerItem.connect('activate', () => this._runMemoryAiScan());
        this._memorySection.addMenuItem(headerItem);

        // Swap usage
        if (snapshot.swap_percent > 0) {
            const swapEmoji = snapshot.swap_percent > 50 ? '⚠️' : '💾';
            let swapItem = new PopupMenu.PopupMenuItem(`  ${swapEmoji} Swap: ${snapshot.swap_percent.toFixed(1)}%`);
            swapItem.reactive = false;
            this._memorySection.addMenuItem(swapItem);
        }

        // PSI metrics if available
        if (snapshot.psi_some_avg10 !== undefined) {
            const psiEmoji = snapshot.psi_some_avg10 > 5 ? '🔥' : '📊';
            let psiItem = new PopupMenu.PopupMenuItem(`  ${psiEmoji} PSI: ${snapshot.psi_some_avg10.toFixed(1)}% (10s avg)`);
            psiItem.reactive = false;
            this._memorySection.addMenuItem(psiItem);
        }

        // Memory trend
        if (snapshot.trend_1m) {
            const trendEmoji = snapshot.trend_1m < 0 ? '📉' : '📈';
            const trendKb = (snapshot.trend_1m / 1024).toFixed(0);
            let trendItem = new PopupMenu.PopupMenuItem(`  ${trendEmoji} Trend: ${trendKb} KB/min`);
            trendItem.reactive = false;
            this._memorySection.addMenuItem(trendItem);
        }
    }

    _displayMemoryOffline() {
        this._memorySection.removeAll();
        let offlineItem = new PopupMenu.PopupMenuItem('⚫ Memory Monitor Offline');
        offlineItem.reactive = false;
        this._memorySection.addMenuItem(offlineItem);

        let startItem = new PopupMenu.PopupMenuItem('  ▶️ Start memory-pressure-monitor.service');
        startItem.connect('activate', () => {
            GLib.spawn_command_line_async('systemctl --user start memory-pressure-monitor');
        });
        this._memorySection.addMenuItem(startItem);
    }

    // Process Diagnostician Integration
    async _fetchProcessDiagnostics() {
        this._processdiagSection.removeAll();

        try {
            Gio.DBus.system.call(
                PROCESS_SERVICE,
                PROCESS_PATH,
                PROCESS_INTERFACE,
                'GetSnapshot',
                null,
                null,
                Gio.DBusCallFlags.NONE,
                5000,
                null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const snapshotJson = reply.deepUnpack()[0];
                        const snapshot = JSON.parse(snapshotJson);
                        this._displayProcessSnapshot(snapshot);
                    } catch (e) {
                        log('[Sentinel Cockpit] Error getting process snapshot: ' + e.message);
                        this._displayProcessOffline();
                    }
                }
            );
        } catch (e) {
            log('[Sentinel Cockpit] Process diagnostics fetch error: ' + e.message);
            this._displayProcessOffline();
        }
    }

    _displayProcessSnapshot(snapshot) {
        this._processdiagSection.removeAll();

        // Zombies
        const zombieCount = snapshot.zombies?.length || 0;
        const zombieEmoji = zombieCount > 0 ? '🧟' : '✅';
        let zombieItem = new PopupMenu.PopupMenuItem(`${zombieEmoji} Zombies: ${zombieCount}`);
        zombieItem.connect('activate', () => this._runProcessAiScan());
        this._processdiagSection.addMenuItem(zombieItem);

        // Memory hogs
        const hogCount = snapshot.memory_hogs?.length || 0;
        const hogEmoji = hogCount > 0 ? '🐷' : '✅';
        let hogItem = new PopupMenu.PopupMenuItem(`${hogEmoji} Memory Hogs: ${hogCount}`);
        hogItem.connect('activate', () => this._runProcessAiScan());
        this._processdiagSection.addMenuItem(hogItem);

        // FD Leaks
        const fdCount = snapshot.fd_leaks?.length || 0;
        const fdEmoji = fdCount > 0 ? '📂' : '✅';
        let fdItem = new PopupMenu.PopupMenuItem(`${fdEmoji} FD Leaks: ${fdCount}`);
        fdItem.connect('activate', () => this._runProcessAiScan());
        this._processdiagSection.addMenuItem(fdItem);

        // Show top memory hog if any
        if (snapshot.memory_hogs && snapshot.memory_hogs.length > 0) {
            const top = snapshot.memory_hogs[0];
            const memMb = (top.rss_bytes / 1048576).toFixed(0);
            let topItem = new PopupMenu.PopupMenuItem(`  🔝 Top: ${top.name} (${memMb} MB)`);
            topItem.reactive = false;
            this._processdiagSection.addMenuItem(topItem);
        }
    }

    _displayProcessOffline() {
        this._processdiagSection.removeAll();
        let offlineItem = new PopupMenu.PopupMenuItem('⚫ Process Diagnostician Offline');
        offlineItem.reactive = false;
        this._processdiagSection.addMenuItem(offlineItem);

        let startItem = new PopupMenu.PopupMenuItem('  ▶️ Start process-diagnostician.service');
        startItem.connect('activate', () => {
            GLib.spawn_command_line_async('systemctl --user start process-diagnostician');
        });
        this._processdiagSection.addMenuItem(startItem);
    }

    // Temperature Sentinel Integration
    async _fetchThermalData() {
        this._thermalSection.removeAll();

        try {
            Gio.DBus.system.call(
                THERMAL_SERVICE,
                THERMAL_PATH,
                THERMAL_INTERFACE,
                'GetSnapshot',
                null,
                null,
                Gio.DBusCallFlags.NONE,
                5000,
                null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const snapshotJson = reply.deepUnpack()[0];
                        const snapshot = JSON.parse(snapshotJson);
                        this._displayThermalSnapshot(snapshot);
                    } catch (e) {
                        log('[Sentinel Cockpit] Error getting thermal snapshot: ' + e.message);
                        this._displayThermalOffline();
                    }
                }
            );
        } catch (e) {
            log('[Sentinel Cockpit] Thermal fetch error: ' + e.message);
            this._displayThermalOffline();
        }
    }

    _displayThermalSnapshot(snapshot) {
        this._thermalSection.removeAll();

        // Alert level with emoji and color
        const alertEmoji = {
            'Normal': '🟢',
            'Warning': '🟡',
            'Critical': '🟠',
            'Throttling': '🔴'
        };
        const emoji = alertEmoji[snapshot.alert_level] || '⚪';

        // Hottest sensor header
        if (snapshot.hottest) {
            const tempC = Math.round(snapshot.hottest.current_temp / 1000);
            const throttleIcon = snapshot.throttling_detected ? ' ⚡' : '';
            let headerItem = new PopupMenu.PopupMenuItem(`${emoji} ${snapshot.hottest.name}: ${tempC}°C${throttleIcon}`);
            headerItem.connect('activate', () => this._runThermalAiScan());
            this._thermalSection.addMenuItem(headerItem);
        }

        // Alert level
        let alertItem = new PopupMenu.PopupMenuItem(`  📊 Alert: ${snapshot.alert_level}`);
        alertItem.reactive = false;
        this._thermalSection.addMenuItem(alertItem);

        // Throttling warning
        if (snapshot.throttling_detected) {
            let throttleItem = new PopupMenu.PopupMenuItem('  ⚠️ THERMAL THROTTLING ACTIVE');
            throttleItem.reactive = false;
            this._thermalSection.addMenuItem(throttleItem);
        }

        // Show top 3 hottest sensors
        if (snapshot.sensors && snapshot.sensors.length > 0) {
            const sorted = snapshot.sensors
                .filter(s => s.current_temp > 0)
                .sort((a, b) => b.current_temp - a.current_temp)
                .slice(0, 3);

            sorted.forEach((sensor, idx) => {
                const tempC = Math.round(sensor.current_temp / 1000);
                const typeIcon = this._getSensorTypeIcon(sensor.sensor_type);
                let sensorItem = new PopupMenu.PopupMenuItem(`  ${typeIcon} ${sensor.name}: ${tempC}°C`);
                sensorItem.reactive = false;
                this._thermalSection.addMenuItem(sensorItem);
            });
        }

        // Sensor count
        let countItem = new PopupMenu.PopupMenuItem(`  📡 ${snapshot.sensors?.length || 0} sensors monitored`);
        countItem.reactive = false;
        this._thermalSection.addMenuItem(countItem);
    }

    _getSensorTypeIcon(sensorType) {
        const icons = {
            'Cpu': '🖥️',
            'Gpu': '🎮',
            'Nvme': '💾',
            'Chipset': '🔧',
            'Wireless': '📶',
            'Other': '📊'
        };
        return icons[sensorType] || '📊';
    }

    _displayThermalOffline() {
        this._thermalSection.removeAll();
        let offlineItem = new PopupMenu.PopupMenuItem('⚫ Temperature Sentinel Offline');
        offlineItem.reactive = false;
        this._thermalSection.addMenuItem(offlineItem);

        let startItem = new PopupMenu.PopupMenuItem('  ▶️ Start temperature-sentinel.service');
        startItem.connect('activate', () => {
            GLib.spawn_command_line_async('systemctl start temperature-sentinel');
        });
        this._thermalSection.addMenuItem(startItem);
    }

    // AI Scan Launchers
    _runMemoryAiScan() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '🧠 Running AI Memory Analysis...'; echo ''; memory-scan-and-analyze; echo ''; echo 'Press Enter to close...'; read"`;
            log('[Sentinel Cockpit] Launching AI memory scan');
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to launch memory AI scan: ' + e.message);
        }
    }

    _runProcessAiScan() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '🔬 Running AI Process Analysis...'; echo ''; scan-and-analyze; echo ''; echo 'Press Enter to close...'; read"`;
            log('[Sentinel Cockpit] Launching AI process scan');
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to launch process AI scan: ' + e.message);
        }
    }

    _runThermalAiScan() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '🌡️ Running AI Thermal Analysis...'; echo ''; thermal-scan-and-analyze; echo ''; echo 'Press Enter to close...'; read"`;
            log('[Sentinel Cockpit] Launching AI thermal scan');
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to launch thermal AI scan: ' + e.message);
        }
    }

    _runNetworkAiScan() {
        try {
            const command = `${this._terminalCmd} bash -c "echo '🌐 Running AI Network Analysis...'; echo ''; network-scan-and-analyze; echo ''; echo 'Press Enter to close...'; read"`;
            log('[Sentinel Cockpit] Launching AI network scan');
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to launch network AI scan: ' + e.message);
        }
    }

    // Network Flow Analyzer Integration
    async _fetchNetworkFlows() {
        this._netflowSection.removeAll();

        try {
            Gio.DBus.system.call(
                NETFLOW_SERVICE,
                NETFLOW_PATH,
                NETFLOW_INTERFACE,
                'GetSnapshot',
                null,
                null,
                Gio.DBusCallFlags.NONE,
                5000,
                null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const snapshotJson = reply.deepUnpack()[0];
                        const snapshot = JSON.parse(snapshotJson);
                        this._displayNetworkSnapshot(snapshot);
                    } catch (e) {
                        log('[Sentinel Cockpit] Error getting network snapshot: ' + e.message);
                        this._displayNetworkOffline();
                    }
                }
            );
        } catch (e) {
            log('[Sentinel Cockpit] Network flow fetch error: ' + e.message);
            this._displayNetworkOffline();
        }
    }

    _displayNetworkSnapshot(snapshot) {
        this._netflowSection.removeAll();

        // Bandwidth header
        const rxRate = this._formatRate(snapshot.total_rx_rate || 0);
        const txRate = this._formatRate(snapshot.total_tx_rate || 0);
        let headerItem = new PopupMenu.PopupMenuItem(`📊 ↓ ${rxRate} | ↑ ${txRate}`);
        headerItem.connect('activate', () => this._runNetworkAiScan());
        this._netflowSection.addMenuItem(headerItem);

        // Connection counts
        let connItem = new PopupMenu.PopupMenuItem(`  🔗 ${snapshot.total_connections || 0} connections (TCP: ${snapshot.total_tcp || 0}, UDP: ${snapshot.total_udp || 0})`);
        connItem.reactive = false;
        this._netflowSection.addMenuItem(connItem);

        // Process count
        let procItem = new PopupMenu.PopupMenuItem(`  📡 ${snapshot.process_count || 0} active processes`);
        procItem.reactive = false;
        this._netflowSection.addMenuItem(procItem);

        // Top talkers (up to 3)
        if (snapshot.top_talkers && snapshot.top_talkers.length > 0) {
            const topTalkers = snapshot.top_talkers.slice(0, 3);
            for (const proc of topTalkers) {
                const totalRate = (proc.bytes_rx_rate || 0) + (proc.bytes_tx_rate || 0);
                const rateStr = this._formatRate(totalRate);
                const connCount = (proc.tcp_connections || 0) + (proc.udp_connections || 0);
                let talkerItem = new PopupMenu.PopupMenuItem(`  🔝 ${proc.name}: ${rateStr} (${connCount} conn)`);
                talkerItem.reactive = false;
                this._netflowSection.addMenuItem(talkerItem);
            }
        }
    }

    _formatRate(bytesPerSec) {
        if (bytesPerSec >= 1000000000) {
            return `${(bytesPerSec / 1000000000).toFixed(1)} GB/s`;
        } else if (bytesPerSec >= 1000000) {
            return `${(bytesPerSec / 1000000).toFixed(1)} MB/s`;
        } else if (bytesPerSec >= 1000) {
            return `${(bytesPerSec / 1000).toFixed(1)} KB/s`;
        } else {
            return `${Math.round(bytesPerSec)} B/s`;
        }
    }

    _displayNetworkOffline() {
        this._netflowSection.removeAll();
        let offlineItem = new PopupMenu.PopupMenuItem('⚫ Network Flow Analyzer Offline');
        offlineItem.reactive = false;
        this._netflowSection.addMenuItem(offlineItem);

        let startItem = new PopupMenu.PopupMenuItem('  ▶️ Start network-flow-analyzer.service');
        startItem.connect('activate', () => {
            GLib.spawn_command_line_async('systemctl start network-flow-analyzer');
        });
        this._netflowSection.addMenuItem(startItem);
    }

    _openScanReports() {
        try {
            const reportsDir = GLib.get_home_dir() + '/agent_sandboxes/tool_scans';
            const command = `${this._terminalCmd} bash -c "echo '📂 AI Scan Reports'; echo '═══════════════════════════════════════'; echo ''; echo 'Location: ${reportsDir}'; echo ''; ls -lht ${reportsDir} | head -20; echo ''; echo 'Latest reports:'; echo ''; for f in \\$(ls -t ${reportsDir}/*.md 2>/dev/null | head -3); do echo \\"--- \\$f ---\\"; head -30 \\\"\\$f\\\"; echo ''; done; echo ''; echo 'Press Enter to close...'; read"`;
            log('[Sentinel Cockpit] Opening scan reports');
            GLib.spawn_command_line_async(command);
        } catch (e) {
            log('[Sentinel Cockpit] Failed to open scan reports: ' + e.message);
        }
    }

    _refreshStrategicIntelligence() {
        // Force refresh of all sections
        this._alertsSection.removeAll();

        this._updateStatus('🔄 REFRESHING STRATEGIC INTELLIGENCE...');

        // Update all quick access button values
        this._updateAllButtonValues();

        // Refresh LogSentinel data
        this._fetchLogSentinelData();

        // Refresh cognitive state
        this._updateCognitiveState();

        // Refresh grimoire alerts
        this._updateGrimoireAlerts();

        // Update cognitive and security button labels
        this._updateCognitiveButton();
        this._updateSecurityButton();
        this._updateLogsButton();

        setTimeout(() => {
            this._updateStatus('🟢 SENTINEL COMMAND CENTER - ALL SYSTEMS ACTIVE');
        }, 1000);
    }

    _updateCognitiveButton() {
        if (!this._quickButtons?.cognitive) return;
        // Get the latest cognitive state from parsed journal
        try {
            let [ok, stdout] = GLib.spawn_command_line_sync(
                'journalctl -u cognitive-watcher -n 50 --no-pager'
            );
            if (ok && stdout) {
                const output = new TextDecoder().decode(stdout);
                // Find the most recent state
                const match = output.match(/(?:⏭️\s+\*\s+|🔄 NEW STATE:\s+\*\s+)([A-Za-z]+)/);
                if (match) {
                    this._quickButtons.cognitive.setValue(match[1].substring(0, 8));
                    this._quickButtons.cognitive.setStatus('normal');
                } else {
                    this._quickButtons.cognitive.setValue('Active');
                    this._quickButtons.cognitive.setStatus('normal');
                }
            }
        } catch (e) {
            this._quickButtons.cognitive.setValue('--');
            this._quickButtons.cognitive.setStatus('offline');
        }
    }

    _updateSecurityButton() {
        if (!this._quickButtons?.security) return;
        // Count grimoire alerts
        try {
            let file = Gio.File.new_for_path('/var/log/zig-sentinel/grimoire_alerts.json');
            if (file.query_exists(null)) {
                let [ok, contents] = file.load_contents(null);
                if (ok) {
                    const text = new TextDecoder().decode(contents);
                    const lines = text.trim().split('\n').filter(l => l.length > 0);
                    this._quickButtons.security.setValue(`${lines.length} alerts`);
                    this._quickButtons.security.setStatus(lines.length > 10 ? 'warning' : 'normal');
                }
            } else {
                this._quickButtons.security.setValue('OK');
                this._quickButtons.security.setStatus('normal');
            }
        } catch (e) {
            this._quickButtons.security.setValue('--');
            this._quickButtons.security.setStatus('offline');
        }
    }

    _updateLogsButton() {
        if (!this._quickButtons?.logs) return;
        // Just show "Active" for now
        this._quickButtons.logs.setValue('Active');
        this._quickButtons.logs.setStatus('normal');
    }

    _clearAlerts() {
        try {
            if (this._dbusConnection) {
                this._dbusConnection.call(
                    SENTINEL_SERVICE,
                    SENTINEL_PATH,
                    SENTINEL_INTERFACE,
                    'ClearEvents',
                    null,
                    null,
                    Gio.DBusCallFlags.NONE,
                    -1,
                    null,
                    (connection, result) => {
                        try {
                            connection.call_finish(result);
                            log('[Sentinel Cockpit] Cleared LogSentinel events');
                        } catch (e) {
                            log('[Sentinel Cockpit] Error clearing events: ' + e.message);
                        }
                    }
                );
            }

            this._alertsSection.removeAll();
            this._alertBadge.visible = false;
            this._alertBadge.text = '';
            this._icon.icon_name = 'security-high-symbolic';

            this._updateStatus('🟢 ALERTS CLEARED - MONITORING CONTINUES');
        } catch (e) {
            log('[Sentinel Cockpit] Error in clearAlerts: ' + e.message);
        }
    }

    _startMonitoring() {
        // Start periodic status updates
        this._timeout = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, REFRESH_INTERVAL, () => {
            this._refreshStrategicIntelligence();
            return GLib.SOURCE_CONTINUE;
        });

        // Start more frequent cognitive state updates (every 2 seconds)
        this._cognitiveTimeout = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 2, () => {
            this._updateCognitiveState();
            return GLib.SOURCE_CONTINUE;
        });
    }

    destroy() {
        // Clean up signal handlers
        this._signalHandlers.forEach(handler => {
            if (this._dbusConnection && handler) {
                this._dbusConnection.signal_unsubscribe(handler);
            }
        });

        if (this._timeout) {
            GLib.source_remove(this._timeout);
            this._timeout = null;
        }

        if (this._cognitiveTimeout) {
            GLib.source_remove(this._cognitiveTimeout);
            this._cognitiveTimeout = null;
        }

        super.destroy();
    }
});

export default class SentinelCockpitExtension {
    constructor() {
        this._cockpit = null;
    }

    enable() {
        this._cockpit = new SentinelCockpit();
        Main.panel.addToStatusArea('sentinel-cockpit', this._cockpit);
    }

    disable() {
        if (this._cockpit) {
            this._cockpit.destroy();
            this._cockpit = null;
        }
    }
}