#!/bin/bash
# 日本語表示を優先したフォント構成
#   UI/文書: Noto Sans CJK JP   等幅: UDEV Gothic NF (BIZ UDゴシック + JetBrains Mono, Nerd Font 入り)
source "$(dirname "$0")/../lib/common.sh"

UDEV_VER="v2.2.0"
UDEV_ZIP="UDEVGothic_NF_${UDEV_VER}.zip"
UDEV_URL="https://github.com/yuru7/udev-gothic/releases/download/${UDEV_VER}/${UDEV_ZIP}"
UDEV_SHA256="45faeef7b5d8bc591bcc5887a2ca0c5fb9028066f18a5a52cd6f10b7d655ba37"
FONT_DIR="$HOME/.local/share/fonts/UDEVGothicNF"
MONO="UDEV Gothic NF"

log "フォントをインストール"
apt_install fonts-noto-cjk fonts-noto-cjk-extra fonts-noto-color-emoji unzip

if ! fc-list : family | grep -qx "$MONO"; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  download "$UDEV_URL" "$UDEV_SHA256" "$tmp/$UDEV_ZIP"
  mkdir -p "$FONT_DIR"
  unzip -qjo "$tmp/$UDEV_ZIP" '*.ttf' -d "$FONT_DIR"
fi

log "fontconfig: 日本語グリフを優先(中国語字形になるのを防ぐ)"
mkdir -p ~/.config/fontconfig/conf.d
cp "$REPO_DIR/config/fontconfig/50-japanese.conf" ~/.config/fontconfig/conf.d/50-japanese.conf
fc-cache -f

if in_desktop_session; then
  log "GNOME のフォント設定"
  gsettings set org.gnome.desktop.interface font-name 'Noto Sans CJK JP 11'
  gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans CJK JP 11'
  gsettings set org.gnome.desktop.interface monospace-font-name "$MONO 11"
  gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans CJK JP Bold 11'
  gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
  gsettings set org.gnome.desktop.interface font-hinting 'slight'
else
  warn "デスクトップセッション外のため GNOME のフォント設定はスキップ"
fi

log "Alacritty のフォント"
mkdir -p ~/.config/alacritty
backup_once ~/.config/alacritty/font.toml
cat > ~/.config/alacritty/font.toml <<EOF
[font]
normal = { family = "$MONO", style = "Regular" }
bold = { family = "$MONO", style = "Bold" }
italic = { family = "$MONO", style = "Italic" }
EOF
if [ ! -e ~/.config/alacritty/alacritty.toml ]; then
  cat > ~/.config/alacritty/alacritty.toml <<'EOF'
[general]
import = ["~/.config/alacritty/font.toml"]

[font]
size = 11
EOF
fi

log "VS Code のフォント"
VSC=~/.config/Code/User/settings.json
mkdir -p "$(dirname "$VSC")"
[ -e "$VSC" ] || echo '{}' > "$VSC"
backup_once "$VSC"
python3 - "$VSC" "$MONO" <<'EOF'
import json, re, sys
path, mono = sys.argv[1], sys.argv[2]
raw = open(path).read()
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    # コメントや末尾カンマ付き(JSONC)は壊さないよう触らない
    print("   settings.json が JSONC のため自動編集をスキップ。editor.fontFamily を手動で設定してください。")
    sys.exit(0)
data["editor.fontFamily"] = f"'{mono}', monospace"
data["terminal.integrated.fontFamily"] = mono
open(path, "w").write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
EOF
