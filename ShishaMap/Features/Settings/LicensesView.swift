import SwiftUI

/// オープンソースライセンス表示画面
struct LicensesView: View {
    var body: some View {
        List {
            Section {
                Text("このアプリはGoogle Places APIを使用しています。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Google Places API")
            }
        }
        .navigationTitle("ライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LicensesView()
    }
}
