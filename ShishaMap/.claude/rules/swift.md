# Swift 規約 — rules/swift.md

すべての `.swift` ファイルに自動適用される最小限の必須ルール。

## 命名規則

- 型・プロトコル: `UpperCamelCase`
- 関数・プロパティ・変数: `lowerCamelCase`
- 識別子はすべて英語。日本語はユーザー向け文字列（`Localizable.strings`）のみ許可

## アクセス制御

- デフォルトは `private` または `fileprivate`
- クロスファイルで参照する場合のみ `internal`（明示不要）
- モジュール外公開が必要な場合のみ `public`

## コメント

- `public` / `internal` なプロトコル・ViewModel関数には `///` docコメントを書く
- インラインコメントは自明でないロジックのみ。何をするかでなく「なぜ」を書く

## 非同期処理

- `async/await` を使う。`DispatchQueue` や completion handler は使用禁止
- `Task {}` をViewに直書きしない。必ずViewModelのメソッドを呼ぶ
