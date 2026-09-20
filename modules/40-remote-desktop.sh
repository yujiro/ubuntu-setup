#!/bin/bash
# GNOME リモートログイン(RDP)を有効化する。Mac の Windows App から接続するための設定。
# ※ このモジュールは実機の画面(またはSSH)で実行すること。認証情報はリポジトリに保存しない。
# ※ 未検証: 既存マシンでは sudo なしで試せないため、新規マシンでの初回実行時に要確認。
source "$(dirname "$0")/../lib/common.sh"

log "GNOME リモートログイン(RDP)を設定"
apt_install gnome-remote-desktop openssl

GRD_HOME="$(getent passwd gnome-remote-desktop | cut -d: -f6)"
GRD_DIR="$GRD_HOME/.local/share/gnome-remote-desktop"
sudo -u gnome-remote-desktop mkdir -p "$GRD_DIR"

if ! sudo test -f "$GRD_DIR/rdp-tls.crt"; then
  log "TLS 証明書を生成"
  sudo -u gnome-remote-desktop openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=JP/O=ubuntu-setup/CN=$(hostname)" \
    -out "$GRD_DIR/rdp-tls.crt" -keyout "$GRD_DIR/rdp-tls.key"
fi
sudo grdctl --system rdp set-tls-cert "$GRD_DIR/rdp-tls.crt"
sudo grdctl --system rdp set-tls-key "$GRD_DIR/rdp-tls.key"

echo "RDP 接続用のユーザー名とパスワードを決めてください(Ubuntu のログインとは別物。接続時に最初に聞かれます)。"
read -r -p "  RDP ユーザー名: " rdp_user
read -r -s -p "  RDP パスワード: " rdp_pass; echo
sudo grdctl --system rdp set-credentials "$rdp_user" "$rdp_pass"
unset rdp_pass

log "リモートセッションで GPU を使えるようにする"
# 実機ログインでは logind が /dev/dri に ACL を付けるが、RDP のリモートログインには付かない。
# render グループに入っていないと GNOME Shell がソフトウェア描画(llvmpipe)になり、
# CPU を1コア以上使い続けて UI がもっさりする(N100 で実測: gnome-shell 150% → 7%)。
sudo usermod -aG render,video "$USER"
warn "GPU のグループ変更は再起動後に有効になります(Linger 有効時はログアウトでは反映されない)"

sudo grdctl --system rdp enable
sudo systemctl enable --now gnome-remote-desktop.service
if has ufw && sudo ufw status | grep -q "Status: active"; then
  sudo ufw allow 3389/tcp
fi

log "RDP を有効化しました (ポート 3389)。Tailscale 経由での接続を推奨。"
sudo grdctl --system status || true
