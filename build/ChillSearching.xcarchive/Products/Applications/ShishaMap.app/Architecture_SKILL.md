# iOS アーキテクチャガイド

## 概要

ShishaMapはMVVM + Repositoryパターンを採用する。
このSkillはViewModel設計・Repository抽象化・依存性注入の詳細ガイドを提供する。

---

## MVVM レイヤー責務

| レイヤー | 責務 | 禁止事項 |
|---|---|---|
| View | 表示・ユーザー入力の受け取り | ビジネスロジック・API呼び出し |
| ViewModel | 状態管理・ユースケース実行 | UIコンポーネントの参照 |
| Repository | データ取得・永続化の抽象化 | ViewModel・Viewの参照 |

---

## StoreViewModel 完全実装例

```swift
@Observable final class StoreViewModel {
    // MARK: - 公開状態
    var stores: [Store] = []
    var isLoading = false
    var errorMessage: String?
    var filter = FilterCriteria()

    // MARK: - 非公開
    private let repository: StoreRepositoryProtocol

    // MARK: - 初期化（DI）
    init(repository: StoreRepositoryProtocol = PlacesRepository()) {
        self.repository = repository
    }

    // MARK: - ユースケース

    /// 現在地周辺の店舗を取得する
    func fetchNearby(coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            stores = try await repository.fetchNearby(
                coordinate: coordinate,
                radius: filter.radiusMeters
            )
        } catch {
            errorMessage = AppError(from: error).localizedDescription
        }
    }

    /// フィルターを適用して表示店舗を絞り込む（クライアントサイド）
    var filteredStores: [Store] {
        stores.filter { store in
            (!filter.openNow || store.isOpenNow) &&
            (!filter.hasPrivateRoom || store.hasPrivateRoom) &&
            (store.priceLevel ?? 0) <= filter.maxPriceLevel &&
            (filter.flavorTags.isEmpty || !filter.flavorTags.isDisjoint(with: store.flavors))
        }
    }
}
```

---

## Repository パターン

### プロトコル定義

```swift
protocol StoreRepositoryProtocol {
    /// 指定座標の半径radius(m)以内のシーシャ店を返す
    func fetchNearby(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store]
    /// placeIDで1件取得（詳細画面用）
    func fetchDetail(placeID: String) async throws -> Store
}
```

### MockStoreRepository（Preview・テスト共用）

```swift
final class MockStoreRepository: StoreRepositoryProtocol {
    func fetchNearby(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        return Store.mocks  // Store.swift に定義した固定フィクスチャ
    }
    func fetchDetail(placeID: String) async throws -> Store {
        return Store.mocks[0]
    }
}
```

### フィクスチャ定義（Store.swift内）

```swift
extension Store {
    static let mocks: [Store] = [
        Store(placeID: "mock_001", name: "シーシャ東京", address: "渋谷区道玄坂1-1",
              latitude: 35.6580, longitude: 139.7016, hasPrivateRoom: true,
              flavors: ["フルーツ系", "ミント系"]),
        Store(placeID: "mock_002", name: "HOOKAH LOUNGE", address: "新宿区歌舞伎町2-2",
              latitude: 35.6938, longitude: 139.7034, hasPrivateRoom: false,
              flavors: ["スパイス系"])
    ]
}
```

---

## 環境注入パターン（App → View）

```swift
@main
struct ShishaMapApp: App {
    @State private var viewModel = StoreViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .modelContainer(for: [Store.self, CheckIn.self])
        }
    }
}

// View側での受け取り
struct MapView: View {
    @Environment(StoreViewModel.self) private var viewModel
    // ...
}
```

---

## 新機能追加時のチェックリスト

1. `StoreRepositoryProtocol` にメソッドを追加
2. `PlacesRepository` に本番実装を追加
3. `MockStoreRepository` にフィクスチャ実装を追加
4. `StoreViewModel` にユースケースメソッドを追加
5. Viewはメソッド呼び出しのみ（ロジックを書かない）
6. `#Preview` が `MockStoreRepository` で動作することを確認
