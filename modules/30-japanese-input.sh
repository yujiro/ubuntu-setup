#!/bin/bash
# Ubuntu 24.04 (GNOME) 日本語入力セットアップ
#   Fcitx5 + Hazkey(ライブ変換) / JIS配列 / かな=必ずON・英数=必ずOFF
#   Mac + Windows App(RDP) から接続する前提(Mac側は mac/karabiner-windowsapp.json を使用)
#   単体でも実行可能: bash modules/30-japanese-input.sh → 完了後ログアウトしてログインし直す
set -euo pipefail

HAZKEY_VER="0.2.1"
HAZKEY_DEB="fcitx5-hazkey_${HAZKEY_VER}-1_amd64.deb"
HAZKEY_URL="https://github.com/7ka-Hiira/hazkey/releases/download/${HAZKEY_VER}/${HAZKEY_DEB}"
HAZKEY_SHA256="a9d394f38e6ee47e84f1e0f6aa742bc555a324501e3dca57d24027f784f0d758"

if [ "$(id -u)" -eq 0 ]; then
  echo "root ではなく、設定を入れたい一般ユーザーで実行してください。" >&2
  exit 1
fi

echo "== 1/5 パッケージをインストール (sudo パスワードを聞かれます)"
sudo apt update
sudo apt install -y curl im-config fcitx5 fcitx5-config-qt \
  fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-frontend-qt6

if [ "$(dpkg-query -W -f='${Version}' fcitx5-hazkey 2>/dev/null)" = "${HAZKEY_VER}-1" ]; then
  echo "   Hazkey ${HAZKEY_VER} は導入済み"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fL -o "$tmp/$HAZKEY_DEB" "$HAZKEY_URL"
  echo "$HAZKEY_SHA256  $tmp/$HAZKEY_DEB" | sha256sum -c -
  sudo apt install -y "$tmp/$HAZKEY_DEB"
fi

echo "== 2/5 既存の Fcitx5 設定をバックアップ"
was_running=no
if pkill -x fcitx5 2>/dev/null; then was_running=yes; sleep 1; fi
if [ -d ~/.config/fcitx5 ]; then
  cp -a ~/.config/fcitx5 ~/.config/fcitx5.bak-"$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p ~/.config/fcitx5 ~/.config/environment.d ~/.config/autostart

echo "== 3/5 Fcitx5 の設定を書き込み"
# 入力メソッド: JIS配列 + Hazkey(既定)
cat > ~/.config/fcitx5/profile <<'EOF'
[Groups/0]
Name=デフォルト
Default Layout=jp
DefaultIM=hazkey

[Groups/0/Items/0]
Name=keyboard-jp
Layout=

[Groups/0/Items/1]
Name=hazkey
Layout=

[GroupOrder]
0=デフォルト
EOF

# ホットキー: トグルは使わず、ON専用/OFF専用キーだけにする
#   かな  → (Karabiner) 半角/全角        → ON
#   英数  → (Karabiner) Shift+半角/全角  → OFF
cat > ~/.config/fcitx5/config <<'EOF'
[Hotkey]
TriggerKeys=
AltTriggerKeys=
EnumerateWithTriggerKeys=True
EnumerateForwardKeys=
EnumerateBackwardKeys=
EnumerateSkipFirst=False

[Hotkey/ActivateKeys]
0=Zenkaku_Hankaku
1=Henkan
2=Hiragana_Katakana

[Hotkey/DeactivateKeys]
0=Shift+Zenkaku_Hankaku
1=Muhenkan
2=Eisu_toggle

[Behavior]
ActiveByDefault=True
ShareInputState=All
PreeditEnabledByDefault=True
EOF

echo "== 4/5 環境変数・自動起動・im-config"
cat > ~/.config/environment.d/90-fcitx5-ime.conf <<'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
EOF
cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/
im-config -n fcitx5

echo "== 5/5 GNOME の入力ソースを JIS 配列のみに(IBus の Mozc 等と競合させない)"
if command -v gsettings >/dev/null && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'jp')]"
else
  echo "  ※ デスクトップセッション外で実行されたため gsettings を設定できませんでした。"
  echo "    ログイン後に次を実行してください:"
  echo "    gsettings set org.gnome.desktop.input-sources sources \"[('xkb', 'jp')]\""
fi

if [ "$was_running" = yes ]; then (setsid -f fcitx5 -d >/dev/null 2>&1 || true); fi

cat <<'EOF'

完了しました。ログアウトしてログインし直すと有効になります。
  - かな = 日本語入力ON / 英数 = OFF (Mac側で Karabiner のルールが必要)
  - ライブ変換は Hazkey の既定で有効。調整は「Hazkey設定」(hazkey-settings) から。
EOF
