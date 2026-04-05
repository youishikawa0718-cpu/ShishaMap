# ShishaMap

近くのシーシャ店をマップで発見できるiOSアプリ。

## 機能

- **マップ表示** — 現在地周辺のシーシャ店をピンで表示、クラスタリング対応
- **検索・フィルター** — キーワード検索、エリア検索、営業中・個室・価格帯などで絞り込み
- **店舗詳細** — 写真、営業時間、フレーバータグ、評価、電話・Webリンク
- **お気に入り・チェックイン** — 気になる店を保存、訪問記録をメモ付きで管理
- **オフライン保存** — お気に入り・チェックイン履歴はすべてローカル保存

## 技術スタック

| 項目 | 技術 |
|---|---|
| UI | SwiftUI |
| アーキテクチャ | MVVM (`@Observable`) |
| データ永続化 | SwiftData |
| 地図 | MapKit |
| 位置情報 | CoreLocation |
| 外部API | Google Places API (REST) |
| 最小ターゲット | iOS 17.0 |

## セットアップ

1. リポジトリをクローン
   ```
   git clone https://github.com/youishikawa0718-cpu/ShishaMap.git
   ```

2. APIキーの設定
   ```
   cp ShishaMap/Secrets.xcconfig.example ShishaMap/Secrets.xcconfig
   ```
   `Secrets.xcconfig` に Google Places API キーを記入：
   ```
   PLACES_API_KEY = YOUR_API_KEY_HERE
   ```

3. Xcode でプロジェクトを開きビルド

## プロジェクト構成

```
ShishaMap/
├── Features/          # 画面ごとのView
│   ├── Map/           # マップ画面
│   ├── Search/        # 検索・フィルター
│   ├── Detail/        # 店舗詳細
│   ├── Favorites/     # お気に入り・チェックイン
│   ├── Settings/      # 設定・ライセンス
│   └── Onboarding/    # 初回起動
├── Models/            # SwiftDataモデル・値型
├── ViewModels/        # StoreViewModel
└── Repositories/      # データアクセス層（Protocol + 実装）
```

## プライバシー

- 位置情報はシーシャ店の検索にのみ使用し、外部サーバーには送信しません
- すべてのユーザーデータ（お気に入り・チェックイン）は端末内にのみ保存されます
- [プライバシーポリシー](https://youishikawa0718-cpu.github.io/ShishaMap/privacy-policy.html)

## ライセンス

© 2026 Yuki Ishikawa
