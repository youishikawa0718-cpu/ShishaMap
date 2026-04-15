import CoreLocation

protocol StoreRepositoryProtocol {
    /// 指定座標の半径radius(m)以内のシーシャ店を返す
    @MainActor func fetchNearby(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store]
    /// placeIDで1件取得（詳細画面用）
    @MainActor func fetchDetail(placeID: String) async throws -> Store
    /// テキスト検索で店舗を取得する
    @MainActor func searchByText(query: String) async throws -> [Store]
}
