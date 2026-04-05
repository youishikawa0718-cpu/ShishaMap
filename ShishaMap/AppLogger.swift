import OSLog

/// カテゴリ別のos.Loggerインスタンスを提供する。
/// リリースビルドでは `.debug` レベルのログが自動的に抑制される（os_log の標準動作）。
/// 機密情報（APIキー・座標・ユーザーデータ）は絶対にログに含めないこと。
enum AppLogger {
    /// API通信関連のログ
    static let api = Logger(subsystem: subsystem, category: "API")
    /// ViewModel・ビジネスロジック関連のログ
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    /// SwiftData・永続化関連のログ
    static let data = Logger(subsystem: subsystem, category: "Data")
    /// 位置情報関連のログ
    static let location = Logger(subsystem: subsystem, category: "Location")

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.shishamap"
}
