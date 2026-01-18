// Log Sentinel V2 - Real-time Security Event Monitor
// Using Rust daemon via D-Bus for zero-latency monitoring

import GObject from 'gi://GObject';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

const DBUS_NAME = 'org.jesternet.LogSentinel';
const DBUS_PATH = '/org/jesternet/LogSentinel';
const DBUS_INTERFACE = 'org.jesternet.LogSentinel';

const REFRESH_INTERVAL = 5; // seconds

const LogSentinelIface = `
<node>
  <interface name="${DBUS_INTERFACE}">
    <method name="GetEvents">
      <arg type="s" direction="out" name="events"/>
    </method>
    <method name="GetSummary">
      <arg type="s" direction="out" name="summary"/>
    </method>
    <method name="GetEventsByCategory">
      <arg type="s" direction="in" name="category"/>
      <arg type="s" direction="out" name="events"/>
    </method>
    <method name="ClearEvents"/>
  </interface>
</node>`;

const LogSentinelProxy = Gio.DBusProxy.makeProxyWrapper(LogSentinelIface);

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
                console.log(`[Log Sentinel] Found terminal: ${terminal.name}`);
                return terminal.cmd;
            }
        } catch (e) {
            // Terminal not found, continue
        }
    }

    console.log('[Log Sentinel] No terminal found, defaulting to xterm');
    return 'xterm -e';
}

