import XCTest

@testable import ShishaMap

final class FilterCriteriaTests: XCTestCase {

    // MARK: - isDefault

    func test_isDefault_whenAllDefaults_returnsTrue() {
        let sut = FilterCriteria()
        XCTAssertTrue(sut.isDefault)
    }

    func test_isDefault_whenOpenNowTrue_returnsFalse() {
        var sut = FilterCriteria()
        sut.openNow = true
        XCTAssertFalse(sut.isDefault)
    }

    func test_isDefault_whenHasPrivateRoomTrue_returnsFalse() {
        var sut = FilterCriteria()
        sut.hasPrivateRoom = true
        XCTAssertFalse(sut.isDefault)
    }

    func test_isDefault_whenMaxPriceLevelChanged_returnsFalse() {
        var sut = FilterCriteria()
        sut.maxPriceLevel = 2
        XCTAssertFalse(sut.isDefault)
    }

    func test_isDefault_whenFlavorTagsNotEmpty_returnsFalse() {
        var sut = FilterCriteria()
        sut.flavorTags = ["フルーツ系"]
        XCTAssertFalse(sut.isDefault)
    }

    func test_isDefault_whenRadiusChanged_returnsFalse() {
        var sut = FilterCriteria()
        sut.radiusMeters = 500
        XCTAssertFalse(sut.isDefault)
    }

    // MARK: - activeCount

    func test_activeCount_whenAllDefaults_returnsZero() {
        let sut = FilterCriteria()
        XCTAssertEqual(sut.activeCount, 0)
    }

    func test_activeCount_whenOpenNowTrue_returnsOne() {
        var sut = FilterCriteria()
        sut.openNow = true
        XCTAssertEqual(sut.activeCount, 1)
    }

    func test_activeCount_whenAllFiltersActive_returnsFive() {
        var sut = FilterCriteria()
        sut.openNow = true
        sut.hasPrivateRoom = true
        sut.maxPriceLevel = 2
        sut.flavorTags = ["フルーツ系"]
        sut.radiusMeters = 500
        XCTAssertEqual(sut.activeCount, 5)
    }

    func test_activeCount_maxPriceLevelAtDefault_notCounted() {
        var sut = FilterCriteria()
        sut.maxPriceLevel = 4
        XCTAssertEqual(sut.activeCount, 0)
    }

    func test_activeCount_multipleFlavorTags_countedAsOne() {
        var sut = FilterCriteria()
        sut.flavorTags = ["フルーツ系", "ミント系", "スパイス系"]
        XCTAssertEqual(sut.activeCount, 1)
    }
}
