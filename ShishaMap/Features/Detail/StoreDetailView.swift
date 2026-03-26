import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct StoreDetailView: View {
    let store: Store
    @Environment(\.modelContext) private var modelContext
    @State private var showCheckInSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 写真プレースホルダー
                Rectangle()
                    .fill(Color.brown.opacity(0.1))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "smoke.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.brown.opacity(0.4))
                    }

                VStack(alignment: .leading, spacing: 12) {
                    // 基本情報
                    Text(store.name)
                        .font(.title2)
                        .bold()
                    Text(store.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // フレーバータグ
                    if !store.flavors.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(store.flavors, id: \.self) { flavor in
                                    Text(flavor)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.brown.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // 詳細情報
                    VStack(alignment: .leading, spacing: 8) {
                        if store.hasPrivateRoom {
                            Label("個室あり", systemImage: "door.left.hand.closed")
                        }
                        if let price = store.priceLevel {
                            Label(String(repeating: "¥", count: price), systemImage: "yensign")
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.isFavorite.toggle()
                } label: {
                    Image(systemName: store.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite ? .red : .primary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    openInMaps()
                } label: {
                    Label("ナビ", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showCheckInSheet = true
                } label: {
                    Label("チェックイン", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showCheckInSheet) {
            CheckInSheet(store: store)
        }
    }

    private func openInMaps() {
        let location = CLLocation(latitude: store.coordinate.latitude, longitude: store.coordinate.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = store.name
        item.openInMaps()
    }
}

// MARK: - チェックインシート

private struct CheckInSheet: View {
    let store: Store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("メモ（任意）") {
                    TextField("今日の一言", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("チェックイン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let record = CheckIn(date: .now, note: note.isEmpty ? nil : note, store: store)
                        modelContext.insert(record)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(store: .mock)
    }
}
