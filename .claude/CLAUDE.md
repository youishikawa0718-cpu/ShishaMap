# CLAUDE.md — ShishaMap iOS App

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

ShishaMapはシーシャ愛好家向けのiOSアプリ。インタラクティブな地図を使って近隣のシーシャ店を
発見・フィルタリング・保存できる。SwiftUI + MapKitを用いてiOS 17以上を対象として開発する。

## 技術スタック

- **言語**: Swift 5.10
- **UIフレームワーク**: SwiftUI
- **アーキテクチャ**: MVVM（`@Observable` — Swift 5.9 Observationフレームワーク）
- **永続化**: SwiftData
- **地図**: MapKit（SwiftUI `Map` API）
- **位置情報**: CoreLocation
- **外部データ**: Google Places API（REST、async/await）
- **最小ターゲット**: iOS 17.0、iPhone専用

---

## プロジェクト構成

```
ShishaMap/
├── ShishaMapApp.swift               # アプリエントリーポイント、SwiftDataコンテナ設定
├── Features/
│   ├── Map/
│   │   ├── MapView.swift            # メインマップ、店舗ピン表示
│   │   ├── StoreAnnotationView.swift
│   │   └── MiniCardView.swift       # ピンタップ時のミニカード
│   ├── Search/
│   │   ├── SearchView.swift         # キーワード検索＋結果リスト
│   │   └── FilterSheetView.swift    # フィルターボトムシート
│   ├── Detail/
│   │   └── StoreDetailView.swift    # 店舗詳細画面
│   └── Favorites/
│       ├── FavoritesView.swift      # お気に入り一覧
│       └── CheckInHistoryView.swift # チェックイン履歴
├── Models/
│   ├── Store.swift                  # SwiftData @Model
│   ├── CheckIn.swift                # SwiftData @Model
│   └── FilterCriteria.swift         # フィルター状態の値型
├── Repositories/
│   ├── StoreRepositoryProtocol.swift
│   ├── PlacesRepository.swift       # Google Places API実装
│   └── MockStoreRepository.swift    # Preview・テスト用モック
└── ViewModels/
    └── StoreViewModel.swift         # @Observable、環境経由で共有
```

---

## アーキテクチャ規約

### MVVM with @Observable

- ビジネスロジックはすべて`StoreViewModel`に集約する。Viewは純粋な宣言的UIのみ。
- `StoreViewModel`はルートで`.environment()`注入する。View内で直接初期化しない。
- `@Query`（SwiftData）はシンプルな読み取り専用リストに限りView内で使用可。
- 非同期処理は`async/await`を使う。コールバック・クロージャ方式は使用しない。

```swift
// 良い例
@Observable final class StoreViewModel {
    var stores: [Store] = []
    var isLoading = false

    func fetchNearby(coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }
        stores = await repository.fetchNearby(coordinate: coordinate, radius: 1500)
    }
}

// 悪い例 — ロジックがViewに混在している
Button("再読み込み") {
    Task { stores = try await URLSession.shared.data(...) }
}
```

### リポジトリパターン

- `StoreRepositoryProtocol`がすべてのデータソースを抽象化する。
- `PlacesRepository`が本番実装。`MockStoreRepository`が固定フィクスチャを返す。
- ViewModelから`URLSession`や`ModelContext`を直接呼び出さない。必ずProtocol経由。
- SwiftUI Previewはすべて`MockStoreRepository`を使用する（必須）。

### エラーハンドリング

- ユーザー向けエラーは`AppError: LocalizedError`として定義する。
- ViewModelは`var errorMessage: String?`を公開し、Viewはアラートとして反応的に表示する。
- ネットワーク失敗はリカバリー可能にする。リトライボタンを表示し、クラッシュさせない。

---

## データモデル

### Store（SwiftData）

```swift
@Model final class Store {
    @Attribute(.unique) var placeID: String
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var openingHours: [String]    // Places APIからの生文字列
    var flavors: [String]         // 例: ["フルーツ系", "ミント系"]
    var priceLevel: Int?          // 1〜4
    var hasPrivateRoom: Bool
    var photoReference: String?
    var isFavorite: Bool = false
    @Relationship(deleteRule: .cascade) var checkIns: [CheckIn] = []
}
```

### CheckIn（SwiftData）

```swift
@Model final class CheckIn {
    var date: Date
    var note: String?
    var store: Store?
}
```

### FilterCriteria（値型）

```swift
struct FilterCriteria {
    var openNow: Bool = false
    var hasPrivateRoom: Bool = false
    var maxPriceLevel: Int = 4
    var flavorTags: Set<String> = []
    var radiusMeters: Double = 1500

    var isDefault: Bool { ... }  // フィルター未適用のときtrue
}
```

