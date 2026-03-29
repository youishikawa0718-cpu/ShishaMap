import SwiftData
import SwiftUI

/// アプリのルートナビゲーション（TabView）
struct RootView: View {
    @Environment(StoreViewModel.self) private var viewModel

    var body: some View {
        TabView(selection: Bindable(viewModel).selectedTab) {
            MapView()
                .tabItem { Label("マップ", systemImage: "map.fill") }
                .tag(AppTab.map)

            SearchView()
                .tabItem { Label("検索", systemImage: "magnifyingglass") }
                .tag(AppTab.search)

            FavoritesView()
                .tabItem { Label("お気に入り", systemImage: "heart.fill") }
                .tag(AppTab.favorites)
        }
        .tint(.brown)
    }
}

#Preview {
    RootView()
        .environment(StoreViewModel(repository: MockStoreRepository()))
        .modelContainer(for: [Store.self, CheckIn.self, RecentlyViewed.self], inMemory: true)
}
