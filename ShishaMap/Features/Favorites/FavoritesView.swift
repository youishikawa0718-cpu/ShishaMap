import SwiftData
import SwiftUI

struct FavoritesView: View {
    @Query(filter: #Predicate<Store> { $0.isFavorite }, sort: \.name)
    private var favorites: [Store]

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "お気に入りなし",
                        systemImage: "heart.slash",
                        description: Text("店舗詳細画面からお気に入り登録できます")
                    )
                } else {
                    List(favorites) { store in
                        NavigationLink {
                            StoreDetailView(store: store)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.name).font(.headline)
                                Text(store.address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("お気に入り")
        }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: [Store.self, CheckIn.self], inMemory: true)
}
