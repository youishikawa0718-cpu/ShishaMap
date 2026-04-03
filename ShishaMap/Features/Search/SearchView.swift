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
        .onChange(of: query) { _, newValue in
            if newValue.count > AppConstants.Validation.maxSearchQueryLength {
                query = String(newValue.prefix(AppConstants.Validation.maxSearchQueryLength))
            }
        }
    }

    private var filteredStores: [Store] {
        guard !query.isEmpty else { return viewModel.filteredStores }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return viewModel.filteredStores }

        return viewModel.filteredStores
            .filter {
                $0.name.localizedCaseInsensitiveContains(trimmed) ||
                $0.address.localizedCaseInsensitiveContains(trimmed)
            }
            .sorted { lhs, rhs in
                matchScore(lhs.name, query: trimmed) > matchScore(rhs.name, query: trimmed)
            }
    }

    /// 店名の一致度スコア: 完全一致(3) > 前方一致(2) > 部分一致(1) > 不一致(0)
    private func matchScore(_ name: String, query: String) -> Int {
        if name.localizedCaseInsensitiveCompare(query) == .orderedSame { return 3 }
        if name.localizedLowercase.hasPrefix(query.localizedLowercase) { return 2 }
        if name.localizedCaseInsensitiveContains(query) { return 1 }
        return 0
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
