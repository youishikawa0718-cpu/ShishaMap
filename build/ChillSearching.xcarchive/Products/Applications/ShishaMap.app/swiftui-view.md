# SwiftUI View 規約 — rules/swiftui-view.md

`Features/` および `*View.swift` に自動適用。

## View 実装

- `body` は60行以内。超えたらサブViewに切り出す
- ビジネスロジックを `body` に書かない。ViewModelのメソッドを呼ぶだけにする
- `@StateObject` / `@ObservedObject` は使用禁止。`@Environment` + `@Observable` を使う
- 一時的なUI状態（シート表示フラグ等）のみ `@State` を使う

## Preview

- すべてのViewファイルに `#Preview` を必ず含める
- `#Preview` では `MockStoreRepository` を使う。本番APIを呼ばない

```swift
#Preview {
    StoreDetailView(store: .mock)
        .environment(StoreViewModel(repository: MockStoreRepository()))
}
```

## SwiftData との連携

- シンプルな読み取り専用リストには `@Query` をView内で直接使ってよい
- 書き込み（insert / delete）は必ず `modelContext` 経由で行う
- `@Query` に複雑なフィルターを書く場合は `FilterCriteria` の `#Predicate` を使う
