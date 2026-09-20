import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const COMMAND = GLib.build_filenamev([GLib.get_home_dir(), '.local', 'bin', 'ai-usage-status']);
const INTERVAL_SECONDS = 60;

export default class UsageBarExtension extends Extension {
    enable() {
        this._button = new PanelMenu.Button(0.5, 'AI Usage Bar');
        this._label = new St.Label({text: '…', y_align: Clutter.ActorAlign.CENTER});
        this._button.add_child(this._label);
        this._button.menu.connect('open-state-changed', (_m, open) => open && this._refresh());
        Main.panel.addToStatusArea(this.uuid, this._button, 0, 'right');

        this._refresh();
        this._timerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, INTERVAL_SECONDS, () => {
            this._refresh();
            return GLib.SOURCE_CONTINUE;
        });
    }

    disable() {
        if (this._timerId) {
            GLib.source_remove(this._timerId);
            this._timerId = 0;
        }
        this._cancellable?.cancel();
        this._cancellable = null;
        this._button?.destroy();
        this._button = null;
        this._label = null;
    }

    _refresh() {
        this._cancellable?.cancel();
        this._cancellable = new Gio.Cancellable();
        let proc;
        try {
            proc = Gio.Subprocess.new([COMMAND],
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
        } catch (e) {
            this._show('AI usage: n/a', [`${COMMAND} を実行できません`]);
            return;
        }
        proc.communicate_utf8_async(null, this._cancellable, (p, res) => {
            try {
                const [, stdout] = p.communicate_utf8_finish(res);
                const lines = (stdout ?? '').trim().split('\n');
                this._show(lines[0] || 'AI usage: n/a', lines.slice(1));
            } catch (e) {
                if (!e.matches?.(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                    this._show('AI usage: n/a', [String(e)]);
            }
        });
    }

    _show(text, details) {
        if (!this._label)
            return;
        this._label.text = text;
        this._button.menu.removeAll();
        for (const line of details) {
            const item = new PopupMenu.PopupMenuItem(line, {reactive: false});
            this._button.menu.addMenuItem(item);
        }
    }
}
