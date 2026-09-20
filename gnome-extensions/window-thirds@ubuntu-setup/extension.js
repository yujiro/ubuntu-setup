import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// name: [x, y, width, height] as fractions of the monitor's work area
const LAYOUTS = {
    'first-third': [0, 0, 1 / 3, 1],
    'middle-third': [1 / 3, 0, 1 / 3, 1],
    'last-third': [2 / 3, 0, 1 / 3, 1],
    'first-two-thirds': [0, 0, 2 / 3, 1],
    'last-two-thirds': [1 / 3, 0, 2 / 3, 1],
};

export default class WindowThirdsExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        for (const [name, rect] of Object.entries(LAYOUTS)) {
            Main.wm.addKeybinding(name, this._settings,
                Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
                Shell.ActionMode.NORMAL,
                () => this._place(rect));
        }
    }

    disable() {
        for (const name of Object.keys(LAYOUTS))
            Main.wm.removeKeybinding(name);
        if (this._idleId) {
            GLib.source_remove(this._idleId);
            this._idleId = 0;
        }
        this._settings = null;
    }

    _place([fx, fy, fw, fh]) {
        const win = global.display.focus_window;
        if (!win || !win.allows_move() || !win.allows_resize())
            return;

        const apply = () => {
            const area = win.get_work_area_current_monitor();
            win.move_resize_frame(true,
                area.x + Math.round(area.width * fx),
                area.y + Math.round(area.height * fy),
                Math.round(area.width * fw),
                Math.round(area.height * fh));
        };

        if (win.get_maximized() || win.is_fullscreen()) {
            if (win.is_fullscreen())
                win.unmake_fullscreen();
            win.unmaximize(Meta.MaximizeFlags.BOTH);
            // the size change is applied asynchronously on Wayland
            this._idleId = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                this._idleId = 0;
                apply();
                return GLib.SOURCE_REMOVE;
            });
        } else {
            apply();
        }
    }
}
