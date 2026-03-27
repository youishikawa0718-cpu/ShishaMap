import CoreLocation
import XCTest

@testable import ShishaMap

@MainActor
final class StoreViewModelTests: XCTestCase {

    // MARK: - fetchNearby

    func test_fetchNearby_updatesStores() async {
        // Arrange
        let sut = StoreViewModel(repository: MockStoreRepository())

        // Act
        await sut.fetchNearby(coordinate: .tokyo)

        // Assert
        XCTAssertFalse(sut.stores.isEmpty)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func test_fetchNearby_onNetworkError_setsErrorMessage() async {
        // Arrange
        let sut = StoreViewModel(repository: FailingStoreRepository())

        // Act
        await sut.fetchNearby(coordinate: .tokyo)

        // Assert
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.stores.isEmpty)
        XCTAssertTrue(sut.isRetryable)
        XCTAssertFalse(sut.isLoading)
    }

    func test_fetchNearby_clearsErrorMessageOnSuccess() async {
        // Arrange
        let sut = StoreViewModel(repository: FailingStoreRepository())
        await sut.fetchNearby(coordinate: .tokyo)
        XCTAssertNotNil(sut.errorMessage)

        // Act — swap to a succeeding repo by re-fetching with mock
        let sut2 = StoreViewModel(repository: MockStoreRepository())
        await sut2.fetchNearby(coordinate: .tokyo)

        // Assert
        XCTAssertNil(sut2.errorMessage)
    }

    // MARK: - retry

    func test_retry_afterSuccess_fetchesAgain() async {
        // Arrange
        let sut = StoreViewModel(repository: MockStoreRepository())
        await sut.fetchNearby(coordinate: .tokyo)

        // Act
        await sut.retry()

        // Assert
        XCTAssertFalse(sut.stores.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }

    func test_retry_beforeAnyFetch_doesNothing() async {
        // Arrange
        let sut = StoreViewModel(repository: MockStoreRepository())

        // Act — retry without prior fetchNearby (lastCoordinate is nil)
        await sut.retry()

        // Assert
        XCTAssertTrue(sut.stores.isEmpty)
    }
}

// MARK: - ネットワークエラーを返すモック

private final class FailingStoreRepository: StoreRepositoryProtocol {
    func fetchNearby(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        throw URLError(.notConnectedToInternet)
    }

    func fetchDetail(placeID: String) async throws -> Store {
        throw URLError(.notConnectedToInternet)
    }
}
