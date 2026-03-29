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
    var photoReferences: [String] = []
    var websiteURL: String?
    var rating: Double?
    var userRatingsTotal: Int?
    var isOpenNow: Bool
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
        self.photoReferences = []
        self.isOpenNow = false
        self.isFavorite = false
        self.checkIns = []
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 店名にシーシャ関連キーワードを含む場合を専門店とみなす
    var isShishaSpecialty: Bool {
        let keywords = ["シーシャ", "水煙草", "水タバコ", "hookah", "shisha", "HOOKAH", "SHISHA"]
        return keywords.contains { name.localizedCaseInsensitiveContains($0) }
    }

    var priceLevelText: String? {
        guard let level = priceLevel else { return nil }
        switch level {
        case 0:  return "無料"
        case 1:  return "¥1,000〜2,000"
        case 2:  return "¥2,000〜3,000"
        case 3:  return "¥3,000〜5,000"
        case 4:  return "¥5,000〜"
        default: return nil
        }
    }
}

extension Store {
    static let mocks: [Store] = {
        let tokyo = Store(
            placeID: "mock_001",
            name: "シーシャ東京",
            address: "渋谷区道玄坂1-1",
            latitude: 35.6580,
            longitude: 139.7016,
            hasPrivateRoom: true,
            flavors: ["フルーツ系", "ミント系"]
        )
        tokyo.isOpenNow = true
        tokyo.rating = 4.3
        tokyo.userRatingsTotal = 128
        tokyo.phoneNumber = "03-1234-5678"
        tokyo.websiteURL = "https://example.com/shisha-tokyo"
        tokyo.openingHours = [
            "月曜日: 17:00 – 翌2:00",
            "火曜日: 17:00 – 翌2:00",
            "水曜日: 17:00 – 翌2:00",
            "木曜日: 17:00 – 翌2:00",
            "金曜日: 17:00 – 翌3:00",
            "土曜日: 14:00 – 翌3:00",
            "日曜日: 14:00 – 翌2:00"
        ]

        let hookah = Store(
            placeID: "mock_002",
            name: "HOOKAH LOUNGE",
            address: "新宿区歌舞伎町2-2",
            latitude: 35.6938,
            longitude: 139.7034,
            hasPrivateRoom: false,
            flavors: ["スパイス系"]
        )
        hookah.rating = 3.8
        hookah.userRatingsTotal = 54

        let roppongi = Store(
            placeID: "mock_003",
            name: "シーシャバー六本木",
            address: "港区六本木3-3",
            latitude: 35.6628,
            longitude: 139.7319,
            hasPrivateRoom: true,
            flavors: ["フルーツ系", "フローラル系"]
        )
        roppongi.rating = 4.6
        roppongi.userRatingsTotal = 312
        roppongi.phoneNumber = "03-9876-5432"

        return [tokyo, hookah, roppongi]
    }()

    static var mock: Store { mocks[0] }
}
