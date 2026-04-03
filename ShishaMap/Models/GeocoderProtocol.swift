import CoreLocation

/// ジオコーディングの抽象化プロトコル
protocol GeocoderProtocol: Sendable {
    func coordinate(for address: String) async throws -> CLLocationCoordinate2D
}

/// CLGeocoderを使用した本番実装
struct LocationGeocoder: GeocoderProtocol {
    func coordinate(for address: String) async throws -> CLLocationCoordinate2D {
        let placemarks = try await CLGeocoder().geocodeAddressString(address)
        guard let location = placemarks.first?.location else {
            throw AppError.geocodingFailed
        }
        return location.coordinate
    }
}