const Indicator = GObject.registerClass(
class Indicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Log Sentinel');

        // Detect available terminal
        this._terminalCmd = findAvailableTerminal();

        // D-Bus proxy
        this._proxy = null;

        // Top bar icon
        this._icon = new St.Icon({
            icon_name: 'security-high-symbolic',
            style_class: 'system-status-icon',
        });

        // Badge for critical count
        this._badge = new St.Label({
            text: '',
            style_class: 'log-sentinel-badge',
            visible: false,
        });

        let box = new St.BoxLayout();
        box.add_child(this._icon);
        box.add_child(this._badge);
        this.add_child(box);

        // Menu sections
        this._guardianSection = new PopupMenu.PopupMenuSection();
        this._ebpfSection = new PopupMenu.PopupMenuSection();
        this._serviceSection = new PopupMenu.PopupMenuSection();
        this._summaryLabel = new St.Label({ text: 'Loading...' });

        // Build menu
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('Security Monitor'));

        let summaryItem = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        summaryItem.actor.add_child(this._summaryLabel);
        this.menu.addMenuItem(summaryItem);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('🛡️ Guardian Shield'));
        this.menu.addMenuItem(this._guardianSection);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('🔍 eBPF Events'));
        this.menu.addMenuItem(this._ebpfSection);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('⚙️ Services'));
        this.menu.addMenuItem(this._serviceSection);

        // View in Logs section
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('📖 View Logs'));

        let logsAppItem = new PopupMenu.PopupMenuItem('All Logs (GNOME Logs)');
        logsAppItem.connect('activate', () => this._openLogsApp());
        this.menu.addMenuItem(logsAppItem);

        let guardianLogsItem = new PopupMenu.PopupMenuItem('Guardian Shield Logs');
        guardianLogsItem.connect('activate', () => this._openTerminalLogs('guardian'));
        this.menu.addMenuItem(guardianLogsItem);

        let ebpfLogsItem = new PopupMenu.PopupMenuItem('eBPF/Deletion Logs');
        ebpfLogsItem.connect('activate', () => this._openTerminalLogs('ebpf'));
        this.menu.addMenuItem(ebpfLogsItem);

        let serviceLogsItem = new PopupMenu.PopupMenuItem('Service Failure Logs');
        serviceLogsItem.connect('activate', () => this._openTerminalLogs('service'));
        this.menu.addMenuItem(serviceLogsItem);

        let fullJournalItem = new PopupMenu.PopupMenuItem('Full Journal (Terminal)');
        fullJournalItem.connect('activate', () => this._openTerminalLogs('all'));
        this.menu.addMenuItem(fullJournalItem);

        // Boot & System Analysis
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem('🚀 Boot & System Analysis'));

        let bootAnalysisItem = new PopupMenu.PopupMenuItem('Boot Performance Analysis');
        bootAnalysisItem.connect('activate', () => this._openBootScript('boot-analysis'));
        this.menu.addMenuItem(bootAnalysisItem);

        let bootErrorsItem = new PopupMenu.PopupMenuItem('Boot Errors & Warnings');
        bootErrorsItem.connect('activate', () => this._openBootScript('boot-errors'));
        this.menu.addMenuItem(bootErrorsItem);

        let kernelMessagesItem = new PopupMenu.PopupMenuItem('Kernel Boot Messages');
        kernelMessagesItem.connect('activate', () => this._openBootScript('kernel-boot-messages'));
        this.menu.addMenuItem(kernelMessagesItem);

        let shutdownLogsItem = new PopupMenu.PopupMenuItem('Shutdown Logs');
        shutdownLogsItem.connect('activate', () => this._openBootScript('shutdown-logs'));
        this.menu.addMenuItem(shutdownLogsItem);

        let allBootLogsItem = new PopupMenu.PopupMenuItem('All Boot Logs');
        allBootLogsItem.connect('activate', () => this._openBootScript('boot-logs'));
        this.menu.addMenuItem(allBootLogsItem);

        // Action buttons
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        let refreshItem = new PopupMenu.PopupMenuItem('🔄 Refresh');
        refreshItem.connect('activate', () => this._refresh());
        this.menu.addMenuItem(refreshItem);

        let clearItem = new PopupMenu.PopupMenuItem('🗑️ Clear Events');
        clearItem.connect('activate', () => this._clearEvents());
        this.menu.addMenuItem(clearItem);

        // Initialize D-Bus connection
        this._initDBus();

        // Auto-refresh
        this._timeout = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, REFRESH_INTERVAL, () => {
            this._refresh();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _initDBus() {
        try {
            this._proxy = new LogSentinelProxy(
                Gio.DBus.session,
                DBUS_NAME,
                DBUS_PATH,
                (proxy, error) => {
                    if (error) {
                        console.error('[Log Sentinel] D-Bus connection error:', error.message);
                        this._showError('Daemon not running');
                        return;
                    }
                    console.log('[Log Sentinel] Connected to daemon');
                    this._refresh();
                }
            );
        } catch (e) {
            console.error('[Log Sentinel] Failed to create D-Bus proxy:', e.message);
            this._showError('D-Bus error');
        }
    }

    _refresh() {
        if (!this._proxy) {
            this._showError('Not connected');
            return;
        }

        try {
            // Get summary
            this._proxy.GetSummaryRemote((result, error) => {
                if (error) {
                    console.error('[Log Sentinel] GetSummary error:', error.message);
                    return;
                }

                try {
                    const summary = JSON.parse(result[0]);
                    this._updateSummary(summary);
                } catch (e) {
                    console.error('[Log Sentinel] Parse error:', e.message);
                }
            });

            // Get events by category
            this._proxy.GetEventsByCategoryRemote('guardian', (result, error) => {
                if (!error) {
                    try {
                        const events = JSON.parse(result[0]);
                        this._updateSection(this._guardianSection, events);
                    } catch (e) {
                        console.error('[Log Sentinel] Parse guardian events:', e.message);
                    }
                }
            });

            this._proxy.GetEventsByCategoryRemote('ebpf', (result, error) => {
                if (!error) {
                    try {
                        const events = JSON.parse(result[0]);
                        this._updateSection(this._ebpfSection, events);
                    } catch (e) {
                        console.error('[Log Sentinel] Parse ebpf events:', e.message);
                    }
                }
            });

            this._proxy.GetEventsByCategoryRemote('service', (result, error) => {
                if (!error) {
                    try {
                        const events = JSON.parse(result[0]);
                        this._updateSection(this._serviceSection, events);
                    } catch (e) {
                        console.error('[Log Sentinel] Parse service events:', e.message);
                    }
                }
            });
        } catch (e) {
            console.error('[Log Sentinel] Refresh error:', e.message);
        }
    }

    _updateSummary(summary) {
        // Update badge
        const critical = summary.critical || 0;
        const guardianBlocks = summary.guardian_blocks || 0;

        if (critical > 0 || guardianBlocks > 0) {
            this._badge.text = (critical + guardianBlocks).toString();
            this._badge.visible = true;
            this._icon.icon_name = 'security-low-symbolic';
        } else {
            this._badge.visible = false;
            this._icon.icon_name = 'security-high-symbolic';
        }

        // Update summary text
        const parts = [];
        if (guardianBlocks > 0) parts.push(`🛡️ ${guardianBlocks} blocked`);
        if (summary.ebpf_deletions > 0) parts.push(`🔍 ${summary.ebpf_deletions} deletions`);
        if (summary.errors > 0) parts.push(`⚠️ ${summary.errors} errors`);

        this._summaryLabel.text = parts.length > 0 ? parts.join(' | ') : 'No events';
    }

    _updateSection(section, events) {
        section.removeAll();

        if (events.length === 0) {
            let item = new PopupMenu.PopupMenuItem('No events');
            item.actor.reactive = false;
            section.addMenuItem(item);
            return;
        }

        // Show last 5 events
        events.slice(-5).reverse().forEach(event => {
            let text = `${event.process}: ${event.message}`;
            if (event.details) {
                text += `\n  ${event.details}`;
            }
            let item = new PopupMenu.PopupMenuItem(text);
            item.actor.reactive = false;
            section.addMenuItem(item);
        });
    }

    _clearEvents() {
        if (!this._proxy) return;

        try {
            this._proxy.ClearEventsRemote((result, error) => {
                if (error) {
                    console.error('[Log Sentinel] Clear error:', error.message);
                    return;
                }
                this._refresh();
            });
        } catch (e) {
            console.error('[Log Sentinel] Clear events error:', e.message);
        }
    }

    _showError(message) {
        this._summaryLabel.text = `Error: ${message}`;
        this._icon.icon_name = 'dialog-error-symbolic';
        this._badge.visible = false;
    }

    _openLogsApp() {
        try {
            GLib.spawn_command_line_async('gnome-logs');
            console.log('[Log Sentinel] Opened GNOME Logs');
        } catch (e) {
            console.error('[Log Sentinel] Failed to open Logs app:', e.message);
        }
    }

    _openTerminalLogs(category) {
        try {
            let command = '';

            switch (category) {
                case 'guardian':
                    command = `${this._terminalCmd} journalctl -f -g 'libwarden|BLOCKED|Guardian'`;
                    break;
                case 'ebpf':
                    command = `${this._terminalCmd} journalctl -f -g 'FILE_DELETE|unlinked'`;
                    break;
                case 'service':
                    command = `${this._terminalCmd} journalctl -f -p err`;
                    break;
                case 'all':
                    command = `${this._terminalCmd} journalctl -f`;
                    break;
            }

            console.log('[Log Sentinel] Running:', command);
            GLib.spawn_command_line_async(command);
        } catch (e) {
            console.error('[Log Sentinel] Failed to open terminal logs:', e.message);
        }
    }

    _openBootScript(scriptName) {
        try {
            let actualCommand = '';

            switch (scriptName) {
                case 'boot-analysis':
                    actualCommand = 'journalctl -b -p info --no-pager | tail -100';
                    break;
                case 'boot-errors':
                    actualCommand = 'journalctl -b -p err --no-pager';
                    break;
                case 'kernel-boot-messages':
                    actualCommand = 'journalctl -b -k --no-pager';
                    break;
                case 'shutdown-logs':
                    actualCommand = 'journalctl -b -1 --no-pager | tail -100';
                    break;
                case 'boot-logs':
                    actualCommand = 'journalctl -b --no-pager | tail -200';
                    break;
                default:
                    actualCommand = scriptName;
            }

            let command = `${this._terminalCmd} bash -c '${actualCommand}; echo ""; echo "Press Enter to close..."; read'`;
            console.log('[Log Sentinel] Running boot script:', actualCommand);
            GLib.spawn_command_line_async(command);
        } catch (e) {
            console.error('[Log Sentinel] Failed to open boot script:', e.message);
        }
    }

    destroy() {
        if (this._timeout) {
            GLib.source_remove(this._timeout);
            this._timeout = null;
        }
        super.destroy();
    }
});

export default class Extension {
    constructor() {
        this._indicator = null;
    }

    enable() {
        this._indicator = new Indicator();
        Main.panel.addToStatusArea('log-sentinel-v2', this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
