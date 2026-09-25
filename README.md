# VZ Go Editor

VZ Editorの軽快な操作感とファンクションキー中心のUIを、macOS標準のCocoaとGoで再構成したネイティブ・テキストエディタです。

## 特徴

- 外部GUIライブラリなし（Go + cgo + Cocoa）
- UTF-8テキストの新規作成・読込・保存・別名保存
- 検索、次検索、指定行ジャンプ
- 行・桁・総行数・文字数を常時表示
- 編集中ファイルの場所をmacOSのターミナルで開く連携
- 拡張子に応じた自動インデント（Goはタブ、Python/C系は4スペース、Web系は2スペース）
- 等幅フォント、濃紺＋シアンのVZ風画面
- 未保存変更の警告と標準Undo/Redo
- F2/F3/F5/F6/F7/F8による操作

## 必要環境

- macOS 13以降
- Go 1.24以降
- Xcode Command Line Tools

## ビルド

```bash
make app
open build/VZGoEditor.app
```

## キーボード操作

| キー | 操作 |
|---|---|
| F2 / Command-S | 保存 |
| F3 / Command-O | 開く |
| F5 / Command-F | 検索 |
| F6 / Command-L | 指定行へ |
| F7 / Command-G | 次を検索 |
| F8 / Command-Shift-T | この場所をターミナルで開く |

MacBookでは設定により `fn` キーとの同時押しが必要です。

## 自動インデント

Enterキーで現在行の字下げを引き継ぎ、ブロック開始後は一段深くします。Tabキーもファイル形式に合う幅を挿入します。

- Go: タブ
- Python、C/C++、Java、Rust、Swift: 4スペース
- JavaScript、TypeScript、HTML/CSS、JSON、YAML、Ruby、Shell: 2スペース

## 設計

エントリーポイントとライフサイクルはGoが担い、Cocoa UIはObjective-Cブリッジを通じて呼び出します。配布物は通常の `.app` バンドルで、実行時の外部依存はありません。

## ライセンス

MIT
