import Foundation

struct FilterCriteria {
    var openNow: Bool = false
    var hasPrivateRoom: Bool = false
    var specialtyOnly: Bool = false
    var maxPriceLevel: Int = AppConstants.Filter.maxPriceLevel
    var flavorTags: Set<String> = []
    var radiusMeters: Double = AppConstants.Search.defaultRadius

    var isDefault: Bool {
        !openNow && !hasPrivateRoom && !specialtyOnly
        && maxPriceLevel == AppConstants.Filter.maxPriceLevel
        && flavorTags.isEmpty
        && radiusMeters == AppConstants.Search.defaultRadius
    }

    var activeCount: Int {
        [openNow, hasPrivateRoom, specialtyOnly].filter { $0 }.count +
        (maxPriceLevel < AppConstants.Filter.maxPriceLevel ? 1 : 0) +
        (flavorTags.isEmpty ? 0 : 1) +
        (radiusMeters != AppConstants.Search.defaultRadius ? 1 : 0)
    }
}
