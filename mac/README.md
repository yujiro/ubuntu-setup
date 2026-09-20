# Mac 側の設定 (Karabiner-Elements)

Windows App が前面のときだけ、次の変換を行う。Mac 本体の操作には影響しない。

| Mac で押すキー | 送られるキー | Ubuntu 側の動作 |
|---|---|---|
| かな | 半角/全角 | 日本語入力 ON(何度押しても ON) |
| 英数 | Shift+半角/全角 | 日本語入力 OFF(何度押しても OFF) |
| Cmd+Space | Option+Space | ulauncher を開く/閉じる |

## 手順

1. [Karabiner-Elements](https://karabiner-elements.pqrs.org/) をインストール
2. システム設定 → プライバシーとセキュリティ → **入力監視** で `Karabiner-Core-Service`(旧版は `karabiner_grabber`)を ON。
   一覧に無ければ「+」→ `/Library/Application Support/org.pqrs/Karabiner-Elements/` から追加
3. 一般 → ログイン項目と機能拡張 で Karabiner のバックグラウンド実行とドライバ機能拡張を許可
4. `karabiner-windowsapp.json` を `~/.config/karabiner/assets/complex_modifications/` に置く
5. Karabiner-Elements → Complex Modifications → Add predefined rule → 2つのルールを Enable

ルールを修正したときは、既存ルールを削除してから入れ直すこと(有効化時の内容が karabiner.json にコピーされるため)。
