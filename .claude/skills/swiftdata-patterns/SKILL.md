# SwiftData パターンガイド

## 概要

ShishaMapのローカル永続化はSwiftDataで行う。
このSkillはモデル定義・@Query・CRUD操作・マイグレーションの実装パターンを提供する。

---

## モデル定義

```swift
// Models/Store.swift
@Model final class Store {
    @Attribute(.unique) var placeID: String
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var openingHours: [String]   // Places APIからの生文字列
    var flavors: [String]        // 例: ["フルーツ系", "ミント系"]
    var priceLevel: Int?         // 1〜4
    var hasPrivateRoom: Bool
    var photoReference: String?
    var isFavorite: Bool = false
    @Relationship(deleteRule: .cascade) var checkIns: [CheckIn] = []

    init(placeID: String, name: String, address: String,
         latitude: Double, longitude: Double,
         hasPrivateRoom: Bool = false, flavors: [String] = []) {
        self.placeID = placeID; self.name = name; self.address = address
        self.latitude = latitude; self.longitude = longitude
        self.hasPrivateRoom = hasPrivateRoom; self.flavors = flavors
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Models/CheckIn.swift
@Model final class CheckIn {
    var date: Date
    var note: String?
    var store: Store?

    init(date: Date = .now, note: String? = nil, store: Store? = nil) {
        self.date = date; self.note = note; self.store = store
    }
}
```

---

## ModelContainer セットアップ

```swift
// ShishaMapApp.swift
.modelContainer(for: [Store.self, CheckIn.self])
```

---

## @Query パターン

```swift
// お気に入り一覧（FavoritesView）
@Query(filter: #Predicate<Store> { $0.isFavorite },
       sort: \.name)
private var favorites: [Store]

// チェックイン履歴（日付降順）
@Query(sort: \CheckIn.date, order: .reverse)
private var checkIns: [CheckIn]
```

---

## CRUD 操作

### お気に入り登録・解除（View内で直接操作可）

```swift
// StoreDetailView
store.isFavorite.toggle()  // @Modelは変更を自動検知・保存する
```

### チェックイン追加

```swift
// ViewModel経由は不要。ViewのmodelContextで直接insert
@Environment(\.modelContext) private var modelContext

func checkIn(to store: Store, note: String? = nil) {
    let record = CheckIn(date: .now, note: note, store: store)
    modelContext.insert(record)
}
```

### チェックイン削除（スワイプ削除）

```swift
.onDelete { indexSet in
    indexSet.forEach { modelContext.delete(checkIns[$0]) }
}
```

---

## マイグレーション方針

- v1.0はスキーマバージョン管理不要（初期リリース）
- フィールド追加時は `@Attribute` のデフォルト値を必ず設定し後方互換を保つ
- 破壊的変更が必要な場合は `VersionedSchema` + `MigrationPlan` を使う（v2.0以降）
