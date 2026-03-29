# テスト規約 — rules/swift-test.md

`*Tests.swift` に自動適用。

## 基本方針

- XCTestを使う
- テスト対象をローカル変数 `sut`（System Under Test）に統一する
- Arrange / Act / Assert の3ブロック構造で書く

```swift
func test_fetchNearby_returnsStores() async throws {
    // Arrange
    let sut = StoreViewModel(repository: MockStoreRepository())

    // Act
    await sut.fetchNearby(coordinate: .tokyo)

    // Assert
    XCTAssertFalse(sut.stores.isEmpty)
    XCTAssertNil(sut.errorMessage)
}
```

## MockStoreRepository

- `StoreViewModel` のユニットテストは必ず `MockStoreRepository` を注入する
- 本番APIやネットワークを呼ぶテストは書かない

## カバレッジ対象

- `StoreViewModel` の全publicメソッド
- `FilterCriteria` のPredicateロジック
- UIテスト: 起動 → マップ表示 → ピンタップ → お気に入り登録 のクリティカルパス

## CI

- PRマージ前に全テストをパスさせる。ゼロ失敗が合格基準
