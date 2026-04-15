//
//  ShishaMapApp.swift
//  ShishaMap
//
//  Created by Yuki Ishikawa on 2026/03/27.
//

import SwiftData
import SwiftUI

@main
struct ChillSearchingApp: App {
    @State private var viewModel: StoreViewModel
    @State private var locationManager = LocationManager()

    init() {
        let container = Self.modelContainer
        _viewModel = State(initialValue: StoreViewModel(
            repository: PlacesRepository(),
            modelContext: container.mainContext
        ))
    }

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
        let dir = appSupport.appendingPathComponent("ChillSearching", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // completeUntilFirstUserAuthentication: デバイスロック解除後にアクセス可能
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: dir.path
            )
        }
        // バックアップから除外（ユーザーデータはAPI再取得可能）
        var url = dir.appendingPathComponent("ChillSearching.store")
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        return url
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showLaunch = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    RootView()
                        .environment(viewModel)
                        .environment(locationManager)
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                    .environment(locationManager)
                }

                if showLaunch {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation {
                    showLaunch = false
                }
            }
        }
        .modelContainer(Self.modelContainer)
    }
}
