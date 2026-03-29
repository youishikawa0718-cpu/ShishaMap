import CoreLocation
import Foundation

final class PlacesRepository: StoreRepositoryProtocol {
    private let apiKey: String
    private let cache = NSCache<NSString, CacheEntry>()

    init() {
        self.apiKey = (Bundle.main.infoDictionary?["PLACES_API_KEY"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func fetchNearby(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        #if DEBUG
        guard !apiKey.isEmpty else { throw AppError.apiKeyMissing }
        #else
        guard !apiKey.isEmpty else { return [] }
        #endif

        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude),\(radius)" as NSString
        if let entry = cache.object(forKey: cacheKey), entry.isValid {
            return entry.stores
        }

        var allResults: [PlaceResult] = []
        var pageToken: String? = nil
        var pageCount = 0

        repeat {
            // Places API requires ~2s before next_page_token becomes valid
            if pageToken != nil {
                try await Task.sleep(for: AppConstants.API.paginationDelay)
            }

            guard var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json") else {
                throw AppError.unknown(NSError(domain: "PlacesRepository", code: -1))
            }
            var queryItems: [URLQueryItem] = [
                .init(name: "language", value: "ja"),
                .init(name: "key", value: apiKey)
            ]
            if let token = pageToken {
                queryItems.append(.init(name: "pagetoken", value: token))
            } else {
                queryItems += [
                    .init(name: "location", value: "\(coordinate.latitude),\(coordinate.longitude)"),
                    .init(name: "radius", value: String(Int(radius))),
                    .init(name: "keyword", value: "シーシャ OR hookah OR shisha")
                ]
            }
            components.queryItems = queryItems

            guard let url = components.url else {
                throw AppError.unknown(NSError(domain: "PlacesRepository", code: -1))
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            try validateHTTPResponse(response)

            let decoded = try JSONDecoder().decode(PlacesResponse.self, from: data)
            try validateAPIStatus(decoded.status)

            allResults += decoded.results
            pageToken = decoded.nextPageToken
            pageCount += 1
        } while pageToken != nil && pageCount < AppConstants.API.maxPaginationPages

        var seen = Set<String>()
        let stores = allResults
            .filter { seen.insert($0.placeId).inserted }
            .map { Store(from: $0) }

        cache.setObject(CacheEntry(stores: stores), forKey: cacheKey)
        return stores
    }

    func fetchDetail(placeID: String) async throws -> Store {
        #if DEBUG
        guard !apiKey.isEmpty else { throw AppError.apiKeyMissing }
        #else
        guard !apiKey.isEmpty else {
            throw AppError.unknown(NSError(domain: "PlacesRepository", code: -1))
        }
        #endif

        let cacheKey = "detail_\(placeID)" as NSString
        if let entry = cache.object(forKey: cacheKey), entry.isValid, let store = entry.stores.first {
            return store
        }

        guard var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/details/json") else {
            throw AppError.unknown(NSError(domain: "PlacesRepository", code: -1))
        }
        components.queryItems = [
            .init(name: "place_id", value: placeID),
            .init(name: "fields", value: "name,formatted_address,formatted_phone_number,website,opening_hours,photos,price_level,rating,user_ratings_total"),
            .init(name: "language", value: "ja"),
            .init(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            throw AppError.unknown(NSError(domain: "PlacesRepository", code: -1))
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateHTTPResponse(response)

        let decoded = try JSONDecoder().decode(PlaceDetailResponse.self, from: data)
        try validateAPIStatus(decoded.status)

        let store = Store(from: decoded.result, placeID: placeID)
        cache.setObject(CacheEntry(stores: [store]), forKey: cacheKey)
        return store
    }

    // MARK: - Validation

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200: break
        case 429: throw AppError.rateLimitExceeded
        case 401, 403: throw AppError.apiKeyMissing
        case 400..<500: throw AppError.unknown(NSError(domain: "Places", code: http.statusCode))
        case 500...: throw AppError.networkUnavailable
        default: break
        }
    }

    private func validateAPIStatus(_ status: String) throws {
        switch status {
        case "OK", "ZERO_RESULTS": break
        case "REQUEST_DENIED": throw AppError.apiKeyMissing
        case "OVER_QUERY_LIMIT": throw AppError.rateLimitExceeded
        default:
            throw AppError.unknown(NSError(
                domain: "Places",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: status]
            ))
        }
    }
}

// MARK: - Cache

private final class CacheEntry {
    let stores: [Store]
    private let timestamp = Date()
    var isValid: Bool { Date().timeIntervalSince(timestamp) < AppConstants.Cache.ttl }
    init(stores: [Store]) { self.stores = stores }
}

