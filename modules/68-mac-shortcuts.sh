#!/bin/bash
# Mac の Cmd 系ショートカットを Ubuntu で受けるための設定(Mac 側は mac/paste-rule-4-mac-shortcuts.json)。
#   Cmd+W → Ctrl+W (タブ/ウィンドウを閉じる。アプリ側の標準ショートカットなので Ubuntu 側の設定は不要)
#   Cmd+Q → Ctrl+Option+Shift+Q → GNOME の「ウィンドウを閉じる」(= ほとんどのアプリで終了)
#     ※ Alt+F4 を直接送る方式は Windows App を通過しなかった(実測)。Ctrl+Alt+Shift+<キー> の形は通る。
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
