#!/bin/bash
# mise(言語バージョン管理) + Node.js + Codex CLI
source "$(dirname "$0")/../lib/common.sh"

has mise || apt_install mise

log "mise を bash で有効化"
if ! grep -q 'mise activate bash' ~/.bashrc; then
  printf '\n# mise\neval "$(mise activate bash)"\n' >> ~/.bashrc
fi

log "Node.js (LTS) を mise で導入"
if mise which node >/dev/null 2>&1; then
  echo "   導入済み: node $(mise exec -- node -v 2>/dev/null || true)"
else
  mise use --global node@lts
fi
eval "$(mise activate bash)"

log "Codex CLI"
if has codex; then
  echo "   導入済み: $(codex --version 2>/dev/null || true)"
else
  mise exec -- npm install -g @openai/codex
  mise reshim 2>/dev/null || true
fi

log "git の基本設定(未設定の場合のみ)"
git config --global init.defaultBranch >/dev/null 2>&1 || git config --global init.defaultBranch main
git config --global pull.rebase >/dev/null 2>&1 || git config --global pull.rebase true
if ! git config --global user.name >/dev/null; then
  warn "git の user.name / user.email が未設定です。次で設定してください:"
  echo '     git config --global user.name  "Your Name"'
  echo '     git config --global user.email "you@example.com"'
fi
has gh && { gh auth status >/dev/null 2>&1 || warn "GitHub 未ログイン: gh auth login を実行してください"; }
