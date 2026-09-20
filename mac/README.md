# Mac 側の設定 (Karabiner-Elements)

Windows App が前面のときだけ、次の変換を行う。Mac 本体の操作には影響しない。

| Mac で押すキー | 送られるキー | Ubuntu 側の動作 |
|---|---|---|
| かな | 半角/全角 | 日本語入力 ON(何度押しても ON) |
| 英数 | Shift+半角/全角 | 日本語入力 OFF(何度押しても OFF) |
| Cmd+Space | Ctrl+Option+Space | ulauncher を開く/閉じる |
| Ctrl+Option+←→↑↓ | Ctrl+Option+Shift+同キー | ウィンドウを左/右/上/下 半分に配置 |
| Ctrl+Option+1/2/3/4 | 同上 | 左上/左下/右上/右下 1/4 に配置 |
| Ctrl+Option+Enter | 同上 | 最大化 |
| Ctrl+Option+M | 同上 | 中央 1/3 に配置 |

## 準備(初回のみ)

1. [Karabiner-Elements](https://karabiner-elements.pqrs.org/) をインストール
2. システム設定 → プライバシーとセキュリティ → **入力監視** で `Karabiner-Core-Service`(旧版は `karabiner_grabber`)を ON。
   一覧に無ければ「+」→ `/Library/Application Support/org.pqrs/Karabiner-Elements/` から追加
3. 一般 → ログイン項目と機能拡張 で Karabiner のバックグラウンド実行とドライバ機能拡張を許可

## ルールの入れ方(どちらか一方)

ファイルの形式が2種類あるので注意。**形式を取り違えると `manipulators is missing or empty` エラーになる。**

### A. 貼り付ける(簡単)

Complex Modifications → **Add your own rule** → 編集欄の中身を全部消して、次のファイルの中身を**1つずつ**貼って Save。

- `paste-rule-1-ime.json` … かな/英数
- `paste-rule-2-cmd-space.json` … Cmd+Space
- `paste-rule-3-window-tiling.json` … ウィンドウ配置(Raycast の Window Management と同じキー)

(この欄に貼れるのは `description` と `manipulators` を持つ「ルール1個」だけ。`karabiner-windowsapp.json` を貼るとエラーになる)

### B. ファイルを置く

`karabiner-windowsapp.json`(`title` と `rules` を持つ配布形式)を
`~/.config/karabiner/assets/complex_modifications/` に置き、
Complex Modifications → **Add predefined rule** → 3つのルールを Enable。

## 修正するとき

有効化した時点の内容が `karabiner.json` にコピーされるため、ファイルを書き換えても反映されない。
古いルールをゴミ箱アイコンで削除してから入れ直すこと。
