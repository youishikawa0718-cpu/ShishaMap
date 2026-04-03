import Foundation
import SwiftData

@Model
final class RecentlyViewed {
    var storeID: String
    var storeName: String
    var storeAddress: String
    var viewedAt: Date

    init(storeID: String, storeName: String, storeAddress: String) {
        self.storeID = storeID
        self.storeName = storeName
        self.storeAddress = storeAddress
        self.viewedAt = Date()
    }
}
