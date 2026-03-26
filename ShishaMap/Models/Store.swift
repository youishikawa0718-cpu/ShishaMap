import Foundation
import SwiftData
import CoreLocation

@Model
final class Store {
    @Attribute(.unique) var placeID: String
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var openingHours: [String]
    var flavors: [String]
    var priceLevel: Int?
    var hasPrivateRoom: Bool
    var photoReference: String?
    var isFavorite: Bool
    @Relationship(deleteRule: .cascade) var checkIns: [CheckIn]

    init(
        placeID: String,
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        hasPrivateRoom: Bool = false,
        flavors: [String] = []
    ) {
        self.placeID = placeID
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.hasPrivateRoom = hasPrivateRoom
        self.flavors = flavors
        self.openingHours = []
        self.isFavorite = false
        self.checkIns = []
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension Store {
    static let mocks: [Store] = [
        Store(
            placeID: "mock_001",
            name: "シーシャ東京",
            address: "渋谷区道玄坂1-1",
            latitude: 35.6580,
            longitude: 139.7016,
            hasPrivateRoom: true,
            flavors: ["フルーツ系", "ミント系"]
        ),
        Store(
            placeID: "mock_002",
            name: "HOOKAH LOUNGE",
            address: "新宿区歌舞伎町2-2",
            latitude: 35.6938,
            longitude: 139.7034,
            hasPrivateRoom: false,
            flavors: ["スパイス系"]
        ),
        Store(
            placeID: "mock_003",
            name: "シーシャバー六本木",
            address: "港区六本木3-3",
            latitude: 35.6628,
            longitude: 139.7319,
            hasPrivateRoom: true,
            flavors: ["フルーツ系", "フローラル系"]
        )
    ]

    static var mock: Store { mocks[0] }
}
