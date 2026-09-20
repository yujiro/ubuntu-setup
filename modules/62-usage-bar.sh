#!/bin/bash
# トップバーに CPU/メモリ(TopHat)と、Claude / Codex の残量(自作拡張 usage-bar)を表示する
#   残量はローカルのファイルから読むだけ(bin/ai-usage-status の冒頭コメント参照)。ネットワークや認証情報は使わない。
source "$(dirname "$0")/../lib/common.sh"

log "ai-usage-status を ~/.local/bin に配置"
mkdir -p ~/.local/bin
install -m 0755 "$REPO_DIR/bin/ai-usage-status" ~/.local/bin/ai-usage-status

if ! in_desktop_session; then
  warn "デスクトップセッション外のため拡張機能の設定をスキップ(ログイン後に再実行してください)"
  exit 0
fi

log "TopHat で CPU とメモリを表示"
dconf write /org/gnome/shell/extensions/tophat/show-cpu true
dconf write /org/gnome/shell/extensions/tophat/show-mem true

log "自作拡張 usage-bar をインストール"
install_local_extension "usage-bar@ubuntu-setup"
