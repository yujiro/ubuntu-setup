#!/bin/bash
# ulauncher(アプリランチャー)。Mac の Windows App(RDP) 越しでも呼び出せるようにする。
#   Wayland では ulauncher 自身のホットキーが効かないため、GNOME のカスタムショートカットから
#   ulauncher-toggle を呼ぶ。Cmd+Space は macOS(Spotlight)に、Option+Space は Raycast 等に取られて
#   届かないため、Mac 側の Karabiner で Cmd+Space → Ctrl+Option+Space に変換して送る。
#     Ctrl+Alt+Space … RDP 越し用の中継キー(手で押す想定ではない)
#     Super+Space    … 実機のキーボード用
source "$(dirname "$0")/../lib/common.sh"

has ulauncher || apt_install ulauncher wmctrl

log "ulauncher の自動起動と設定"
mkdir -p ~/.config/autostart ~/.config/ulauncher
cat > ~/.config/autostart/ulauncher.desktop <<'EOF'
[Desktop Entry]
Name=Ulauncher
Comment=Application launcher for Linux
Categories=GNOME;GTK;Utility;
Exec=env GDK_BACKEND=x11 /usr/bin/ulauncher --hide-window
Icon=ulauncher
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF

python3 - <<'EOF'
import json, os
p = os.path.expanduser("~/.config/ulauncher/settings.json")
try:
    d = json.load(open(p))
except Exception:
    d = {}
d.update({
    "hotkey-show-app": "null",          # ホットキーは GNOME 側で持つ
    "show-indicator-icon": True,
    "clear-previous-query": True,
    "render-on-screen": "mouse-pointer-monitor",
    "theme-name": "dark",
})
json.dump(d, open(p, "w"), indent=2)
EOF

if ! in_desktop_session; then
  warn "デスクトップセッション外のためショートカット登録をスキップ"
  exit 0
fi

log "ショートカットを登録 (Ctrl+Alt+Space / Super+Space)"
# GNOME 既定の割り当てを空ける
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"          # Fcitx5 を使うので不要
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"

python3 - <<'EOF'
import ast, subprocess
SCHEMA = "org.gnome.settings-daemon.plugins.media-keys"
BASE = "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
CMD = 'sh -c "pgrep -x ulauncher >/dev/null && ulauncher-toggle || setsid -f env GDK_BACKEND=x11 ulauncher"'
ENTRIES = {"ulauncher-remote": "<Control><Alt>space", "ulauncher-super": "<Super>space"}

def gs(*a): return subprocess.run(["gsettings", *a], check=True, capture_output=True, text=True).stdout.strip()

cur = gs("get", SCHEMA, "custom-keybindings")
paths = [] if cur.startswith("@as") else list(ast.literal_eval(cur))

# 以前の登録(Omakub の ulauncher-toggle を含む)で同じキーを使っているものは外す
keep = []
for p in paths:
    rel = f"{SCHEMA}.custom-keybinding:{p}"
    name, binding = gs("get", rel, "name").strip("'"), gs("get", rel, "binding").strip("'")
    if binding in ENTRIES.values() or name.startswith("ulauncher"):
        for k in ("name", "command", "binding"):
            subprocess.run(["gsettings", "reset", rel, k])
        continue
    keep.append(p)

for ident, binding in ENTRIES.items():
    p = f"{BASE}/{ident}/"
    rel = f"{SCHEMA}.custom-keybinding:{p}"
    gs("set", rel, "name", ident)
    gs("set", rel, "command", CMD)
    gs("set", rel, "binding", binding)
    keep.append(p)

gs("set", SCHEMA, "custom-keybindings", str(keep))
print("   登録:", ", ".join(ENTRIES.values()))
EOF

pgrep -x ulauncher >/dev/null || (setsid -f env GDK_BACKEND=x11 ulauncher --hide-window >/dev/null 2>&1 || true)
