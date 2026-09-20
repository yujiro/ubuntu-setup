#!/bin/bash
# Mac の Cmd 系ショートカットを Ubuntu で受けるための設定(Mac 側は mac/paste-rule-4-mac-shortcuts.json)。
#   Cmd+W → Ctrl+W (タブ/ウィンドウを閉じる。アプリ側の標準ショートカットなので Ubuntu 側の設定は不要)
#   Cmd+Q → Alt+F4 (ウィンドウを閉じる = ほとんどのアプリで終了)。GNOME の「ウィンドウを閉じる」に Alt+F4 が必要
source "$(dirname "$0")/../lib/common.sh"

if ! in_desktop_session; then
  warn "デスクトップセッション外のため 68-mac-shortcuts をスキップ(ログイン後に再実行してください)"
  exit 0
fi

log "「ウィンドウを閉じる」に Alt+F4 を割り当て(既存の割り当ては残す)"
python3 - <<'EOF'
import ast, subprocess
WM, KEY, ACCEL = "org.gnome.desktop.wm.keybindings", "close", "<Alt>F4"
out = subprocess.run(["gsettings", "get", WM, KEY], check=True, capture_output=True, text=True).stdout.strip()
cur = [] if out.startswith("@as") else list(ast.literal_eval(out))
if ACCEL not in cur:
    subprocess.run(["gsettings", "set", WM, KEY, str(cur + [ACCEL])], check=True)
print("   close =", subprocess.run(["gsettings", "get", WM, KEY], capture_output=True, text=True).stdout.strip())
EOF
