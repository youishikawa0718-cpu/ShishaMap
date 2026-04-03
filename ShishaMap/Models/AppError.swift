import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case apiKeyMissing
    case rateLimitExceeded
    case locationPermissionDenied
    case geocodingFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:       return "ネットワークに接続できません"
        case .apiKeyMissing:            return "APIキーが設定されていません"
        case .rateLimitExceeded:        return "しばらくしてから再度お試しください"
        case .locationPermissionDenied: return "位置情報の使用を許可してください"
        case .geocodingFailed:         return "エリアが見つかりませんでした"
        case .unknown(let e):           return e.localizedDescription
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .rateLimitExceeded: return true
        default: return false
        }
    }

    init(from error: Error) {
        if let appError = error as? AppError { self = appError; return }
        let nsError = error as NSError
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet: self = .networkUnavailable
        default: self = .unknown(error)
        }
    }
}
