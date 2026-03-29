# iOS UI/UX デザインガイド — Apple HIG 準拠

## 概要

ShishaMap の UI/UX 実装において Apple Human Interface Guidelines (HIG) に準拠するためのSkill。
レイアウト・タイポグラフィ・カラー・ナビゲーション・アクセシビリティ・インタラクションの
ベストプラクティスを網羅する。

**参照元**: https://developer.apple.com/design/human-interface-guidelines

---

## 1. レイアウトと間隔

### Safe Area

```swift
// Safe Area を必ず尊重する。edgesIgnoringSafeArea は背景のみに使用
VStack {
    content
}
.safeAreaInset(edge: .bottom) {
    bottomBar
}
```

### 間隔の標準値

| 用途 | 値 | 備考 |
|---|---|---|
| 画面端マージン | 16pt | `.padding()` デフォルト |
| セクション間 | 20-32pt | 視覚的グループ分離 |
| 関連要素間 | 8pt | 同グループ内の要素 |
| タッチターゲット最小 | 44x44pt | **絶対に下回らない** |

### レイアウト原則

- **余白を恐れない**: 密集させず呼吸させる
- **視覚的階層**: サイズ・太さ・色で優先度を表現
- **一貫性**: 同じ種類の要素は同じ間隔・配置
- `LazyVStack` / `LazyHStack` でリスト系は遅延読み込み

```swift
// 良い例: 標準マージンとタッチターゲット
List {
    ForEach(stores) { store in
        StoreRow(store: store)
            .frame(minHeight: 44) // タッチターゲット確保
    }
}
.listStyle(.plain)
```

---

## 2. タイポグラフィ

### Dynamic Type 必須対応

```swift
// 必ずシステムテキストスタイルを使う
Text(store.name)
    .font(.headline)       // 17pt semibold (デフォルト)

Text(store.address)
    .font(.subheadline)    // 15pt regular
    .foregroundStyle(.secondary)

Text("距離: \(distance)")
    .font(.caption)        // 12pt regular
```

### テキストスタイル一覧（iOS）

| スタイル | デフォルトサイズ | 用途 |
|---|---|---|
| `.largeTitle` | 34pt | 画面タイトル（NavigationBar） |
| `.title` | 28pt | セクションタイトル |
| `.title2` | 22pt | サブセクション |
| `.title3` | 20pt | カード見出し |
| `.headline` | 17pt semibold | 強調テキスト |
| `.body` | 17pt | 本文 |
| `.callout` | 16pt | 補足説明 |
| `.subheadline` | 15pt | 二次情報 |
| `.footnote` | 13pt | 注釈 |
| `.caption` | 12pt | メタ情報 |
| `.caption2` | 11pt | 最小テキスト |

### 禁止事項

- **フォントサイズのハードコード禁止**: `.font(.system(size: 14))` ではなく `.font(.subheadline)`
- **固定高さのテキストコンテナ禁止**: Dynamic Type でテキストが大きくなっても切れないようにする
- **長いテキストに `lineLimit(1)` を安易に使わない**: truncation よりレイアウト調整を優先

```swift
// 悪い例
Text(title).font(.system(size: 16))

// 良い例
Text(title).font(.body)
```

---

## 3. カラー

### セマンティックカラーを使う

```swift
// システムカラー（ダークモード自動対応）
Text(store.name)
    .foregroundStyle(.primary)         // ラベル（白/黒自動切替）

Text(store.address)
    .foregroundStyle(.secondary)       // 二次テキスト

VStack { }
    .background(.systemBackground)     // 背景
    .background(.secondarySystemBackground) // グループ背景
```

### カラーパレット原則

| 原則 | 説明 |
|---|---|
| アクセントカラー | アプリ全体で1色に統一。ShishaMapは `.accentColor` で設定 |
| セマンティック使用 | `.red` は破壊的操作、`.green` は成功、`.orange` は警告 |
| ダークモード | 必ず両モードで確認。カスタムカラーは Asset Catalog で定義 |
| コントラスト比 | テキスト: 最低 4.5:1、大文字: 最低 3:1（WCAG AA） |

### カスタムカラー定義

```swift
// Asset Catalog で Light/Dark 両方定義した上で使用
extension Color {
    static let shishaAccent = Color("ShishaAccent")
    static let shishaBackground = Color("ShishaBackground")
}
```

### 禁止事項

