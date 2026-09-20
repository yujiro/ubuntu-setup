# ubuntu-setup

Ubuntu 24.04 (GNOME) の初期構成を1コマンドで再現するためのリポジトリ。
Mac (JISキーボード) から **Windows App (RDP)** で接続して使う前提で、日本語入力まわりを調整してある。
Omakub は使わず、必要な部分だけを自前で持つ。

## 手順

1. **Ubuntu をインストール**(公式ISO・通常インストール。言語=日本語、キーボード=日本語)
2. **実機の画面で** 端末を開いて実行(RDP はまだ使えないため最初の1回だけ実機で):

   ```bash
   sudo apt-get update && sudo apt-get install -y curl
   curl -fsSL https://raw.githubusercontent.com/yujiro/ubuntu-setup/main/bootstrap.sh | bash
   ```

   (git を入れて `~/ubuntu-setup` に clone し、`setup.sh` を実行する。手動でやる場合は `git clone https://github.com/yujiro/ubuntu-setup.git ~/ubuntu-setup && ~/ubuntu-setup/setup.sh`)

   途中で聞かれるもの: sudo パスワード、RDP 用のユーザー名/パスワード、GNOME 拡張のインストール確認ダイアログ。
3. **再起動**(日本語入力、docker / render グループが有効になる。ログアウトだけでは GPU のグループが反映されないことがある)
4. **Mac 側(初回のみ)**: [mac/README.md](mac/README.md) の手順で Karabiner-Elements にルールを入れる(貼り付け用は `mac/paste-rule-*.json`)
5. 手作業で残るもの: `gh auth login` / `sudo tailscale up` / 1Password・Chrome・Claude へのサインイン

## モジュール

| 番号 | 内容 | ローカル検証 |
|---|---|---|
| 10-apt-repos | 1Password / Chrome / VS Code / Docker / gh / mise / Claude Desktop / ulauncher の apt リポジトリ | 済 |
| 20-packages | 上記アプリ + CLI ツール、tailscale(snap) | 未(要sudo) |
| 30-japanese-input | Fcitx5 + Hazkey(ライブ変換)、JIS配列、かな=ON / 英数=OFF | 済 |
| 40-remote-desktop | GNOME リモートログイン(RDP)有効化。認証情報は実行時に入力 | 未(要sudo) |
| 50-fonts | UI: Noto Sans CJK JP / 等幅: UDEV Gothic NF、fontconfig で日本語字形を優先 | 済 |
| 60-gnome | GNOME 拡張6つ + 設定、Yaru-purple-dark、Dock。RDP 向けにアニメーションとぼかしはオフ | 済 |
| 62-usage-bar | トップバーに CPU/メモリ(TopHat)、GPU 稼働率(Intel)、Claude / Codex の残量(自作拡張 `usage-bar` + `bin/ai-usage-status`) | 済(拡張の表示は要再ログイン) |
| 65-window-tiling | ウィンドウ配置のショートカット(Raycast と同じキー。半分/四隅/最大化/中央1/3。3分割は同梱の自作拡張 `gnome-extensions/window-thirds`) | 済 |
| 68-mac-shortcuts | Cmd+W / Cmd+Q(閉じる)、Cmd+Shift+3/4/5(スクリーンショット)を Ubuntu で受ける | 済 |
| 70-ulauncher | ulauncher。Mac からは Cmd+Space(Karabiner で Ctrl+Option+Space に変換)、実機は Super+Space | 済 |
| 80-dev-tools | mise、Node.js、Codex CLI、git 初期設定 | 済 |

```bash
./setup.sh --list     # 一覧
./setup.sh 50 70      # 指定したモジュールだけ再実行(何度実行しても安全)
```

## Windows App (RDP) 経由での注意点(実測済み)

- Windows App は **英数キーを送らない**。かなキーも Karabiner 有効時は届かない。無変換も届かない。
  → Mac 側の Karabiner で「かな→半角/全角」「英数→Shift+半角/全角」に変換し、Fcitx5 側でそれぞれ ON専用 / OFF専用に割り当てている(トグルではないので何度押しても状態が反転しない)。
- **Cmd+Space は macOS(Spotlight)に、Option+Space は Raycast に取られて届かない。** → Karabiner で Cmd+Space を Ctrl+Option+Space に変換して送り、Ubuntu 側はそれで ulauncher を開く。
- Karabiner が効かないときは、まず macOS の「入力監視」に Karabiner-Core-Service(旧 karabiner_grabber)があるか確認。
- Karabiner の assets JSON を書き換えても有効中のルールには反映されない。ルールを削除 → Add predefined rule で入れ直す。
- **Option+F4 (Alt+F4) も届かない。** 確実に届くのは `Ctrl+Option+Shift+<キー>` の形 → 中継キーはこの形に統一している。
- **RDP セッションは GPU を使えず、ソフトウェア描画になって重い。** ユーザーを `render`,`video` グループに入れて再起動すると直る(モジュール40に組み込み済み)。確認: `top -H -p $(pgrep -x gnome-shell)` に `llvmpipe` スレッドが居なければ OK。
- **スクロールの重さは RDP の H.264 圧縮(GNOME 46 は CPU で圧縮)が上限。** 効くのは 有線LAN > ぼかし/アニメーションをオフ(60番で設定済み)> Windows App の Retina 最適化オフ。
- **NoMachine を入れない。** GNOME Shell の起動設定を書き換えて描画ライブラリ(libnxegl)を注入するため、GPU 描画と組み合わさるとカーソルの残像が出る。入れてしまったら `sudo apt remove nomachine-personal-edition` → 再ログイン。
- どのキーが届いているかは `GTK_IM_MODULE=xim xev -event keyboard` で確認できる。

## メンテナンス

- Hazkey / UDEV Gothic はバージョンと SHA256 を固定している(`modules/30-*.sh`, `modules/50-*.sh` の先頭)。上げるときは両方を書き換える。
- GNOME 拡張の設定を変えたら書き出して commit する:
  `dconf dump /org/gnome/shell/extensions/ > config/dconf/shell-extensions.ini`(`[space-bar/state]` など実行時の状態は手で除く)
- 秘密情報(パスワード、鍵、トークン)はこのリポジトリに入れない。
