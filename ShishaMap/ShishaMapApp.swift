//
//  ShishaMapApp.swift
//  ShishaMap
//
//  Created by Yuki Ishikawa on 2026/03/27.
//

import SwiftData
import SwiftUI

@main
struct ShishaMapApp: App {
    @State private var viewModel = StoreViewModel(repository: PlacesRepository())
    @State private var locationManager = LocationManager()

    private static let modelContainer: ModelContainer = {
        let schema = Schema([Store.self, CheckIn.self, RecentlyViewed.self])
        let config = ModelConfiguration(
            schema: schema,
            url: defaultStoreURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData ModelContainer の初期化に失敗: \(error)")
        }
    }()

    /// SwiftDataの保存先をData Protection属性付きディレクトリに配置する
    private static var defaultStoreURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ShishaMap", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // completeUntilFirstUserAuthentication: デバイスロック解除後にアクセス可能
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: dir.path
            )
        }
        // バックアップから除外（ユーザーデータはAPI再取得可能）
        var url = dir.appendingPathComponent("ShishaMap.store")
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        return url
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .environment(locationManager)
        }
        .modelContainer(Self.modelContainer)
    }
}
