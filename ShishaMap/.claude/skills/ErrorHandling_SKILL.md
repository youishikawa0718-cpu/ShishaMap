# エラーハンドリングガイド

## 概要

ShishaMapのエラーはすべて`AppError`に集約し、ユーザーへのフィードバックを統一する。
このSkillはエラー定義・ViewModel連携・View表示・リトライ設計のパターンを提供する。

---

## AppError 定義

```swift
// Models/AppError.swift
enum AppError: LocalizedError {
    case networkUnavailable
    case apiKeyMissing
    case rateLimitExceeded
    case locationPermissionDenied
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:      return "ネットワークに接続できません"
        case .apiKeyMissing:           return "APIキーが設定されていません"
        case .rateLimitExceeded:       return "しばらくしてから再度お試しください"
        case .locationPermissionDenied:return "位置情報の使用を許可してください"
        case .unknown(let e):          return e.localizedDescription
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
```

---

## ViewModel でのエラー処理

```swift
@Observable final class StoreViewModel {
    var errorMessage: String?
    var isRetryable = false
    private var lastCoordinate: CLLocationCoordinate2D?

    func fetchNearby(coordinate: CLLocationCoordinate2D) async {
        lastCoordinate = coordinate
        isLoading = true
        errorMessage = nil
        isRetryable = false
        defer { isLoading = false }
        do {
            stores = try await repository.fetchNearby(coordinate: coordinate, radius: filter.radiusMeters)
        } catch {
            let appError = AppError(from: error)
            errorMessage = appError.errorDescription
            isRetryable = appError.isRetryable
        }
    }

    func retry() async {
        guard let coord = lastCoordinate else { return }
        await fetchNearby(coordinate: coord)
    }
}
```

---

## View でのエラー表示

```swift
// エラーバナー（マップ画面上部に重ねて表示）
struct ErrorBannerView: View {
    let message: String
    let isRetryable: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message).font(.subheadline)
            if isRetryable {
                Button("再試行", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}

// MapView での使い方
.overlay(alignment: .top) {
    if let message = viewModel.errorMessage {
        ErrorBannerView(
            message: message,
            isRetryable: viewModel.isRetryable
        ) {
            Task { await viewModel.retry() }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
.animation(.easeInOut, value: viewModel.errorMessage)
```

---

## 位置情報エラー

```swift
// LocationManager でのエラー処理
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if manager.authorizationStatus == .denied {
        // ViewModelにエラーを伝える
        errorSubject = .locationPermissionDenied
    }
}
```

---

## 原則

- クラッシュさせない。すべての`throws`は`do-catch`で捕捉する
- エラーメッセージはユーザーが行動できる内容にする（「何が起きたか」より「どうすればよいか」）
- リトライ可能なエラーには必ずリトライボタンを表示する
- デバッグ情報（スタックトレース等）はユーザーに見せない。ログにのみ出力する
