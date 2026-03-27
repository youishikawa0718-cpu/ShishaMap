import SwiftData
import SwiftUI

/// アプリのルートナビゲーション（TabView）
struct RootView: View {
    @Environment(StoreViewModel.self) private var viewModel

    var body: some View {
        TabView(selection: Bindable(viewModel).selectedTab) {
            MapView()
                .tabItem { Label("マップ", systemImage: "map.fill") }
                .tag(0)

            SearchView()
                .tabItem { Label("検索", systemImage: "magnifyingglass") }
                .tag(1)

            FavoritesView()
                .tabItem { Label("お気に入り", systemImage: "heart.fill") }
                .tag(2)

            CheckInHistoryView()
                .tabItem { Label("履歴", systemImage: "clock.fill") }
                .tag(3)
        }
        .tint(.brown)
    }
}

#Preview {
    RootView()
        .environment(StoreViewModel(repository: MockStoreRepository()))
        .modelContainer(for: [Store.self, CheckIn.self], inMemory: true)
}
