import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import St from 'gi://St';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import Clutter from 'gi://Clutter';
import Pango from 'gi://Pango';
import { PopupBaseMenuItem, Ornament, PopupSubMenuMenuItem, PopupSeparatorMenuItem, PopupMenuSection, PopupMenu } from 'resource:///org/gnome/shell/ui/popupMenu.js';
import { SystemIndicator, QuickMenuToggle } from 'resource:///org/gnome/shell/ui/quickSettings.js';

const assert = (condition, errorMessage) => {
    if (condition)
        return;
    logError(errorMessage);
    throw new Error(errorMessage);
};
class ConsoleUtil extends GObject.Object {
    static {
        GObject.registerClass(ConsoleUtil);
    }
    _command;
    constructor(...args) {
        super();
        assert(!!args[0], 'Util not defined');
        assert(!!GLib.find_program_in_path(args[0]), `Util ${args[0]} not found`);
        this._command = ConsoleUtil.args(args.join(' '));
        if (this.available &&
            'update' in this &&
            typeof this.update === 'function') {
            this.update();
        }
    }
    run(argv, condition, errorMessage) {
        assert(condition, errorMessage);
        return new Promise((resolve, reject) => {
            const proc = Gio.Subprocess.new(argv, Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
            proc.communicate_utf8_async(null, null, (proc, res) => {
                try {
                    if (!proc)
                        throw new Error('Util subprocess error');
                    const [, stdout, stderr] = proc.communicate_utf8_finish(res);
                    if (!proc.get_successful())
                        throw new Error(stderr);
                    resolve(stdout);
                }
                catch (e) {
                    reject(e);
                }
            });
        });
    }
    async execute(callback) {
        try {
            return callback(await this.run(this._command, this.available, `Util ${this._command[0]} not available`));
        }
        catch (e) {
            logError(e);
        }
    }
    get available() {
        return this._command.length > 0;
    }
    static args(cmd) {
        if (typeof cmd !== 'string')
            return cmd;
        const [ok, argv] = GLib.shell_parse_argv(cmd);
        assert(ok && !!argv, `Unable to parse ${cmd} as argument vector`);
        return argv;
    }
    static celsius(c, round) {
        return `${round ? Math.round(c) : c} °C`;
    }
    static fahrenheit(c, round) {
        const value = (c * 9) / 5 + 32;
        return `${round ? Math.round(value) : value} °F`;
    }
    static temperature(c, unit, round) {
        return unit === 'celsius'
            ? ConsoleUtil.celsius(c, round)
            : ConsoleUtil.fahrenheit(c, round);
    }
    static revs(n) {
        return `${n} RPM`;
    }
}

class LsnvmeUtil extends ConsoleUtil {
    static {
        GObject.registerClass(LsnvmeUtil);
    }
    data = {};
    constructor() {
        super('ls', '-l', '/dev/disk/by-path');
    }
    static IS = {
        NVME: /nvme/i,
        PART: /part/i,
    };
    parse(str) {
        this.data = str
            .split('\n')
            .filter((l) => !LsnvmeUtil.IS.PART.test(l))
            .filter((l) => LsnvmeUtil.IS.NVME.test(l))
            .map((l) => l.slice(l.indexOf('pci-')))
            .map((l) => l.replace(/(\.\.\/)/gim, '').split('->'))
            .map(([a, b]) => [
            b.trim(),
            ['nvme', 'pci', a.slice(9, 14).replace(/[:.]/gim, '')].join('-'),
        ])
            .reduce((acc, [path, name]) => {
            acc[path] = name;
            return acc;
        }, {});
    }
    update() {
        return super.execute(this.parse.bind(this));
    }
    name(key) {
        return this.data[key] ?? key;
    }
}
class LsblkUtil extends ConsoleUtil {
    static {
        GObject.registerClass(LsblkUtil);
    }
    _lsnvme = new LsnvmeUtil();
    data = {};
    constructor() {
        super('lsblk', '-o', 'HCTL,MODEL,NAME,TRAN', '-dnJ');
    }
    parse(str) {
        const { blockdevices } = JSON.parse(str);
        this.data = blockdevices.reduce((acc, { hctl, model, name, tran }) => {
            if (hctl) {
                const key = [
                    'drivetemp',
                    'scsi',
                    ...hctl.split(':').slice(0, 2),
                ].join('-');
                acc[key] = model;
                return acc;
            }
            if (tran === 'nvme') {
                const key = this._lsnvme.name(name);
                acc[key] = model;
                return acc;
            }
            return acc;
        }, {});
    }
    update() {
        return super.execute(this.parse.bind(this));
    }
    name(key) {
        if (!this.data[key]) {
            this.update();
            this._lsnvme.update();
        }
        return this.data[key] ?? key;
    }
}

class LscpuUtil extends ConsoleUtil {
    static {
        GObject.registerClass(LscpuUtil);
    }
    _data = {};
    constructor() {
        super('lscpu', '-e=MODELNAME,SOCKET', '-J');
    }
    extractModel(modelName) {
        if (modelName.toLowerCase().includes('intel')) {
            return (modelName
                .split('@')[0]
                .replace('CPU', '')
                .replace(/\(R\)/g, '®')
                .replace(/\(TM\)/g, '™')
                .trim() || 'Intel CPU');
        }
        if (modelName.toLowerCase().includes('amd')) {
            return (modelName
                .split('with')[0]
                .split(/\s+\d+-Core/)[0]
                .split(/\s+[A-Za-z]+-Core/)[0]
                .trim() || 'AMD CPU');
        }
        return 'Processor';
    }
    parse(str) {
        const { cpus } = JSON.parse(str);
        this._data = Object.values(cpus).reduce((acc, curr) => {
            let key = curr.socket.toString().padStart(4, '0');
            key = `coretemp-isa-${key}`;
            acc[key] = this.extractModel(curr.modelname);
            return acc;
        }, {});
        return this._data;
    }
    update() {
        return super.execute(this.parse.bind(this));
    }
    name(key) {
        return this._data[key] ?? key;
    }
}

class SensorsUtil extends ConsoleUtil {
    static {
        GObject.registerClass({
            Signals: {
                updated: {
                    param_types: [GObject.TYPE_JSOBJECT],
                },
            },
        }, SensorsUtil);
    }
    static NOTIFY = ['cpu', 'hdd', 'fan', 'other'];
    static IS = {
        INPUT: /_input$/,
        FANS: /^fan/i,
        CPU: /^coretemp/i,
        DRIVETEMP: /^drivetemp/i,
        NVME: /^nvme/i,
        TPISA: /^thinkpad-isa/i,
        BATTERIES: /^bat/i,
        POWER: /_psy_/i,
    };
    _lscpu;
    _lsblk;
    data = {};
    config;
    constructor(config) {
        super('sensors', '-A', '-j');
        this._lscpu = new LscpuUtil();
        this._lsblk = new LsblkUtil();
        this.update(config);
    }
    parse(str) {
        const obj = typeof str === 'string' ? JSON.parse(str) : str;
        const keys = Object.keys(obj);
        if (keys.length === 0)
            return obj;
        if (keys.length === 1)
            return this.parse(Object.values(obj)[0]);
        const input = keys.find((k) => SensorsUtil.IS.INPUT.test(k));
        if (input)
            return this.parse(obj[input]);
        return keys.reduce((acc, key) => {
            acc[key] = this.parse(obj[key]);
            return acc;
        }, {});
    }
    async update(config) {
        this.config = {
            ...this.config,
            ...config,
        };
        try {
            this.data = await super.execute(this.parse.bind(this));
            const obj = SensorsUtil.NOTIFY.reduce((acc, key) => {
                acc[key] = this[key];
                return acc;
            }, {});
            this.emit('updated', obj);
        }
        catch (error) {
            logError(error);
        }
    }
    select(f, r, key) {
        return Object.keys(key ? this.data[key] : this.data)
            .filter(f)
            .reduce(r, {});
    }
    get cpu() {
        return this.select((k) => SensorsUtil.IS.CPU.test(k), (acc, k) => {
            const name = this._lscpu.name(k);
            const value = { ...this.data[k] };
            for (const key of Object.keys(value)) {
                value[key] = ConsoleUtil.temperature(value[key], this.config.temperatureUnit);
            }
            acc[name] = value;
            return acc;
        });
    }
    get hdd() {
        return this.select((k) => SensorsUtil.IS.DRIVETEMP.test(k) || SensorsUtil.IS.NVME.test(k), (acc, k) => {
            const name = this._lsblk.name(k);
            let value = this.data[k];
            if (typeof value === 'object') {
                value = Math.max(...Object.values(value));
            }
            acc[name] = ConsoleUtil.temperature(value, this.config.temperatureUnit);
            return acc;
        });
    }
    get bat() {
        return this.select((k) => SensorsUtil.IS.BATTERIES.test(k), (acc, k) => {
            acc[k] = this.data[k];
            return acc;
        });
    }
    get fan() {
        const key = Object.keys(this.data).find((k) => SensorsUtil.IS.TPISA.test(k));
        return this.select((k) => SensorsUtil.IS.FANS.test(k), (acc, k) => {
            acc[k] = ConsoleUtil.revs(this.data[key][k]);
            return acc;
        }, key);
    }
    get other() {
        return this.select((k) => Object.keys(SensorsUtil.IS).every((check) => !SensorsUtil.IS[check].test(k)), (acc, k) => {
            const value = this.data[k];
            acc[k] = ConsoleUtil.temperature(value, this.config.temperatureUnit);
            return acc;
        });
    }
}

const richTypes = { Date: true, RegExp: true, String: true, Number: true };
function diff(obj, newObj, options = { cyclesFix: true }, _stack = []) {
    let diffs = [];
    const isObjArray = Array.isArray(obj);
    for (const key in obj) {
        const objKey = obj[key];
        const path = isObjArray ? +key : key;
        if (!(key in newObj)) {
            diffs.push({
                type: 'REMOVE',
                path: [path],
                oldValue: obj[key],
            });
            continue;
        }
        const newObjKey = newObj[key];
        const areCompatibleObjects = typeof objKey === 'object' &&
            typeof newObjKey === 'object' &&
            Array.isArray(objKey) === Array.isArray(newObjKey);
        if (objKey &&
            newObjKey &&
            areCompatibleObjects &&
            !richTypes[Object.getPrototypeOf(objKey)?.constructor?.name] &&
            (!options.cyclesFix || !_stack.includes(objKey))) {
            diffs.push.apply(diffs, diff(objKey, newObjKey, options, options.cyclesFix ? _stack.concat([objKey]) : []).map((difference) => {
                difference.path.unshift(path);
                return difference;
            }));
        }
        else if (objKey !== newObjKey &&
            !(Number.isNaN(objKey) && Number.isNaN(newObjKey)) &&
            !(areCompatibleObjects &&
                (isNaN(objKey)
                    ? objKey + '' === newObjKey + ''
                    : +objKey === +newObjKey))) {
            diffs.push({
                path: [path],
                type: 'CHANGE',
                value: newObjKey,
                oldValue: objKey,
            });
        }
    }
    const isNewObjArray = Array.isArray(newObj);
    for (const key in newObj) {
        if (!(key in obj)) {
            diffs.push({
                type: 'CREATE',
                path: [isNewObjArray ? +key : key],
                value: newObj[key],
            });
        }
    }
    return diffs;
}

class IbmAcpiUtil extends ConsoleUtil {
    static {
        GObject.registerClass({
            Properties: {
                cpu: GObject.ParamSpec.string('cpu', 'CPU temperature', 'Current CPU temperature', GObject.ParamFlags.READABLE, '...'),
                gpu: GObject.ParamSpec.string('gpu', 'GPU temperature', 'Current GPU temperature', GObject.ParamFlags.READABLE, '...'),
                speed: GObject.ParamSpec.string('speed', 'Fan speed', 'Current fan speed', GObject.ParamFlags.READABLE, '...'),
                status: GObject.ParamSpec.string('status', 'Fan status', 'Current fan status', GObject.ParamFlags.READABLE, '...'),
                level: GObject.ParamSpec.string('level', 'Fan level', 'Current fan level', GObject.ParamFlags.READABLE, '...'),
            },
            Signals: {
                updated: {
                    param_types: [GObject.TYPE_JSOBJECT, GObject.TYPE_JSOBJECT],
                },
            },
        }, IbmAcpiUtil);
    }
    data = {
        cpu: 0,
        gpu: 0,
        status: 'disabled',
        speed: 0,
        level: 'auto',
        levels: [],
    };
    prev = {};
    config;
    constructor(config) {
        super('cat', '/proc/acpi/ibm/thermal', '/proc/acpi/ibm/fan');
        this.update(config);
    }
    parse(str) {
        const [temps, status, speed, level, cmd1] = str
            .split('\n')
            .map((r) => r.slice(r.lastIndexOf('\t') + 1));
        let [cpu, gpu] = temps
            .split(' ')
            .map((s) => Number.parseInt(s));
        if (gpu <= 0 && 'gpu' in this.prev && this.prev.gpu > 0) {
            gpu = this.prev.gpu;
        }
        let levels = this.data.levels;
        if (status === 'enabled' &&
            cmd1.includes('<level>') &&
            levels?.length === 0) {
            const [range, ...rest] = cmd1
                .slice(cmd1.indexOf('> is ') + 5, -1)
                .split(', ');
            const [, to] = range
                .split('-')
                .map((s) => Number.parseInt(s));
            const nums = Array.from(Array(to + 1), (_, i) => i);
            levels = [rest[0], ...nums, ...rest.slice(1)]
                .filter((l) => !IbmAcpiUtil.DISABLED_LEVELS.includes(l))
                .map(String);
        }
        return {
            cpu,
            gpu,
            status,
            speed: Number.parseInt(speed),
            level,
            levels,
        };
    }
    async update(config) {
        if (config) {
            this.config = {
                ...(this.config || {}),
                ...config,
            };
        }
        if (config && Object.keys(this.prev).length > 0) {
            for (const k of IbmAcpiUtil.NOTIFY)
                this.notify(k);
            const diffs = IbmAcpiUtil.NOTIFY.map((k) => ({
                type: 'CHANGE',
                path: [k],
                value: this[k],
                oldValue: '*',
            }));
            this.emit('updated', IbmAcpiUtil.NOTIFY, diffs);
            return;
        }
        try {
            this.data = await super.execute(this.parse.bind(this));
            const diff$1 = diff(this.prev, this.data);
            this.prev = this.data;
            if (diff$1.length === 0)
                return;
            const keys = diff$1
                .flatMap(({ path }) => path)
                .filter(IbmAcpiUtil.isNotifiable);
            for (const k of keys)
                this.notify(k);
            this.emit('updated', keys, diff$1);
        }
        catch (e) {
            logError(e);
        }
    }
    setLevel(next) {
        this.run(ConsoleUtil.args(`pkexec sh -c "echo level ${next} | tee /proc/acpi/ibm/fan"`), this.data.levels.includes(next), `Invalid level: ${next}. Available levels: ${this.data.levels.join(', ')}`);
    }
    static NOTIFY = ['cpu', 'gpu', 'speed', 'level', 'status'];
    static CHECKS = [-128, 0];
    static DISABLED_LEVELS = [0, 'disengaged'];
    static isNotifiable = (key) => IbmAcpiUtil.NOTIFY.includes(key);
    static isValidSensor = (v) => IbmAcpiUtil.CHECKS.every((check) => check !== v);
    get cpu() {
        return ConsoleUtil.temperature(this.data.cpu, this.config.temperatureUnit, true);
    }
    get gpu() {
        return ConsoleUtil.temperature(this.data.gpu, this.config.temperatureUnit, true);
    }
    get status() {
        return this.data.status;
    }
    get speed() {
        return ConsoleUtil.revs(this.data.speed);
    }
    get level() {
        if (this.data.level === 'disengaged' && this.data.speed > 0) {
            return 'full-speed';
        }
        return this.data.level;
    }
    get levels() {
        return this.data.levels;
    }
    get hasDedicatedGpu() {
        return IbmAcpiUtil.isValidSensor(this.data.gpu);
    }
    get isControllable() {
        return this.data.status === 'enabled' && this.data.levels.length > 0;
    }
}

class DmiUtil extends ConsoleUtil {
    static {
        GObject.registerClass({
            Signals: {
                updated: {
                    param_types: [GObject.TYPE_JSOBJECT],
                },
            },
        }, DmiUtil);
    }
    constructor() {
        super('cat', ...DmiUtil.TAGS.map((tag) => `/sys/devices/virtual/dmi/id/${tag}`));
    }
    static TAGS = [
        'bios_date',
        'bios_release',
        'bios_version',
        'ec_firmware_release',
        'product_name',
        'product_version',
        'sys_vendor',
    ];
    data;
    parse(str) {
        const values = str.split('\n');
        this.data = DmiUtil.TAGS.reduce((acc, curr, i) => {
            acc[curr] = (values[i] ?? '')
                .replace(/\(\s+/g, '(')
                .replace(/\s+\)/g, ')')
                .trim();
            return acc;
        }, {});
        this.emit('updated', this.dmi);
    }
    get dmi() {
        if (!this.data)
            return {};
        return {
            [this.data.product_version]: {
                [this.data.sys_vendor]: this.data.product_name,
                BIOS: this.data.bios_version,
                Date: this.data.bios_date,
                Release: this.data.bios_release,
                'EC firmware': this.data.ec_firmware_release,
            },
        };
    }
    update() {
        return super.execute(this.parse.bind(this));
    }
}

class ThermalData {
    _interval;
    config;
    acpi;
    dmi;
    sensors;
    constructor(settings) {
        this.config = {
            checkInterval: settings.get_int('check-interval'),
            temperatureUnit: settings.get_string('temperature-unit'),
        };
        this.dmi = new DmiUtil();
        this.acpi = new IbmAcpiUtil(this.config);
        this.sensors = new SensorsUtil(this.config);
        settings.connect('changed::check-interval', () => {
            this.config.checkInterval = settings.get_int('check-interval');
            this.startInterval();
        });
        settings.connect('changed::temperature-unit', () => {
            this.config.temperatureUnit = settings.get_string('temperature-unit');
            this.acpi.update(this.config);
            this.sensors.update(this.config);
        });
        this.startInterval();
    }
    startInterval() {
        if (this._interval)
            GLib.source_remove(this._interval);
        this._interval = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, this.config.checkInterval, this.fetchData.bind(this));
    }
    fetchData() {
        this.acpi.update();
        this.sensors.update();
        return GLib.SOURCE_CONTINUE;
    }
    destroy() {
        if (this._interval) {
            GLib.source_remove(this._interval);
            this._interval = null;
        }
    }
}

