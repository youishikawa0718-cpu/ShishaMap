import CoreLocation
import Observation
import OSLog
import SwiftData

@MainActor
@Observable
final class StoreViewModel {
    // MARK: - 公開状態
    var stores: [Store] = []
    var isLoading = false
    var isDetailLoading = false
    var errorMessage: String?
    var isRetryable = false
    var errorRequiresSettings = false
    var filter = FilterCriteria()
    var selectedTab: AppTab = .map
    var mapFocusedStore: Store?

    // エリア検索
    var searchedAreaName: String? = nil
    var searchedAreaCoordinate: CLLocationCoordinate2D? = nil
    var isGeocodingLoading = false

    // テキスト検索
    var textSearchResults: [Store] = []
    var isTextSearching = false

    // MARK: - 非公開
    private let repository: StoreRepositoryProtocol
    private let geocoder: GeocoderProtocol
    private var fetchTask: Task<Void, Never>?
    private var textSearchTask: Task<Void, Never>?
    private var lastCoordinate: CLLocationCoordinate2D?
    var modelContext: ModelContext?

    // MARK: - 初期化（DI）
    init(repository: any StoreRepositoryProtocol, geocoder: GeocoderProtocol? = nil, modelContext: ModelContext? = nil) {
        self.repository = repository
        self.geocoder = geocoder ?? LocationGeocoder()
        self.modelContext = modelContext
    }

    // MARK: - ユースケース

    /// 現在地周辺の店舗を取得する（0.5秒デバウンス付き）
    /// 前回取得地点と近い場合（100m以内）はスキップして無駄なAPIコールを防ぐ
    func fetchNearbyDebounced(coordinate: CLLocationCoordinate2D) {
        // 前回と近い座標なら再取得しない
        if let last = lastCoordinate {
            let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if distance < 100 { return }
        }
        fetchTask?.cancel()
        fetchTask = Task {
            try? await Task.sleep(for: .milliseconds(AppConstants.Search.debounceMilliseconds))
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
        errorRequiresSettings = false
        defer { isLoading = false }
        do {
            let fetched = try await repository.fetchNearby(
                coordinate: coordinate,
                radius: filter.radiusMeters
            )
            stores = fetched.map { upsert($0) }
        } catch {
            let appError = AppError(from: error)
            AppLogger.viewModel.error("fetchNearby失敗: \(appError.errorDescription ?? "")")
            errorMessage = appError.errorDescription
            isRetryable = appError.isRetryable
        }
    }

    /// エリア名で店舗を検索する
    func searchByArea(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.count <= AppConstants.Validation.maxSearchQueryLength else { return }

        isGeocodingLoading = true
        errorMessage = nil
        defer { isGeocodingLoading = false }
        do {
            let coordinate = try await geocoder.coordinate(for: trimmed)
            searchedAreaName = trimmed
            searchedAreaCoordinate = coordinate
            await fetchNearby(coordinate: coordinate)
        } catch {
            let appError = AppError(from: error)
            AppLogger.viewModel.error("searchByArea失敗 query=\(query): \(appError.errorDescription ?? "")")
            errorMessage = appError.errorDescription
            isRetryable = appError.isRetryable
        }
    }

    /// テキスト入力に応じてリアルタイムに店舗を検索する（0.5秒デバウンス）
    func searchByTextDebounced(query: String) {
        textSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.count >= 2,
              trimmed.count <= AppConstants.Validation.maxSearchQueryLength else {
            textSearchResults = []
            return
        }
        textSearchTask = Task {
            try? await Task.sleep(for: .milliseconds(AppConstants.Search.debounceMilliseconds))
            guard !Task.isCancelled else { return }
            isTextSearching = true
            defer { isTextSearching = false }
            do {
                let results = try await repository.searchByText(query: trimmed)
                guard !Task.isCancelled else { return }
                textSearchResults = results.map { upsert($0) }
            } catch {
                guard !Task.isCancelled else { return }
                textSearchResults = []
            }
        }
    }

    /// テキスト検索をクリアする
    func clearTextSearch() {
        textSearchTask?.cancel()
        textSearchResults = []
        isTextSearching = false
    }

    /// 検索結果タップ時にマップタブへ切り替えて該当店舗にフォーカスする
    func focusOnMap(_ store: Store) {
        mapFocusedStore = store
        selectedTab = .map
    }

    /// 位置情報権限拒否エラーを表示する
    func showLocationPermissionError() {
        errorMessage = AppError.locationPermissionDenied.errorDescription
        isRetryable = false
        errorRequiresSettings = true
    }

    /// 店舗詳細情報をAPIから取得し、既存のSwiftDataモデルへマージする
    func loadDetail(store: Store) async {
        isDetailLoading = true
        defer { isDetailLoading = false }
        do {
            let detail = try await repository.fetchDetail(placeID: store.placeID)
            if !detail.openingHours.isEmpty { store.openingHours = detail.openingHours }
            if detail.isOpenNow { store.isOpenNow = detail.isOpenNow }
            if let phone = detail.phoneNumber { store.phoneNumber = phone }
            if let website = detail.websiteURL { store.websiteURL = website }
            if !detail.photoReferences.isEmpty {
                store.photoReferences = detail.photoReferences
            }
            if let price = detail.priceLevel { store.priceLevel = price }
            if let r = detail.rating { store.rating = r }
            if let total = detail.userRatingsTotal { store.userRatingsTotal = total }
        } catch {
            // 詳細取得はベストエフォート。基本情報は表示済みのため無視する
        }
    }

    /// エラー時のリトライ
    func retry() async {
        guard let coord = lastCoordinate else { return }
        await fetchNearby(coordinate: coord)
    }

    // MARK: - SwiftData upsert

    /// API 結果を SwiftData に upsert し、managed な Store を返す。
    /// ModelContext 未設定時はそのまま返す（Preview・テスト用）。
    private func upsert(_ store: Store) -> Store {
        guard let ctx = modelContext else { return store }
        let id = store.placeID
        let descriptor = FetchDescriptor<Store>(predicate: #Predicate { $0.placeID == id })
        if let existing = try? ctx.fetch(descriptor).first {
            existing.name = store.name
            existing.address = store.address
            existing.latitude = store.latitude
            existing.longitude = store.longitude
            existing.isOpenNow = store.isOpenNow
            if let price = store.priceLevel { existing.priceLevel = price }
            if !store.photoReferences.isEmpty { existing.photoReferences = store.photoReferences }
            if !store.flavors.isEmpty { existing.flavors = store.flavors }
            return existing
        } else {
            ctx.insert(store)
            return store
        }
    }

    // MARK: - フィルタリング（クライアントサイド）

    var filteredStores: [Store] {
        stores.filter { store in
            (!filter.openNow || store.isOpenNow) &&
            (!filter.hasPrivateRoom || store.hasPrivateRoom) &&
            (!filter.specialtyOnly || store.isShishaSpecialty) &&
            (store.priceLevel ?? 0) <= filter.maxPriceLevel &&
            (filter.flavorTags.isEmpty || !filter.flavorTags.isDisjoint(with: Set(store.flavors)))
        }
    }

    /// マップピン表示用。近い順に20件に絞ってタップしやすくする
    var mapStores: [Store] {
        Array(filteredStores.prefix(AppConstants.Map.maxPins))
    }
}
