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
                storePhoto
                storeInfo
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { store.isFavorite.toggle() }
                } label: {
                    Image(systemName: store.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite ? .red : .primary)
                        .symbolEffect(.bounce, value: store.isFavorite)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showCheckInSheet) {
            CheckInSheet(store: store)
        }
    }

    // MARK: - 写真

    private var storePhoto: some View {
        Group {
            if let ref = store.photoReference, !ref.isEmpty {
                let apiKey = Bundle.main.infoDictionary?["PLACES_API_KEY"] as? String ?? ""
                let url = URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=\(ref)&key=\(apiKey)")
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        photoPlaceholder
                    default:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                photoPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipped()
    }

    private var photoPlaceholder: some View {
        Rectangle()
            .fill(Color.brown.opacity(0.08))
            .overlay {
                Image(systemName: "smoke.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brown.opacity(0.3))
            }
    }

    // MARK: - 店舗情報

    private var storeInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 名前＋営業状態
            HStack {
                Text(store.name)
                    .font(.title2)
                    .bold()
                Spacer()
                if store.isOpenNow {
                    Text("営業中")
                        .font(.caption).bold()
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.12), in: Capsule())
                }
            }

            Text(store.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // フレーバータグ
            if !store.flavors.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.flavors, id: \.self) { flavor in
                            Text(flavor)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
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
                if let priceText = store.priceLevelText {
                    Label(priceText, systemImage: "yensign")
                }
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
    }

    // MARK: - 下部バー

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button { openInMaps() } label: {
                Label("ナビ", systemImage: "map")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button { showCheckInSheet = true } label: {
                Label("チェックイン", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown)
        }
        .padding()
        .background(.ultraThinMaterial)
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
