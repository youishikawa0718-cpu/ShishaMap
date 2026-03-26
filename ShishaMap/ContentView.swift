import SwiftData
import SwiftUI

/// アプリのルートナビゲーション（TabView）
struct RootView: View {
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("マップ", systemImage: "map.fill")
                }

            SearchView()
                .tabItem {
                    Label("検索", systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label("お気に入り", systemImage: "heart.fill")
                }

            CheckInHistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
        }
        .tint(.brown)
    }
}

#Preview {
    RootView()
        .environment(StoreViewModel(repository: MockStoreRepository()))
        .modelContainer(for: [Store.self, CheckIn.self], inMemory: true)
}
