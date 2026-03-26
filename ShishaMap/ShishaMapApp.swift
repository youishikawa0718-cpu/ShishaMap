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
    @State private var viewModel = StoreViewModel(repository: MockStoreRepository())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
        }
        .modelContainer(for: [Store.self, CheckIn.self])
    }
}
