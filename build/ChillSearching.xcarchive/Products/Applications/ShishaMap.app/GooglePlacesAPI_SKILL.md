# Google Places API 実装ガイド

## 概要

ShishaMapの店舗データはGoogle Places APIから取得する。
このSkillはAPIキー管理・リクエスト・Codableパース・キャッシュの実装パターンを提供する。

---

## APIキー管理

APIキーはソースコードに直書きしない。

```
# Secrets.xcconfig（.gitignoreに追加すること）
PLACES_API_KEY = YOUR_API_KEY_HERE
```

```xml
<!-- Info.plist -->
<key>PLACES_API_KEY</key>
<string>$(PLACES_API_KEY)</string>
```

```swift
// 読み込み
let apiKey = Bundle.main.infoDictionary?["PLACES_API_KEY"] as? String ?? ""
```

---

## エンドポイントと検索パラメータ

```
GET https://maps.googleapis.com/maps/api/place/nearbysearch/json
  ?location={lat},{lng}
  &radius={radius}
  &keyword=シーシャ OR hookah OR shisha
  &language=ja
  &key={PLACES_API_KEY}
```

---

## Codable レスポンス定義

```swift
// Repositories/PlacesResponse.swift
struct PlacesResponse: Decodable {
    let results: [PlaceResult]
    let status: String
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case results, status
        case nextPageToken = "next_page_token"
    }
}

struct PlaceResult: Decodable {
    let placeId: String
    let name: String
    let vicinity: String            // 住所
    let geometry: Geometry
    let openingHours: OpeningHours?
    let priceLevel: Int?
    let photos: [Photo]?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, vicinity, geometry
        case openingHours = "opening_hours"
        case priceLevel = "price_level"
        case photos
    }
}

struct Geometry: Decodable {
    let location: Location
    struct Location: Decodable { let lat: Double; let lng: Double }
}

struct OpeningHours: Decodable {
    let openNow: Bool?
    enum CodingKeys: String, CodingKey { case openNow = "open_now" }
}

struct Photo: Decodable {
    let photoReference: String
    enum CodingKeys: String, CodingKey { case photoReference = "photo_reference" }
}
```

---

## PlacesRepository 実装

```swift
// Repositories/PlacesRepository.swift
final class PlacesRepository: StoreRepositoryProtocol {
    private let apiKey: String
    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheLifetime: TimeInterval = 300  // 5分

    init() {
        self.apiKey = Bundle.main.infoDictionary?["PLACES_API_KEY"] as? String ?? ""
    }

    func fetchNearby(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude),\(radius)" as NSString
        if let entry = cache.object(forKey: cacheKey), entry.isValid {
            return entry.stores
        }

        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
        components.queryItems = [
            .init(name: "location", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            .init(name: "radius", value: String(Int(radius))),
            .init(name: "keyword", value: "シーシャ OR hookah OR shisha"),
            .init(name: "language", value: "ja"),
            .init(name: "key", value: apiKey)
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
        let stores = response.results.map { Store(from: $0) }

        cache.setObject(CacheEntry(stores: stores), forKey: cacheKey)
        return stores
    }
}

// キャッシュエントリ
private final class CacheEntry {
    let stores: [Store]
    let timestamp = Date()
    var isValid: Bool { Date().timeIntervalSince(timestamp) < 300 }
    init(stores: [Store]) { self.stores = stores }
}
```

---

## Store への変換

```swift
extension Store {
    convenience init(from result: PlaceResult) {
        self.init(
            placeID: result.placeId,
            name: result.name,
            address: result.vicinity,
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng,
            hasPrivateRoom: false,  // Places APIでは不明 → 詳細取得時に更新
            flavors: []
        )
        self.priceLevel = result.priceLevel
        self.photoReference = result.photos?.first?.photoReference
    }
}
```

---

## 写真URL生成

```swift
func photoURL(reference: String, maxWidth: Int = 400) -> URL? {
    URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxWidth)&photoreference=\(reference)&key=\(apiKey)")
}
```