---

## 主要機能と実装上の注意点

### 1. マップ画面

- `MapAnnotation`を使って店舗ピンを表示する。
- 表示件数が20件超の場合は`MKClusterAnnotation`でピンをクラスタリングする。
- ピンタップで`MiniCardView`を`presentationDetents: [.height(140)]`のオーバーレイシートとして表示。
- 現在地ボタンは`MapCameraPosition`でカメラを再センタリングする。
- 表示領域変更のたびに店舗を再取得する。APIコール過多を防ぐため0.5秒デバウンスを挟む。

### 2. 検索・フィルター

- `SearchView`は`NavigationStack`に`.searchable`モディファイアを付与して実装する。
- 結果リストには店舗名・現在地からの距離・営業中バッジを表示する。
- `FilterSheetView`はボトムシートで、トグルと半径スライダーで構成する。
- 結果タップで検索を閉じ、マップを該当店舗ピンにフォーカスする。
- フィルターボタンのアイコンに適用中条件数をバッジ表示する。

### 3. お気に入り・チェックイン

- お気に入りトグルは`store.isFavorite`をSwiftDataモデルに直接書き込む（ViewModel経由不要）。
- チェックインは`CheckIn`レコードを生成し`modelContext.insert()`で保存する。
- `FavoritesView`は`@Query(filter: #Predicate { $0.isFavorite })`でリアルタイム更新する。
- チェックイン履歴は日付降順ソート、スワイプで削除できる。

### 4. 店舗詳細画面

- 写真は`AsyncImage`で遅延読み込みし、ロード中はシマープレースホルダーを表示する。
- ナビボタンは`MKMapItem.openInMaps(launchOptions:)`でApple Mapsを開く。
- フレーバータグはカスタム`Layout`実装の`FlowLayout`で折り返し表示する。
- お気に入り・チェックインボタンはセーフエリア対応の`VStack`で画面下部に固定する。

---

## Google Places API

- エンドポイント: `https://maps.googleapis.com/maps/api/place/nearbysearch/json`
- 検索キーワード: `"シーシャ OR hookah OR shisha"`
- APIキーは`Secrets.xcconfig`に記載しGitignore対象とする。`Bundle.main.infoDictionary`経由で読み込む。
- レスポンスは`PlacesResponse.swift`内の`Codable`構造体でパースする。
- クォータ節約のため`NSCache`を使って5分間メモリキャッシュする。

---

## コーディング規約

詳細なルールは `.claude/rules/` を参照（ファイル種別ごとに自動適用）：

| ファイル | ルールファイル |
|---|---|
| すべての `.swift` | `rules/swift.md` |
| `Features/**`, `*View.swift` | `rules/swiftui-view.md` |
| `*ViewModel.swift` | `rules/viewmodel.md` |
| `*Tests.swift` | `rules/swift-test.md` |

要点：
- **命名**: 型は`UpperCamelCase`、関数・プロパティは`lowerCamelCase`。識別子はすべて英語。
- **View分割**: bodyは60行以内。積極的にサブViewに切り出す。
- **Preview**: すべてのViewファイルに`MockStoreRepository`を使った`#Preview`を必ず含める。
- **状態管理**: `@StateObject`・`@ObservedObject`は使用しない（`@Observable`を使う）。

---

## Skills

実装パターンは `.claude/skills/` を参照：

| Skill | 参照すべきタスク |
|---|---|
| `skills/ios-architecture/` | MVVM設計・ViewModel実装・Repositoryパターン・新機能追加 |
| `skills/swiftdata-patterns/` | SwiftDataモデル定義・`@Query`・マイグレーション |
| `skills/mapkit-guide/` | マップ表示・ピン・クラスタリング・カメラ操作 |
| `skills/places-api-guide/` | Google Places API連携・キャッシュ・Codable定義 |
| `skills/error-handling/` | `AppError`定義・エラー表示・リトライ設計 |

---

## テスト方針

- `StoreViewModel`は`MockStoreRepository`を注入してユニットテストする。
- `FilterCriteria`のPredicateロジックは単独でテストする。
- UIテストはクリティカルパスをカバーする: 起動→マップ上に店舗表示→ピンタップ→お気に入り登録。
- PRマージ前に必ずテストを実行し、ゼロ失敗をCIの合格基準とする。

---

## v1.0のスコープ外

- ユーザーアカウント・認証機能
- ユーザー投稿レビュー・写真
- Android・iPad対応
- プッシュ通知
- オフラインマップタイル
