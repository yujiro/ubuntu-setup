# 各モジュールから source される共通関数
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_DIR

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }

has() { command -v "$1" >/dev/null 2>&1; }

# 未導入のパッケージだけを入れる(全部入っていれば sudo も呼ばない)
apt_install() {
  local missing=() p
  for p in "$@"; do
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || missing+=("$p")
  done
  [ "${#missing[@]}" -eq 0 ] && return 0
  sudo apt-get install -y "${missing[@]}"
}

# デスクトップセッション内(gsettings/dconf が使える)か
in_desktop_session() {
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && has gsettings
}

# download <url> <sha256|-> <出力先>  … sha256 が "-" なら照合しない
download() {
  local url="$1" sha="$2" out="$3"
  curl -fsSL -o "$out" "$url"
  if [ "$sha" != "-" ]; then
    echo "$sha  $out" | sha256sum -c - >/dev/null || { warn "SHA256 不一致: $url"; return 1; }
  fi
}

# 既存ファイルを上書きする前に .bak を1回だけ残す
backup_once() {
  local f="$1"
  if [ -e "$f" ] && [ ! -e "$f.bak-ubuntu-setup" ]; then
    cp -a "$f" "$f.bak-ubuntu-setup"
  fi
}

# install_local_extension <uuid> … gnome-extensions/<uuid> を ~/.local にコピーして有効化する
install_local_extension() {
  local uuid="$1" dir="$HOME/.local/share/gnome-shell/extensions/$1"
  mkdir -p "$dir"
  cp -r "$REPO_DIR/gnome-extensions/$uuid/." "$dir/"
  [ -d "$dir/schemas" ] && glib-compile-schemas "$dir/schemas"
  if gnome-extensions list | grep -qx "$uuid"; then
    gnome-extensions enable "$uuid"
    return 0
  fi
  # Wayland では新しい拡張は次回ログインまで認識されない。有効化リストに入れておけばログイン時に読み込まれる
  python3 - "$uuid" <<'PY'
import ast, subprocess, sys
uuid = sys.argv[1]
out = subprocess.run(["gsettings", "get", "org.gnome.shell", "enabled-extensions"], check=True, capture_output=True, text=True).stdout.strip()
cur = [] if out.startswith("@as") else list(ast.literal_eval(out))
if uuid not in cur:
    subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", str(cur + [uuid])], check=True)
PY
  warn "$uuid は次回ログインから有効になります"
}
