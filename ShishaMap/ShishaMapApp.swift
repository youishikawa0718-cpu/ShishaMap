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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .environment(locationManager)
        }
        .modelContainer(for: [Store.self, CheckIn.self])
    }
}