class ButtonSection extends St.BoxLayout {
    static {
        GObject.registerClass(ButtonSection);
    }
    key;
    _icon;
    _value;
    _unit;
    constructor(key, text, icon) {
        super({ style_class: 'section' });
        this.key = key;
        this._icon = new Icon(icon ?? key);
        this._value = new Label('value', '');
        this._unit = new Label('unit', '');
        this.add_child(this._icon);
        this.add_child(this._value);
        this.add_child(this._unit);
        this.update(text);
    }
    update(text) {
        const [value, unit = ''] = text.split(' ');
        this._value.set_text(value);
        this._unit.set_text(unit);
    }
    toggleUnit(show) {
        this._unit.visible = show;
    }
}
class Label extends St.Label {
    static {
        GObject.registerClass(Label);
    }
    constructor(style_class, text = '') {
        super({
            text,
            style_class,
            y_align: Clutter.ActorAlign.CENTER,
        });
        this.clutter_text.set_ellipsize(Pango.EllipsizeMode.NONE);
    }
}
class Icon extends St.Icon {
    static {
        GObject.registerClass(Icon);
    }
    constructor(filename, style_class = 'icon', icon_size = 14) {
        super({
            icon_size,
            style_class,
            y_align: Clutter.ActorAlign.CENTER,
        });
        this.set_gicon(Icon.createIcon(filename));
    }
    static createIcon(filename) {
        if (!ME)
            return null;
        return new Gio.FileIcon({
            file: ME.dir.resolve_relative_path(`icons/${filename}-symbolic.svg`),
        });
    }
}
class Title extends PopupBaseMenuItem {
    static {
        GObject.registerClass(Title);
    }
    _text;
    constructor(text) {
        super({
            style_class: 'title',
            reactive: false,
        });
        this._text = new St.Label({
            text,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
            x_expand: true,
        });
        this.add_child(this._text);
    }
}
class Item extends PopupBaseMenuItem {
    static {
        GObject.registerClass(Item);
    }
    key;
    _label;
    _value;
    _icon;
    constructor(key, label, value, icon) {
        super({
            style_class: 'item',
            reactive: false,
        });
        this.key = key;
        if (icon) {
            this.setOrnament(Ornament.HIDDEN);
            this._icon = new Icon(icon, 'popup-menu-ornament');
            this.add_child(this._icon);
        }
        this._label = new St.Label({
            style_class: 'label',
            text: label,
            x_align: Clutter.ActorAlign.START,
            x_expand: false,
            reactive: false,
        });
        this._value = new St.Label({
            style_class: 'value',
            text: value,
            x_align: Clutter.ActorAlign.END,
            x_expand: true,
        });
        this.add_child(this._label);
        this.add_child(this._value);
    }
    set value(value) {
        this._value.set_text(value);
    }
    set label(label) {
        this._label.set_text(label);
    }
}
class Group extends PopupSubMenuMenuItem {
    static {
        GObject.registerClass(Group);
    }
    key;
    rename;
    constructor(key, label, value, icon, rename) {
        super(label, true);
        this.key = key;
        this.actor.y_expand = false;
        this.add_style_class_name('submenu');
        this.setOrnament(Ornament.HIDDEN);
        if ('icon' in this) {
            const i = this.icon;
            i.set_gicon(Icon.createIcon(icon ?? key));
        }
        if (typeof rename === 'function')
            this.rename = rename;
        for (const k of Object.keys(value)) {
            this.CREATE([k], value[k]);
        }
    }
    element(key) {
        return this.menu._getMenuItems().find((item) => item.key === key);
    }
    CREATE(path, value) {
        const key = path[0];
        const el = new Item(key, key, value);
        el.value = value;
        el.setOrnament(Ornament.HIDDEN);
        const curr = this.element(key);
        if (curr) {
            this.menu.actor.replace_child(curr, el);
        }
        else {
            this.menu.addMenuItem(el);
        }
    }
    CHANGE(path, value) {
        const key = path[0];
        const el = this.element(key);
        el.value = value;
        if (typeof this.rename === 'function' && el.label === key) {
            el.label = this.rename(key);
        }
    }
    REMOVE(path) {
        const key = path[0];
        this.element(key).destroy();
    }
    update(diffs) {
        for (const { type, path, value } of diffs) {
            this[type](path, value);
        }
    }
}
class Groups extends PopupMenuSection {
    key;
    icon;
    constructor(key, icon) {
        super();
        this.key = key;
        this.icon = icon ?? key;
        this.actor.y_expand = false;
    }
    element(key) {
        return this._getMenuItems().find((item) => item.key === key);
    }
    CREATE(path, value) {
        const key = path[0];
        this.addMenuItem(new Group(key, key, value, this.icon));
    }
    CHANGE(path, value) {
        const key = path[0];
        this.element(key).update([
            {
                type: 'CHANGE',
                path: path.slice(1),
                value,
                oldValue: 'unknown',
            },
        ]);
    }
    REMOVE(path) {
        const key = path[0];
        this.element(key).destroy();
    }
    update(diffs) {
        for (const { type, path, value } of diffs) {
            this[type](path, value);
        }
    }
}
class PopupSection extends PopupMenuSection {
    name = 'Section';
    constructor(name, data, createTitle = true) {
        super();
        this.name = name;
        this.actor.y_expand = false;
        if (createTitle)
            this.addMenuItem(new Title(name));
        data.connect('updated', (next) => this.sync(next));
    }
    get elements() {
        return this._getMenuItems()
            .filter((e) => e.key);
    }
    item(key) {
        return this.elements.find((e) => e.key === key);
    }
    sync(data) {
        for (const el of this.elements) {
            const { key, prev } = el;
            const value = data[key];
            if (prev === value)
                continue;
            if (typeof value === 'object' ||
                el instanceof Group ||
                el instanceof Groups) {
                const diffs = diff(prev ?? {}, value);
                if (diffs.length === 0)
                    continue;
                el.prev = value;
                if ('update' in el)
                    el.update(diffs);
                continue;
            }
            el.prev = value;
            el.value = value;
        }
    }
}
class QuickDropdown extends SystemIndicator {
    static {
        GObject.registerClass(QuickDropdown);
    }
    _quick;
    _icon;
    constructor(title, icon_name, items, current, onClick) {
        super();
        this._icon = Icon.createIcon(icon_name);
        this._quick = new QuickMenuToggle({
            title,
            subtitle: current ?? '...',
            gicon: this._icon,
            toggleMode: false,
        });
        this._quick.menu.setHeader(this._icon, title, current ?? '...');
        for (const s of items) {
            this._quick.menu.addAction(s, () => onClick(s));
        }
        this._quick.menu.addMenuItem(new PopupSeparatorMenuItem());
        this._quick.menu.addAction('Settings', () => ME?.openPreferences(), 'org.gnome.Settings-symbolic');
        this.quickSettingsItems.push(this._quick);
    }
    destroy() {
        this._quick?.destroy();
        this._quick = null;
        super.destroy();
    }
    status(current, header, subtitle) {
        if (!this._quick)
            return;
        this._quick.subtitle = current;
        this._quick.menu.setHeader(this._icon, header, subtitle);
        for (const item of this._quick.menu._getMenuItems()) {
            if (item instanceof PopupSeparatorMenuItem)
                break;
            item.setOrnament(Ornament.NONE);
            if (item.labelActor.text === current) {
                item.setOrnament(Ornament.CHECK);
            }
        }
    }
}

