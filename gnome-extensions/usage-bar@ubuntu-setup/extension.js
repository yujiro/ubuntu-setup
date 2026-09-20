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

// Intel GPU: RC6 (GPU の深いアイドル状態) に居た時間の累計。root 不要で読める。
// 稼働率 = 1 - (RC6 に居た時間の増分 / 経過時間)。/proc/*/fdinfo の drm-engine-render 集計とほぼ一致する(実測)。
const GPU_RC6_FILES = [
    '/sys/class/drm/card0/gt/gt0/rc6_residency_ms',
    '/sys/class/drm/card1/gt/gt0/rc6_residency_ms',
];
const GPU_INTERVAL_SECONDS = 3;

export default class UsageBarExtension extends Extension {
    enable() {
        this._button = new PanelMenu.Button(0.5, 'AI Usage Bar');
        const box = new St.BoxLayout();
        this._gpuLabel = new St.Label({text: '', y_align: Clutter.ActorAlign.CENTER, style: 'margin-right: 10px;'});
        this._label = new St.Label({text: '…', y_align: Clutter.ActorAlign.CENTER});
        box.add_child(this._gpuLabel);
        box.add_child(this._label);
        this._button.add_child(box);
        this._button.menu.connect('open-state-changed', (_m, open) => open && this._refresh());
        Main.panel.addToStatusArea(this.uuid, this._button, 0, 'right');

        this._gpuFile = GPU_RC6_FILES.find(f => GLib.file_test(f, GLib.FileTest.EXISTS)) ?? null;
        if (this._gpuFile) {
            this._refreshGpu();
            this._gpuTimerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, GPU_INTERVAL_SECONDS, () => {
                this._refreshGpu();
                return GLib.SOURCE_CONTINUE;
            });
        }

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
        if (this._gpuTimerId) {
            GLib.source_remove(this._gpuTimerId);
            this._gpuTimerId = 0;
        }
        this._cancellable?.cancel();
        this._cancellable = null;
        this._button?.destroy();
        this._button = null;
        this._label = null;
        this._gpuLabel = null;
        this._gpuPrev = null;
    }

    _refreshGpu() {
        if (!this._gpuLabel)
            return;
        try {
            const [ok, bytes] = GLib.file_get_contents(this._gpuFile);
            if (!ok)
                return;
            const rc6 = parseInt(new TextDecoder().decode(bytes).trim());
            const now = GLib.get_monotonic_time() / 1000;   // ms
            if (this._gpuPrev && now > this._gpuPrev.now) {
                const idle = (rc6 - this._gpuPrev.rc6) / (now - this._gpuPrev.now);
                const busy = Math.round(100 * Math.min(1, Math.max(0, 1 - idle)));
                this._gpuLabel.text = `GPU ${busy}%`;
            }
            this._gpuPrev = {rc6, now};
        } catch (e) {
            this._gpuLabel.text = '';
        }
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