- **`.black` / `.white` の直接使用禁止**: ダークモードで破綻する
- **透明度でコントラストを下げすぎない**: `.opacity(0.3)` のテキストはNG
- **色だけで情報を伝えない**: 色覚多様性に配慮し、アイコン・テキストを併用

---

## 4. ナビゲーション

### NavigationStack（iOS 16+）

```swift
// NavigationStack + navigationDestination パターン
NavigationStack {
    MapView()
        .navigationTitle("ShishaMap")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
}
```

### ナビゲーション原則

| 原則 | 実装 |
|---|---|
| 予測可能性 | 戻るボタンは常に左上。カスタマイズしない |
| フラット構造 | TabView で主要機能を分離。深い階層を避ける |
| モーダル使用 | 自己完結タスク（フィルター設定等）のみ `.sheet` |
| 情報アーキテクチャ | 3タップ以内で目的に到達 |

### TabView 構成

```swift
TabView {
    Tab("マップ", systemImage: "map") {
        MapView()
    }
    Tab("検索", systemImage: "magnifyingglass") {
        SearchView()
    }
    Tab("お気に入り", systemImage: "heart.fill") {
        FavoritesView()
    }
}
```

### Sheet / FullScreenCover 使い分け

```swift
// Sheet: 部分的なタスク（フィルター、詳細プレビュー）
.sheet(isPresented: $showFilter) {
    FilterSheetView()
        .presentationDetents([.medium, .large])  // ハーフモーダル対応
        .presentationDragIndicator(.visible)
}

// FullScreenCover: 没入型タスク（写真ビューア等）
.fullScreenCover(isPresented: $showFullImage) {
    ImageViewer(url: imageURL)
}
```

---

## 5. コンポーネントとインタラクション

### ボタン

```swift
// プライマリアクション
Button("お気に入りに追加") {
    viewModel.toggleFavorite(store)
}
.buttonStyle(.borderedProminent)

// セカンダリアクション
Button("共有") {
    showShareSheet = true
}
.buttonStyle(.bordered)

// 破壊的アクション
Button("削除", role: .destructive) {
    viewModel.delete(store)
}
```

### フィードバック

```swift
// 触覚フィードバック（重要なアクション時）
import SwiftUI

// ボタンタップ時
.sensoryFeedback(.impact(weight: .medium), trigger: isFavorite)

// 成功時
.sensoryFeedback(.success, trigger: checkInCompleted)

// エラー時
.sensoryFeedback(.error, trigger: errorOccurred)
```

### ローディング状態

```swift
// ローディング中はコンテンツの位置を維持
ZStack {
    if viewModel.isLoading {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
        contentView
    }
}

// リスト内のインクリメンタルローディング
List {
    ForEach(stores) { store in
        StoreRow(store: store)
    }
    if viewModel.hasMore {
        ProgressView()
            .onAppear { Task { await viewModel.loadMore() } }
    }
}
```

### 空状態

```swift
// 空状態は必ず案内を表示
ContentUnavailableView(
    "店舗が見つかりません",
    systemImage: "map",
    description: Text("検索条件を変更するか、地図を移動してみてください")
)
```

---

## 6. アクセシビリティ

### 必須対応事項

```swift
// 1. VoiceOver ラベル
Image(systemName: "heart.fill")
    .accessibilityLabel("お気に入り")

// 2. アクセシビリティ値
StarRatingView(rating: store.rating)
    .accessibilityValue("\(store.rating)つ星")

// 3. ボタンのヒント
Button { } label: {
    Image(systemName: "phone")
}
.accessibilityLabel("電話をかける")
.accessibilityHint("\(store.name)に電話します")
```

### Dynamic Type 対応

```swift
// 大きなテキストサイズでレイアウトが崩れないようにする
@Environment(\.dynamicTypeSize) private var typeSize

var body: some View {
    if typeSize >= .accessibility1 {
        // 縦並びレイアウト
        VStack(alignment: .leading) {
            storeInfo
            actionButtons
        }
    } else {
        // 横並びレイアウト
        HStack {
            storeInfo
            Spacer()
            actionButtons
        }
    }
}
```

