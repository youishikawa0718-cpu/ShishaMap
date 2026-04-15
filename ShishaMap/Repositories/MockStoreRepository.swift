import CoreLocation

final class MockStoreRepository: StoreRepositoryProtocol {
    func fetchNearby(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        return Store.mocks
    }

    func fetchDetail(placeID: String) async throws -> Store {
        guard let store = Store.mocks.first(where: { $0.placeID == placeID }) else {
            return Store.mock
        }
        return store
    }

    func searchByText(query: String) async throws -> [Store] {
        return Store.mocks.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.address.localizedCaseInsensitiveContains(query)
        }
    }
}
