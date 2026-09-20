#!/bin/bash
# Ubuntu 初期構成。何度実行しても安全(導入済みのものはスキップ/上書き)。
#   ./setup.sh            全モジュールを番号順に実行
#   ./setup.sh 50 70      番号で指定したモジュールだけ実行
#   ./setup.sh --list     モジュール一覧
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(id -u)" -eq 0 ]; then
  echo "root ではなく、設定を入れたい一般ユーザーで実行してください。" >&2
  exit 1
fi

mapfile -t ALL < <(ls modules/[0-9][0-9]-*.sh | sort)

if [ "${1:-}" = "--list" ]; then
  for m in "${ALL[@]}"; do
    printf '%s  %s\n' "$(basename "$m" .sh)" "$(sed -n '2s/^# *//p' "$m")"
  done
  exit 0
fi

if [ "$#" -gt 0 ]; then
  SELECTED=()
  for n in "$@"; do
    match=(modules/"$n"-*.sh)
    [ -e "${match[0]}" ] || { echo "モジュール $n が見つかりません" >&2; exit 1; }
    SELECTED+=("${match[0]}")
  done
else
  SELECTED=("${ALL[@]}")
fi

sudo -v   # 最初に1回だけパスワードを聞く

failed=()
for m in "${SELECTED[@]}"; do
  printf '\n\033[1;32m#### %s\033[0m\n' "$(basename "$m")"
  if ! bash "$m"; then
    failed+=("$(basename "$m")")
    printf '\033[1;31m[x] %s が失敗しました(続行します)\033[0m\n' "$(basename "$m")"
  fi
done

echo
if [ "${#failed[@]}" -gt 0 ]; then
  echo "失敗したモジュール: ${failed[*]}"
  echo "原因を直したあと ./setup.sh <番号> で個別に再実行できます。"
  exit 1
fi
echo "すべて完了しました。ログアウトしてログインし直してください(日本語入力・docker グループが有効になります)。"
