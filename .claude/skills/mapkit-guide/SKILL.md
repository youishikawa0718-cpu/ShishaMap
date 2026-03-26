# MapKit 実装ガイド

## 概要

ShishaMapのマップ機能はSwiftUI `Map` APIとMapKitを組み合わせて実装する。
このSkillはピン表示・クラスタリング・カメラ操作・位置情報取得の実装パターンを提供する。

---

## 基本セットアップ

```swift
// Features/Map/MapView.swift
struct MapView: View {
    @Environment(StoreViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .tokyo)
    @State private var selectedStore: Store?

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedStore) {
            UserAnnotation()
            ForEach(viewModel.filteredStores) { store in
                Annotation(store.name, coordinate: store.coordinate) {
                    StoreAnnotationView(store: store)
                        .tag(store)
                }
            }
        }
        .mapControls { MapCompass(); MapUserLocationButton() }
        .onMapCameraChange(frequency: .onEnd) { context in
            Task { await viewModel.fetchNearby(coordinate: context.region.center) }
        }
        .sheet(item: $selectedStore) { store in
            MiniCardView(store: store)
                .presentationDetents([.height(140)])
                .presentationBackgroundInteraction(.enabled)
        }
    }
}
```

---

## デバウンス処理（API過剰呼び出し防止）

```swift
// StoreViewModel.swift
private var fetchTask: Task<Void, Never>?

func fetchNearbyDebounced(coordinate: CLLocationCoordinate2D) {
    fetchTask?.cancel()
    fetchTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await fetchNearby(coordinate: coordinate)
    }
}
```

---

## ピンのクラスタリング

SwiftUI `Map` APIの `Annotation` はネイティブにクラスタリングをサポートしない。
20件超の場合は `MapAnnotationCluster` を使うか、ズームレベルに応じて表示件数を制限する。

```swift
// 簡易実装：ズームレベルに応じた表示制限
var visibleStores: [Store] {
    let span = currentRegion.span.latitudeDelta
    let limit = span > 0.1 ? 20 : stores.count  // 広域は20件まで
    return Array(filteredStores.prefix(limit))
}
```

---

## カメラ操作

```swift
// 現在地に戻るボタン
Button { cameraPosition = .userLocation(fallback: .tokyo) } label: {
    Image(systemName: "location.fill")
}

// 特定の店舗にフォーカス（検索結果タップ時）
func focus(on store: Store) {
    withAnimation {
        cameraPosition = .region(MKCoordinateRegion(
            center: store.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        ))
    }
}
```

---

## CoreLocation 権限リクエスト

```swift
// LocationManager.swift
@Observable final class LocationManager: NSObject, CLLocationManagerDelegate {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
}
```

---

## Info.plist に必須追加

```
NSLocationWhenInUseUsageDescription
→ "近くのシーシャ店を地図に表示するために現在地を使用します"
```

---

## フォールバック座標

```swift
extension MapCameraPosition {
    static let tokyo = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        latitudinalMeters: 3000, longitudinalMeters: 3000
    ))
}
```
