import CoreLocation
import Observation

@MainActor
@Observable
final class StoreViewModel {
    // MARK: - 公開状態
    var stores: [Store] = []
    var isLoading = false
    var errorMessage: String?
    var isRetryable = false
    var filter = FilterCriteria()

    // MARK: - 非公開
    private let repository: StoreRepositoryProtocol
    private var fetchTask: Task<Void, Never>?
    private var lastCoordinate: CLLocationCoordinate2D?

    // MARK: - 初期化（DI）
    init(repository: any StoreRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - ユースケース

    /// 現在地周辺の店舗を取得する（0.5秒デバウンス付き）
    func fetchNearbyDebounced(coordinate: CLLocationCoordinate2D) {
        fetchTask?.cancel()
        fetchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await fetchNearby(coordinate: coordinate)
        }
    }

    /// 現在地周辺の店舗を取得する
    func fetchNearby(coordinate: CLLocationCoordinate2D) async {
        lastCoordinate = coordinate
        isLoading = true
        errorMessage = nil
        isRetryable = false
        defer { isLoading = false }
        do {
            stores = try await repository.fetchNearby(
                coordinate: coordinate,
                radius: filter.radiusMeters
            )
        } catch {
            let appError = AppError(from: error)
            errorMessage = appError.errorDescription
            isRetryable = appError.isRetryable
        }
    }

    /// エラー時のリトライ
    func retry() async {
        guard let coord = lastCoordinate else { return }
        await fetchNearby(coordinate: coord)
    }

    // MARK: - フィルタリング（クライアントサイド）

    var filteredStores: [Store] {
        stores.filter { store in
            (!filter.openNow) &&
            (!filter.hasPrivateRoom || store.hasPrivateRoom) &&
            (store.priceLevel ?? 0) <= filter.maxPriceLevel &&
            (filter.flavorTags.isEmpty || !filter.flavorTags.isDisjoint(with: Set(store.flavors)))
        }
    }
}
