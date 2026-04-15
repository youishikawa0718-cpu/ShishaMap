import OSLog
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("情報") {
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        Label("プライバシーポリシー", systemImage: "hand.raised")
                    }

                    Button {
                        showTermsOfService = true
                    } label: {
                        Label("利用規約", systemImage: "doc.text")
                    }

                    NavigationLink {
                        LicensesView()
                    } label: {
                        Label("ライセンス", systemImage: "doc.plaintext")
                    }
                }

                Section("サポート") {
                    if let url = URLs.contactEmail {
                        Link(destination: url) {
                            Label("お問い合わせ", systemImage: "envelope")
                        }
                    }
                }

                Section("履歴") {
                    NavigationLink {
                        CheckInHistoryView()
                    } label: {
                        Label("チェックイン履歴", systemImage: "clock")
                    }
                }

                Section("データ") {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("お気に入り・履歴を削除", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("バージョン \(appVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showPrivacyPolicy) {
                SafariView(url: URLs.privacyPolicy)
            }
            .sheet(isPresented: $showTermsOfService) {
                SafariView(url: URLs.termsOfService)
            }
            .alert("データを削除", isPresented: $showDeleteConfirmation) {
                Button("削除", role: .destructive) { deleteAllData() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("お気に入り・チェックイン履歴・最近見た店舗をすべて削除します。この操作は取り消せません。")
            }
        }
    }

    // MARK: - Private

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: CheckIn.self)
            try modelContext.delete(model: RecentlyViewed.self)
            // お気に入りフラグをリセット
            let descriptor = FetchDescriptor<Store>(predicate: #Predicate { $0.isFavorite })
            let favorites = (try? modelContext.fetch(descriptor)) ?? []
            for store in favorites {
                store.isFavorite = false
            }
        } catch {
            AppLogger.data.error("データ削除に失敗: \(error.localizedDescription)")
        }
    }

    private enum URLs {
        static let privacyPolicy = URL(string: "https://youishikawa0718-cpu.github.io/ShishaMap/privacy-policy.html")!
        static let termsOfService = URL(string: "https://youishikawa0718-cpu.github.io/ShishaMap/terms-of-service.html")!
        static let contactEmail = URL(string: "mailto:youishikawa0718@gmail.com?subject=ShishaMap%E3%81%B8%E3%81%AE%E3%81%8A%E5%95%8F%E3%81%84%E5%90%88%E3%82%8F%E3%81%9B")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Store.self, CheckIn.self, RecentlyViewed.self], inMemory: true)
}
