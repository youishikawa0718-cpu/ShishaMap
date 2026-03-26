import SwiftUI

struct SearchView: View {
    @Environment(StoreViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List(filteredStores) { store in
                Button {
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.name).font(.headline)
                        Text(store.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
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

#Preview {
    SearchView()
        .environment(StoreViewModel(repository: MockStoreRepository()))
}
