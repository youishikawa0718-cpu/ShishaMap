import Foundation

struct FilterCriteria {
    var openNow: Bool = false
    var hasPrivateRoom: Bool = false
    var maxPriceLevel: Int = 4
    var flavorTags: Set<String> = []
    var radiusMeters: Double = 1500

    var isDefault: Bool {
        !openNow && !hasPrivateRoom && maxPriceLevel == 4 && flavorTags.isEmpty && radiusMeters == 1500
    }

    var activeCount: Int {
        [openNow, hasPrivateRoom].filter { $0 }.count +
        (maxPriceLevel < 4 ? 1 : 0) +
        (flavorTags.isEmpty ? 0 : 1) +
        (radiusMeters != 1500 ? 1 : 0)
    }
}
