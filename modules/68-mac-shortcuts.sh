#!/bin/bash
# Mac の Cmd 系ショートカットを Ubuntu で受けるための設定(Mac 側は mac/paste-rule-4-mac-shortcuts.json)。
#   Cmd+W → Ctrl+W (タブ/ウィンドウを閉じる。アプリ側の標準ショートカットなので Ubuntu 側の設定は不要)
#   Cmd+Q → Ctrl+Option+Shift+Q → GNOME の「ウィンドウを閉じる」(= ほとんどのアプリで終了)
#     ※ Alt+F4 を直接送る方式は Windows App を通過しなかった(実測)。Ctrl+Alt+Shift+<キー> の形は通る。
#   Cmd+Shift+3 / 4 / 5 (Mac のスクリーンショット) → Ctrl+Option+Shift+S / A / R (Mac 側は paste-rule-5-screenshot.json)
#     3 = 画面全体を即撮影   4 = 範囲選択の撮影UI   5 = 画面収録UI    保存先: ~/ピクチャ/スクリーンショット + クリップボード
#     ※ 中継キーに数字を使わないのは Ctrl+Alt+Shift+1〜4 をウィンドウ配置(65番)で使っているため
source "$(dirname "$0")/../lib/common.sh"

if ! in_desktop_session; then
  warn "デスクトップセッション外のため 68-mac-shortcuts をスキップ(ログイン後に再実行してください)"
  exit 0
fi

log "「ウィンドウを閉じる」に Ctrl+Alt+Shift+Q と Alt+F4 を割り当て(既存の割り当ては残す)"
python3 - <<'EOF'
import ast, subprocess
WM, KEY = "org.gnome.desktop.wm.keybindings", "close"
out = subprocess.run(["gsettings", "get", WM, KEY], check=True, capture_output=True, text=True).stdout.strip()
cur = [] if out.startswith("@as") else list(ast.literal_eval(out))
new = cur + [a for a in ("<Control><Alt><Shift>q", "<Alt>F4") if a not in cur]
if new != cur:
    subprocess.run(["gsettings", "set", WM, KEY, str(new)], check=True)
print("   close =", subprocess.run(["gsettings", "get", WM, KEY], capture_output=True, text=True).stdout.strip())
EOF

log "スクリーンショットの中継キーを割り当て(既存の Print 系は残す)"
python3 - <<'EOF'
import ast, subprocess
SCHEMA = "org.gnome.shell.keybindings"
ADD = {
    "screenshot": "<Control><Alt><Shift>s",                # Cmd+Shift+3: 画面全体
    "show-screenshot-ui": "<Control><Alt><Shift>a",        # Cmd+Shift+4: 範囲選択UI
    "show-screen-recording-ui": "<Control><Alt><Shift>r",  # Cmd+Shift+5: 収録UI (GNOME 既定と同じキー)
}
def norm(a):
    return (tuple(sorted(m.lower().replace("<ctrl>", "<control>") for m in a.replace(">", "> ").split() if m.startswith("<"))), a.split(">")[-1].lower())
for key, accel in ADD.items():
    out = subprocess.run(["gsettings", "get", SCHEMA, key], check=True, capture_output=True, text=True).stdout.strip()
    cur = [] if out.startswith("@as") else list(ast.literal_eval(out))
    if norm(accel) not in {norm(a) for a in cur}:
        subprocess.run(["gsettings", "set", SCHEMA, key, str(cur + [accel])], check=True)
    print(f"   {key} =", subprocess.run(["gsettings", "get", SCHEMA, key], capture_output=True, text=True).stdout.strip())
EOF
