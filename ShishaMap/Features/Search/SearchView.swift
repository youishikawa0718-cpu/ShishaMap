import MapKit
import SwiftUI

struct SearchView: View {
    @Environment(StoreViewModel.self) private var viewModel
    @State private var query = ""
    @State private var searchCompleter = LocationSearchCompleter()
    @State private var showDetail: Store?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isGeocodingLoading || viewModel.isLoading {
                    ProgressView("検索中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isAreaSearchActive {
                    if areaStores.isEmpty {
                        ContentUnavailableView(
                            "店舗が見つかりません",
                            systemImage: "magnifyingglass",
                            description: Text("エリアを変更して再検索してください")
                        )
                    } else {
                        areaResultList
                    }
                } else if !query.isEmpty && !allSearchResults.isEmpty {
                    storeResultList(stores: allSearchResults)
                } else if !query.isEmpty && !searchCompleter.results.isEmpty {
                    suggestionList
                } else if viewModel.isTextSearching {
                    ProgressView("検索中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if query.isEmpty && viewModel.filteredStores.isEmpty {
                    ContentUnavailableView(
                        "店舗データなし",
                        systemImage: "magnifyingglass",
                        description: Text("マップを移動して店舗を読み込んでください")
                    )
                } else if !query.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    storeList(stores: viewModel.filteredStores)
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
            searchCompleter.queryFragment = newValue
            // テキストが変わったらエリア検索結果をクリア
            if viewModel.searchedAreaName != nil {
                viewModel.searchedAreaName = nil
                viewModel.searchedAreaCoordinate = nil
            }
            // リアルタイムテキスト検索
            viewModel.searchByTextDebounced(query: newValue)
        }
        .onSubmit(of: .search) {
            Task { await viewModel.searchByArea(query: query) }
        }
        .sheet(item: $showDetail) { store in
            NavigationStack {
                StoreDetailView(store: store)
            }
        }
    }

    /// エリア検索が実行済みかどうか
    private var isAreaSearchActive: Bool {
        viewModel.searchedAreaName != nil
    }

    /// ローカルフィルタ + API テキスト検索を統合した結果
    private var allSearchResults: [Store] {
        var seen = Set<String>()
        var results: [Store] = []
        // ローカル一致を優先
        for store in filteredStores where seen.insert(store.placeID).inserted {
            results.append(store)
        }
        // API結果を追加
        for store in viewModel.textSearchResults where seen.insert(store.placeID).inserted {
            results.append(store)
        }
        return results
    }

    // MARK: - サジェスト一覧

    private var suggestionList: some View {
        List(searchCompleter.results, id: \.self) { result in
            Button {
                let areaName = [result.title, result.subtitle]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                query = areaName
                // queryのonChangeでsearchedAreaNameがクリアされた後にsearchByAreaを呼ぶ
                Task { await viewModel.searchByArea(query: areaName) }
            } label: {
                Label {
                    VStack(alignment: .leading) {
                        Text(result.title)
                            .font(.subheadline)
                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.brown)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - エリア検索結果

    private var areaStores: [Store] {
        guard viewModel.searchedAreaName != nil else { return [] }
        return viewModel.filteredStores
    }

    private var areaResultList: some View {
        List {
            Section {
                ForEach(areaStores) { store in
                    Button {
                        showDetail = store
                    } label: {
                        StoreRowView(store: store)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.focusOnMap(store)
                        } label: {
                            Label("マップ", systemImage: "map")
                        }
                        .tint(.brown)
                    }
                }
            } header: {
                if let areaName = viewModel.searchedAreaName {
                    Label("\(areaName) 付近のお店", systemImage: "mappin.and.ellipse")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
    }

    // MARK: - テキスト検索（ローカルフィルタ）

    private var filteredStores: [Store] {
        guard !query.isEmpty else { return [] }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return viewModel.filteredStores
            .filter {
                $0.name.localizedCaseInsensitiveContains(trimmed) ||
                $0.address.localizedCaseInsensitiveContains(trimmed)
            }
            .sorted { lhs, rhs in
                matchScore(lhs.name, query: trimmed) > matchScore(rhs.name, query: trimmed)
            }
    }

    private func storeResultList(stores: [Store]) -> some View {
        List(stores) { store in
            Button {
                showDetail = store
            } label: {
                StoreRowView(store: store)
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing) {
                Button {
                    viewModel.focusOnMap(store)
                } label: {
                    Label("マップ", systemImage: "map")
                }
                .tint(.brown)
            }
        }
    }

    private func storeList(stores: [Store]) -> some View {
        List(stores) { store in
            Button {
                viewModel.focusOnMap(store)
            } label: {
                StoreRowView(store: store)
            }
            .buttonStyle(.plain)
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