class ThermalButton extends PanelMenu.Button {
    static {
        GObject.registerClass(ThermalButton);
    }
    _data;
    layout = new St.BoxLayout({
        style_class: 'layout',
    });
    constructor(align, name, data, settings) {
        super(align, name);
        this._data = data;
        this.add_style_class_name('tpt-button');
        this.add_child(this.layout);
        this.addIndicator('cpu')();
        this.addIndicator('gpu')((el, next) => {
            if (next.hasDedicatedGpu) {
                el.show();
                el.update(next.gpu);
            }
            else {
                el.hide();
            }
        });
        this.addIndicator('speed', 'fan')((el, { speed }) => {
            el.add_style_class_name('text-only');
            if (speed === '0 RPM')
                return el.update('OFF');
            if (speed === '65535 RPM')
                return el.update('SPOOLING');
            el.remove_style_class_name('text-only');
            return el.update(speed);
        });
        this.toggleUnit(settings.get_boolean('show-indicator-unit'));
        settings.connect('changed::show-indicator-unit', () => {
            this.toggleUnit(settings.get_boolean('show-indicator-unit'));
        });
    }
    toggleUnit(showUnit) {
        for (const el of this.layout.get_children())
            el.toggleUnit(showUnit);
    }
    addIndicator(key, icon) {
        return (handler) => {
            const text = this._data[key];
            const child = new ButtonSection(key, text, icon);
            this.layout.add_child(child);
            const connectId = this._data.connect(`notify::${key}`, (next) => typeof handler === 'function'
                ? handler(child, next)
                : child.update(next[key]));
            child.connect('destroy', () => {
                this._data.disconnect(connectId);
            });
            return child;
        };
    }
}

