import Foundation

/// アプリ全体で使用する定数
enum AppConstants {
    // MARK: - API

    enum API {
        /// Places APIページネーション間の待機時間（秒）
        static let paginationDelay: Duration = .seconds(2)
        /// ページネーション最大取得ページ数
        static let maxPaginationPages = 3
        /// 写真取得時の最大幅（px）
        static let photoMaxWidth = 800
    }

    // MARK: - Cache

    enum Cache {
        /// APIレスポンスキャッシュの有効期間（秒）
        static let ttl: TimeInterval = 300
    }

    // MARK: - Search

    enum Search {
        /// マップ移動時のデバウンス遅延（ミリ秒）
        static let debounceMilliseconds: Int = 500
        /// デフォルト検索半径（メートル）
        static let defaultRadius: Double = 1500
        /// 最小検索半径（メートル）
        static let minRadius: Double = 500
        /// 最大検索半径（メートル）
        static let maxRadius: Double = 5000
        /// 半径スライダーのステップ（メートル）
        static let radiusStep: Double = 500
    }

    // MARK: - Map

    enum Map {
        /// マップ上に表示するピンの最大数
        static let maxPins = 20
    }

    // MARK: - Filter

    enum Filter {
        /// 最大価格レベル（全て表示）
        static let maxPriceLevel = 4
    }

    // MARK: - Data

    enum Data {
        /// 最近見た店舗の最大保持件数
        static let maxRecentlyViewed = 20
    }

    // MARK: - Validation

    enum Validation {
        /// 検索キーワードの最大文字数
        static let maxSearchQueryLength = 100
        /// チェックインノートの最大文字数
        static let maxCheckInNoteLength = 500
        /// 電話番号に許可する文字セット
        static let allowedPhoneCharacters = CharacterSet(charactersIn: "0123456789+-() ")
        /// URLスキームのホワイトリスト
        static let allowedURLSchemes: Set<String> = ["http", "https", "tel"]
    }
}
