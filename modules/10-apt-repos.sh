#!/bin/bash
# 外部 apt リポジトリの登録 (1Password / Chrome / VS Code / Docker / GitHub CLI / mise / Claude Desktop / ulauncher)
source "$(dirname "$0")/../lib/common.sh"

log "apt リポジトリを登録"
apt_install curl gpg ca-certificates software-properties-common
sudo install -d -m 0755 /etc/apt/keyrings /usr/share/keyrings

# add_repo <名前> <鍵URL> <鍵の保存先> <dearmor:yes|no> <deb行>
add_repo() {
  local name="$1" key_url="$2" key_path="$3" dearmor="$4" line="$5"
  if [ "$dearmor" = yes ]; then
    curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$key_path" >/dev/null
  else
    curl -fsSL "$key_url" | sudo tee "$key_path" >/dev/null
  fi
  sudo chmod a+r "$key_path"
  echo "$line" | sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
}

CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

add_repo 1password https://downloads.1password.com/linux/keys/1password.asc \
  /usr/share/keyrings/1password-archive-keyring.gpg yes \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main"
# 1Password 公式手順の debsig ポリシー
sudo install -d -m 0755 /etc/debsig/policies/AC2D62742012EA22 /usr/share/debsig/keyrings/AC2D62742012EA22
curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol \
  | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
  | gpg --dearmor | sudo tee /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg >/dev/null

# Chrome と VS Code はパッケージ自身が <名前>.sources (deb822形式) を作って管理する。
# 同じファイル名・形式で書いておかないと、インストール後に定義が二重になり apt が警告を出す。
add_repo_deb822() {
  local name="$1" key_url="$2" key_path="$3" uri="$4"
  curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$key_path" >/dev/null
  sudo chmod a+r "$key_path"
  sudo rm -f "/etc/apt/sources.list.d/$name.list"
  printf 'Types: deb\nURIs: %s\nSuites: stable\nComponents: main\nArchitectures: amd64\nSigned-By: %s\n' \
    "$uri" "$key_path" | sudo tee "/etc/apt/sources.list.d/$name.sources" >/dev/null
}

add_repo_deb822 google-chrome https://dl.google.com/linux/linux_signing_key.pub \
  /usr/share/keyrings/google-chrome.gpg https://dl.google.com/linux/chrome-stable/deb/

add_repo_deb822 vscode https://packages.microsoft.com/keys/microsoft.asc \
  /usr/share/keyrings/microsoft.gpg https://packages.microsoft.com/repos/code

add_repo docker https://download.docker.com/linux/ubuntu/gpg \
  /etc/apt/keyrings/docker.asc no \
  "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $CODENAME stable"

add_repo github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  /usr/share/keyrings/githubcli-archive-keyring.gpg no \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"

add_repo mise https://mise.jdx.dev/gpg-key.pub \
  /etc/apt/keyrings/mise-archive-keyring.gpg yes \
  "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main"

# Claude Desktop: 公開鍵はパッケージ同梱のものをリポジトリに保存してある
sudo install -m 0644 "$REPO_DIR/config/keys/claude-desktop-archive-keyring.asc" \
  /usr/share/keyrings/claude-desktop-archive-keyring.asc
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
  | sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null

sudo add-apt-repository -y ppa:agornostal/ulauncher

sudo apt-get update