class Dmi extends PopupSection {
    constructor(data) {
        super('Device info', data, false);
        this.addMenuItem(new Groups('dmi', 'thinkpad'));
    }
}
class Sensors extends PopupSection {
    constructor(data) {
        super('Sensors', data, false);
        this.addMenuItem(new Groups('cpu'));
        this.addMenuItem(new Group('hdd', 'Disks', data.hdd));
        this.addMenuItem(new Group('other', 'Thermal', data.other, 'sensor'));
        this.addMenuItem(new Group('fan', 'Cooling', data.fan));
    }
}
class Acpi extends PopupSection {
    constructor(data) {
        super('ACPI', data);
        this.addMenuItem(new Item('cpu', 'CPU', data.cpu, 'cpu'));
        this.addMenuItem(new Item('gpu', 'GPU', data.gpu, 'gpu'));
        data.connect('notify::gpu', (next) => {
            if (!next.hasDedicatedGpu) {
                this.item('gpu')?.hide();
            }
            else {
                this.item('gpu')?.show();
            }
        });
    }
}
class FanControl extends PopupSection {
    constructor(data) {
        super('Fan control', data);
        this.addMenuItem(new Item('status', 'Status', data.status));
        this.addMenuItem(new Item('speed', 'Speed', data.speed));
        this.addMenuItem(new Item('level', 'Level', data.level));
    }
}
class ThermalPopup extends PopupMenu {
    _dd;
    constructor(align, actor, { acpi, dmi, sensors }) {
        super(actor, align, St.Side.TOP);
        this.actor.add_style_class_name('tpt-popup');
        this.addMenuItem(new Dmi(dmi));
        this.addMenuItem(new Sensors(sensors));
        this.addMenuItem(new Acpi(acpi));
        this.addMenuItem(new FanControl(acpi));
        acpi.connect('notify::status', (data) => {
            if (!data.isControllable) {
                this._dd?.destroy();
                this._dd = null;
                return;
            }
            if (this._dd)
                return;
            this._dd = new QuickDropdown('Fan Level', 'fan', data.levels, data.level, (next) => data.setLevel(next));
            Main.panel.statusArea.quickSettings
                .addExternalIndicator(this._dd);
        });
        acpi.connect('notify::level', (data) => {
            this._dd?.status(data.level, 'ThinkPad Fan Control', `Current level is: ${data.level}`);
        });
    }
    destroy() {
        this._dd?.destroy();
        this._dd = null;
        super.destroy();
    }
}

