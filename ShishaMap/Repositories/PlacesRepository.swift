import CoreLocation
import Foundation

final class PlacesRepository: StoreRepositoryProtocol {
    private let apiKey: String
    private let cache = NSCache<NSString, CacheEntry>()

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

    func fetchDetail(placeID: String) async throws -> Store {
        // TODO: Places API Detail endpoint
        throw AppError.unknown(NSError(domain: "PlacesRepository", code: -1))
    }
}

// MARK: - Cache

private final class CacheEntry {
    let stores: [Store]
    private let timestamp = Date()
    var isValid: Bool { Date().timeIntervalSince(timestamp) < 300 }
    init(stores: [Store]) { self.stores = stores }
}

// MARK: - Codable

private struct PlacesResponse: Decodable {
    let results: [PlaceResult]
    let status: String

    enum CodingKeys: String, CodingKey {
        case results, status
    }
}

private struct PlaceResult: Decodable {
    let placeId: String
    let name: String
    let vicinity: String
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
}

// MARK: - Store conversion

private extension Store {
    convenience init(from result: PlaceResult) {
        self.init(
            placeID: result.placeId,
            name: result.name,
            address: result.vicinity,
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng
        )
        self.priceLevel = result.priceLevel
        self.photoReference = result.photos?.first?.photoReference
        self.isOpenNow = result.openingHours?.openNow ?? false
    }
}
