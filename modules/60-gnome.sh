#!/bin/bash
# GNOME の見た目と拡張機能(Omakub の「画面が良い感じ」部分だけを移植)
source "$(dirname "$0")/../lib/common.sh"

if ! in_desktop_session; then
  warn "デスクトップセッション外のため 60-gnome をスキップ(ログイン後に再実行してください)"
  exit 0
fi

EXTENSIONS=(
  tactile@lundal.io                        # Super+T でグリッド配置
  just-perfection-desktop@just-perfection  # パネル等の細かい調整
  blur-my-shell@aunetx                     # ぼかし
  space-bar@luchrioh                       # ワークスペース番号をトップバーに表示
  undecorate@sun.wxg@gmail.com             # タイトルバーを消す
  tophat@fflewddur.github.io               # CPU/メモリ表示
  AlphabeticalAppGrid@stuarthayhurst       # アプリ一覧をABC順
)

log "GNOME 拡張機能をインストール(確認ダイアログが出たら「インストール」を押す)"
apt_install gnome-shell-extension-manager gir1.2-gtop-2.0 pipx
has gext || pipx install gnome-extensions-cli --system-site-packages
export PATH="$HOME/.local/bin:$PATH"
for ext in "${EXTENSIONS[@]}"; do
  if gnome-extensions list | grep -qx "$ext"; then
    gnome-extensions enable "$ext" 2>/dev/null || true
  else
    gext install "$ext" || warn "$ext のインストールに失敗(GNOMEのバージョン非対応の可能性)"
  fi
done

log "拡張機能の設定を読み込み"
dconf load /org/gnome/shell/extensions/ < "$REPO_DIR/config/dconf/shell-extensions.ini"

log "テーマと動作"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-purple-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru-purple'
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.interface clock-show-weekday true

log "Dock のお気に入り(存在するアプリだけ登録)"
favs=()
for app in google-chrome.desktop Alacritty.desktop code.desktop com.anthropic.Claude.desktop \
           1password.desktop org.gnome.Nautilus.desktop org.gnome.Settings.desktop; do
  for d in /usr/share/applications ~/.local/share/applications /var/lib/snapd/desktop/applications; do
    if [ -e "$d/$app" ]; then favs+=("'$app'"); break; fi
  done
done
if [ "${#favs[@]}" -gt 0 ]; then
  gsettings set org.gnome.shell favorite-apps "[$(IFS=,; echo "${favs[*]}")]"
fi
