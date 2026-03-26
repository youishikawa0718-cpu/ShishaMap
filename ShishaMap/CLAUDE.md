# CLAUDE.md — ShishaMap iOS App

## プロジェクト概要

ShishaMapはシーシャ愛好家向けのiOSアプリ。インタラクティブな地図を使って近隣のシーシャ店を
発見・フィルタリング・保存できる。SwiftUI + MapKit、iOS 17以上、iPhone専用。

## 技術スタック

- **言語**: Swift 5.10 / **UI**: SwiftUI / **アーキテクチャ**: MVVM（`@Observable`）
- **永続化**: SwiftData / **地図**: MapKit / **位置情報**: CoreLocation
- **外部データ**: Google Places API（REST、async/await）/ **最小ターゲット**: iOS 17.0

## プロジェクト構成

```
ShishaMap/
├── ShishaMapApp.swift
├── Features/
│   ├── Map/        MapView, StoreAnnotationView, MiniCardView
│   ├── Search/     SearchView, FilterSheetView
│   ├── Detail/     StoreDetailView
│   └── Favorites/  FavoritesView, CheckInHistoryView
├── Models/         Store.swift, CheckIn.swift, FilterCriteria.swift
├── Repositories/   StoreRepositoryProtocol, PlacesRepository, MockStoreRepository
└── ViewModels/     StoreViewModel.swift
```

## Skills 使用ガイド

Claudeはタスクの内容に応じて以下のSkillsを自律的に参照すること。

| Skill | 参照すべきタスク |
|---|---|
| `ios-architecture` | MVVM設計・ViewModel実装・Repositoryパターン・新機能追加 |
| `swiftdata-patterns` | SwiftDataモデル定義・@Query・マイグレーション |
| `mapkit-guide` | マップ表示・ピン・クラスタリング・カメラ操作 |
| `places-api-guide` | Google Places API連携・キャッシュ・Codable定義 |
| `error-handling` | AppError定義・エラー表示・リトライ設計 |

## v1.0のスコープ外

ユーザーアカウント・認証 / ユーザー投稿レビュー・写真 / Android・iPad / プッシュ通知 / オフラインマップ