### Reduce Motion 対応

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// アニメーションを条件付きにする
withAnimation(reduceMotion ? .none : .spring()) {
    showDetail = true
}
```

### チェックリスト

- [ ] すべてのインタラクティブ要素に `accessibilityLabel` がある
- [ ] 画像に `accessibilityLabel` または `.accessibilityHidden(true)`（装飾用）
- [ ] Dynamic Type の最大サイズ（AX5）でレイアウトが崩れない
- [ ] VoiceOver でアプリ全体を操作できる
- [ ] カラーコントラスト比が WCAG AA 以上
- [ ] Reduce Motion 有効時にアニメーションが無効化される

---

## 7. アニメーションとトランジション

### 原則

- **目的のあるアニメーション**: 装飾ではなく状態変化の理解を助ける
- **短く軽く**: 0.2〜0.4秒。長いアニメーションはユーザーを待たせる
- **システム標準を優先**: カスタムアニメーションより `.spring()` や `.easeInOut`

```swift
// 状態変化に連動するアニメーション
.animation(.spring(duration: 0.3), value: isExpanded)

// リスト変更のトランジション
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

---

## 8. アイコンと SF Symbols

### SF Symbols を優先使用

```swift
// SF Symbols は Dynamic Type・アクセシビリティ・ローカライズに自動対応
Label("お気に入り", systemImage: "heart.fill")

// サイズはテキストスタイルに合わせる
Image(systemName: "mappin.circle.fill")
    .font(.title2)
    .foregroundStyle(.shishaAccent)

// シンボルレンダリングモード
Image(systemName: "heart.circle.fill")
    .symbolRenderingMode(.hierarchical)  // 階層的カラー
```

### アイコン選択ガイド（ShishaMap用）

| 用途 | SF Symbol |
|---|---|
| 地図 | `map` / `map.fill` |
| 店舗ピン | `mappin.circle.fill` |
| 検索 | `magnifyingglass` |
| フィルター | `line.3.horizontal.decrease.circle` |
| お気に入り | `heart` / `heart.fill` |
| チェックイン | `checkmark.circle` / `checkmark.circle.fill` |
| 電話 | `phone` / `phone.fill` |
| ウェブ | `safari` |
| 共有 | `square.and.arrow.up` |
| 営業時間 | `clock` |
| 距離 | `location.fill` |
| 星評価 | `star.fill` |
| 設定 | `gearshape` |

---

## 9. Sheet / Modal デザイン

### presentationDetents（iOS 16+）

```swift
.sheet(isPresented: $showDetail) {
    StoreDetailView(store: store)
        .presentationDetents([.medium, .fraction(0.7), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .presentationBackground(.regularMaterial) // すりガラス
}
```

### ConfirmationDialog（破壊操作）

```swift
.confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
    Button("削除", role: .destructive) {
        viewModel.deleteFavorite(store)
    }
    Button("キャンセル", role: .cancel) { }
} message: {
    Text("この操作は取り消せません")
}
```

---

## 10. 地図UI特有のガイドライン（ShishaMap固有）

### マップ上のUI配置

```swift
Map {
    // アノテーション
}
.mapControls {
    MapUserLocationButton()  // 現在地ボタン（右上）
    MapCompass()             // コンパス
    MapScaleView()           // スケール
}
.safeAreaInset(edge: .bottom) {
    // ミニカード: 地図の下部にオーバーレイ
    MiniCardView(store: selectedStore)
        .padding()
        .background(.ultraThinMaterial)
}
```

### ピン/アノテーション

- 44pt 以上のタッチ領域を確保
- 選択状態を明確に（サイズ拡大 + カラー変更）
- 密集時はクラスタリングで整理

### ボトムシート（店舗詳細）

- デフォルト: `.medium`（画面半分）→ スワイプで `.large`
- 地図は背景として維持（FullScreenCover にしない）
- シート内はスクロール可能にする

---

## クイックリファレンス: やること / やらないこと

### やること

- セマンティックカラー・フォントスタイルを使う
- 44pt 以上のタッチターゲット
- ダークモードでの表示確認
- VoiceOver での操作確認
- `ContentUnavailableView` で空状態を案内
- 破壊操作に `confirmationDialog` を使う
- 触覚フィードバックで重要な操作を強調

### やらないこと

- フォントサイズ・カラーのハードコード
- `.black` / `.white` の直接使用
- 44pt 未満のタッチターゲット
- 深すぎるナビゲーション階層（4段以上）
- 目的のないアニメーション
- 色だけで意味を伝える（アイコン・テキスト併用）
- `Alert` の多用（本当に重要な場面のみ）
