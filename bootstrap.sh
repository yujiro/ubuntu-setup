#!/bin/bash
# まっさらな Ubuntu で最初に実行する入口。git を入れてこのリポジトリを取得し、setup.sh を実行する。
#   REPO_URL を自分のリポジトリに書き換えて使う。private リポジトリの場合は先に gh auth login が必要。
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/CHANGE-ME/ubuntu-setup.git}"
DEST="${DEST:-$HOME/ubuntu-setup}"

sudo apt-get update
sudo apt-get install -y git curl

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  git clone "$REPO_URL" "$DEST"
fi

exec "$DEST/setup.sh" "$@"
