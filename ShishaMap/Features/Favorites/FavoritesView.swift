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
                            VStack(alignment: .leading, spacing: 6) {
                                Text(store.name).font(.headline)
                                Text(store.address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    if store.isOpenNow {
                                        Text("営業中")
                                            .font(.caption2).bold()
                                            .foregroundStyle(.green)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.green.opacity(0.12), in: Capsule())
                                    }
                                    if let priceText = store.priceLevelText {
                                        Text(priceText)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                withAnimation { store.isFavorite = false }
                            } label: {
                                Label("解除", systemImage: "heart.slash")
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
