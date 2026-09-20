#!/bin/bash
# ウィンドウ配置のショートカット(Raycast の Window Management 相当)。Ubuntu 標準の Tiling Assistant を使う。
#   Mac では Raycast と同じ Ctrl+Option+<キー> を押す。Windows App 前面時だけ Karabiner が
#   Ctrl+Option+Shift+<キー> に変換して送り(そのままだと Mac 側の Raycast が先に取るため)、
#   Ubuntu 側はその中継キーで配置する。実機のキーボードでは Ctrl+Alt+Shift+<キー> を直接押せばよい。
#     ←/→/↑/↓ … 左/右/上/下 半分     1/2/3/4 … 左上/左下/右上/右下 1/4     Enter … 最大化
#     M … 中央 1/3 (Tiling Assistant に3分割が無いため、同梱の自作拡張 window-thirds で実現)
source "$(dirname "$0")/../lib/common.sh"

if ! in_desktop_session; then
  warn "デスクトップセッション外のため 65-window-tiling をスキップ(ログイン後に再実行してください)"
  exit 0
fi

EXT="tiling-assistant@ubuntu.com"
if ! gnome-extensions list | grep -qx "$EXT"; then
  apt_install gnome-shell-extension-ubuntu-tiling-assistant
fi
gnome-extensions enable "$EXT"

log "自作拡張 window-thirds をインストール(中央1/3 など)"
WT="window-thirds@ubuntu-setup"
WT_DIR="$HOME/.local/share/gnome-shell/extensions/$WT"
mkdir -p "$WT_DIR"
cp -r "$REPO_DIR/gnome-extensions/$WT/." "$WT_DIR/"
glib-compile-schemas "$WT_DIR/schemas"
if gnome-extensions list | grep -qx "$WT"; then
  gnome-extensions enable "$WT"
else
  # Wayland では新しい拡張は次回ログインまで認識されない。有効化リストに入れておけばログイン時に読み込まれる
  python3 - "$WT" <<'PY'
import ast, subprocess, sys
uuid = sys.argv[1]
out = subprocess.run(["gsettings", "get", "org.gnome.shell", "enabled-extensions"], check=True, capture_output=True, text=True).stdout.strip()
cur = [] if out.startswith("@as") else list(ast.literal_eval(out))
if uuid not in cur:
    subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", str(cur + [uuid])], check=True)
PY
  warn "window-thirds は次回ログインから有効になります"
fi

log "Tiling Assistant の設定とショートカット"
python3 - <<'EOF'
import ast, subprocess

TA = "org.gnome.shell.extensions.tiling-assistant"
WM = "org.gnome.desktop.wm.keybindings"
MOD = "<Control><Alt><Shift>"

# -ignore-ta 版 = 他のタイル状態に関係なく常に指定の位置へ(Raycast と同じ挙動)
BINDINGS = {
    "tile-left-half-ignore-ta": "Left",
    "tile-right-half-ignore-ta": "Right",
    "tile-top-half-ignore-ta": "Up",
    "tile-bottom-half-ignore-ta": "Down",
    "tile-topleft-quarter-ignore-ta": "1",
    "tile-bottomleft-quarter-ignore-ta": "2",
    "tile-topright-quarter-ignore-ta": "3",
    "tile-bottomright-quarter-ignore-ta": "4",
    "tile-maximize": "Return",
}

def get(schema, key):
    out = subprocess.run(["gsettings", "get", schema, key], check=True, capture_output=True, text=True).stdout.strip()
    return [] if out.startswith("@as") else list(ast.literal_eval(out))

def put(schema, key, value):
    subprocess.run(["gsettings", "set", schema, key, str(value)], check=True)

def norm(accel):  # 修飾キーの順序違いを同一視する
    mods = sorted(m.lower() for m in accel.replace(">", "> ").split() if m.startswith("<"))
    key = accel.split(">")[-1].lower()
    return tuple(mods), key

wanted = {norm(MOD + k) for k in BINDINGS.values()}

# GNOME 標準で同じキーを使っているもの(ウィンドウを別ワークスペースへ移動)から、そのキーだけ外す
keys = subprocess.run(["gsettings", "list-keys", WM], check=True, capture_output=True, text=True).stdout.split()
for key in keys:
    cur = get(WM, key)
    new = [a for a in cur if norm(a) not in wanted]
    if new != cur:
        put(WM, key, new)
        print(f"   GNOME標準の {key} から中継キーと重なる割り当てを外しました")

for key, k in BINDINGS.items():
    cur = get(TA, key)
    accel = MOD + k
    if norm(accel) not in {norm(a) for a in cur}:
        put(TA, key, cur + [accel])

# 半分に寄せたあと「残り半分に何を置くか」のポップアップは出さない(Raycast に合わせる)
subprocess.run(["gsettings", "set", TA, "enable-tiling-popup", "false"], check=True)
print("   登録: Ctrl+Alt+Shift + ←→↑↓ / 1 2 3 4 / Enter / M")
EOF
