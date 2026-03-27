import SwiftUI

struct SearchView: View {
    @Environment(StoreViewModel.self) private var viewModel
    @State private var query = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredStores.isEmpty && query.isEmpty {
                    ContentUnavailableView(
                        "店舗データなし",
                        systemImage: "magnifyingglass",
                        description: Text("マップを移動して店舗を読み込んでください")
                    )
                } else if filteredStores.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(filteredStores) { store in
                        Button {
                            viewModel.focusOnMap(store)
                        } label: {
                            StoreRowView(store: store)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $query, prompt: "店名・エリアで検索")
    }

    private var filteredStores: [Store] {
        guard !query.isEmpty else { return viewModel.filteredStores }
        return viewModel.filteredStores.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.address.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - 店舗行

private struct StoreRowView: View {
    let store: Store

    var body: some View {
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
                if store.hasPrivateRoom {
                    Label("個室", systemImage: "door.left.hand.closed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if store.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SearchView()
        .environment(StoreViewModel(repository: MockStoreRepository()))
}