// MARK: - Nearby Search Codable

private struct PlacesResponse: Decodable {
    let results: [PlaceResult]
    let status: String
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case results, status
        case nextPageToken = "next_page_token"
    }
}

private struct PlaceResult: Decodable {
    let placeId: String
    let name: String
    let vicinity: String
    let geometry: Geometry
    let openingHours: OpeningHours?
    let priceLevel: Int?
    let photos: [PhotoRef]?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, vicinity, geometry
        case openingHours = "opening_hours"
        case priceLevel = "price_level"
        case photos
    }

    struct Geometry: Decodable {
        let location: Location
        struct Location: Decodable { let lat: Double; let lng: Double }
    }

    struct OpeningHours: Decodable {
        let openNow: Bool?
        enum CodingKeys: String, CodingKey { case openNow = "open_now" }
    }
}

// MARK: - Details Codable

private struct PlaceDetailResponse: Decodable {
    let result: PlaceDetail
    let status: String
}

private struct PlaceDetail: Decodable {
    let name: String?
    let formattedAddress: String?
    let formattedPhoneNumber: String?
    let website: String?
    let openingHours: DetailOpeningHours?
    let photos: [PhotoRef]?
    let priceLevel: Int?
    let rating: Double?
    let userRatingsTotal: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case formattedAddress = "formatted_address"
        case formattedPhoneNumber = "formatted_phone_number"
        case website
        case openingHours = "opening_hours"
        case photos
        case priceLevel = "price_level"
        case rating
        case userRatingsTotal = "user_ratings_total"
    }

    struct DetailOpeningHours: Decodable {
        let openNow: Bool?
        let weekdayText: [String]?
        enum CodingKeys: String, CodingKey {
            case openNow = "open_now"
            case weekdayText = "weekday_text"
        }
    }
}

private struct PhotoRef: Decodable {
    let photoReference: String
    enum CodingKeys: String, CodingKey { case photoReference = "photo_reference" }
}

// MARK: - フレーバー自動検出

/// 店名・住所テキストからフレーバータグを推定する（案B: キーワードマッチング）
private func detectFlavors(from text: String) -> [String] {
    let rules: [(keywords: [String], tag: String)] = [
        (["フルーツ", "果物", "マンゴー", "ピーチ", "ストロベリー", "レモン", "アップル", "グレープ"], "フルーツ系"),
        (["ミント", "クール", "メンソール"], "ミント系"),
        (["フローラル", "ローズ", "ジャスミン", "花"], "フローラル系"),
        (["スパイス", "シナモン", "カルダモン", "チャイ"], "スパイス系"),
        (["チョコ", "バニラ", "キャラメル", "スイーツ", "デザート"], "スイーツ系"),
        (["コーヒー", "カフェ", "エスプレッソ", "抹茶"], "コーヒー系"),
    ]
    let lower = text.lowercased()
    return rules.compactMap { rule in
        rule.keywords.contains(where: { lower.contains($0.lowercased()) }) ? rule.tag : nil
    }
}

// MARK: - Store conversion

private extension Store {
    convenience init(from result: PlaceResult) {
        self.init(
            placeID: result.placeId,
            name: result.name,
            address: result.vicinity,
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng,
            flavors: detectFlavors(from: result.name)
        )
        self.priceLevel = result.priceLevel
        self.photoReferences = result.photos?.map { $0.photoReference } ?? []
        self.photoReference = self.photoReferences.first
        self.isOpenNow = result.openingHours?.openNow ?? false
    }

    /// Detail APIレスポンスから一時的なDTOを生成する（lat/lngは0のまま）。
    /// StoreViewModel.loadDetail() で既存のSwiftData Storeへマージする。
    convenience init(from detail: PlaceDetail, placeID: String) {
        self.init(
            placeID: placeID,
            name: detail.name ?? "",
            address: detail.formattedAddress ?? "",
            latitude: 0,
            longitude: 0
        )
        self.phoneNumber = detail.formattedPhoneNumber
        self.websiteURL = detail.website
        self.openingHours = detail.openingHours?.weekdayText ?? []
        self.isOpenNow = detail.openingHours?.openNow ?? false
        self.photoReferences = detail.photos?.map { $0.photoReference } ?? []
        self.photoReference = self.photoReferences.first
        self.priceLevel = detail.priceLevel
        self.rating = detail.rating
        self.userRatingsTotal = detail.userRatingsTotal
    }
}