let ME;
class ThinkPadThermal extends Extension {
    _settings;
    _data;
    _indicator;
    enable() {
        ME = this;
        this._settings = this.getSettings();
        this._data = new ThermalData(this._settings);
        this._indicator = new ThermalButton(0.5, 'ThinkPad Thermal', this._data.acpi, this._settings);
        this._indicator.setMenu(new ThermalPopup(0.5, this._indicator, this._data));
        Main.panel.addToStatusArea(this.uuid, this._indicator, this._position, this._area);
        this._settings.connect('changed', (_, change) => {
            if (change.startsWith('position-'))
                this.reposition();
        });
    }
    get _position() {
        return this._settings.get_boolean('position-enable')
            ? this._settings.get_int('position-index')
            : 0;
    }
    get _area() {
        return this._settings.get_boolean('position-enable')
            ? this._settings.get_string('position-area')
            : 'right';
    }
    get _box() {
        return Main.panel.get_child_at_index(['left', 'center', 'right'].indexOf(this._area));
    }
    reposition() {
        if (!this._settings.get_boolean('position-enable'))
            return;
        Main.panel._addToPanelBox(this.uuid, this._indicator, this._position, this._box);
    }
    disable() {
        this._indicator?.destroy();
        this._data?.destroy();
        this._indicator = null;
        this._data = null;
        ME = null;
    }
}

export { ME, ThinkPadThermal as default };
