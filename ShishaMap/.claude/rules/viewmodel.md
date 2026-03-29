# ViewModel 規約 — rules/viewmodel.md

`*ViewModel.swift` に自動適用。

## 基本構造

- `@Observable final class` で宣言する
- ルートで `.environment()` 注入する。View内で `StoreViewModel()` を直接生成しない
- `init` でRepositoryをDI（依存性注入）する。テスト・Previewで差し替え可能にする

```swift
@Observable final class StoreViewModel {
    private let repository: StoreRepositoryProtocol

    init(repository: StoreRepositoryProtocol = PlacesRepository()) {
        self.repository = repository
    }
}
```

## 公開プロパティ

- `var stores: [Store] = []`  — Viewがバインドする状態
- `var isLoading: Bool = false` — ローディング制御
- `var errorMessage: String?`  — エラー表示（nilで非表示）

## 非同期メソッド

- `async` メソッドで実装。`defer { isLoading = false }` でフラグを確実に解除する
- `URLSession` / `ModelContext` を直接呼ばない。必ずProtocol経由

## 禁止事項

- ViewModelからUIコンポーネントをimportしない（`SwiftUI` 以外）
- `@Published` は使わない（`@Observable` に移行済み）
