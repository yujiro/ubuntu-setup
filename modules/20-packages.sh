#!/bin/bash
# アプリと基本ツール
source "$(dirname "$0")/../lib/common.sh"

log "apt パッケージをインストール"
apt_install \
  git curl wget unzip build-essential \
  1password 1password-cli google-chrome-stable code gh claude-desktop \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  mise ulauncher wmctrl \
  alacritty flameshot gnome-tweaks gnome-shell-extension-manager pipx \
  ripgrep fd-find fzf bat eza btop

log "docker を sudo なしで使えるようにする(次回ログインから有効)"
sudo usermod -aG docker "$USER"

log "snap: tailscale"
has tailscale || sudo snap install tailscale
