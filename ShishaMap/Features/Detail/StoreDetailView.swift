import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct StoreDetailView: View {
    let store: Store
    @Environment(StoreViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    ShareLink(item: shareText, subject: Text(store.name)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: store.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(store.isFavorite ? .red : .primary)
                            .symbolEffect(.bounce, value: store.isFavorite)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showCheckInSheet) {
            CheckInSheet(store: store)
        }
        .task {
            await viewModel.loadDetail(store: store)
            recordRecentlyViewed()
        }
    }

    // MARK: - 写真

    private var storePhoto: some View {
        let refs = store.photoReferences.isEmpty
            ? (store.photoReference.map { [$0] } ?? [])
            : store.photoReferences
        return Group {
            if refs.isEmpty {
                photoPlaceholder
            } else {
                TabView {
                    ForEach(refs, id: \.self) { ref in
                        photoCell(ref: ref)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipped()
    }

    private func photoCell(ref: String) -> some View {
        let apiKey = Bundle.main.infoDictionary?["PLACES_API_KEY"] as? String ?? ""
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=\(ref)&key=\(apiKey)")
        return AsyncImage(url: url) { phase in
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
    }

    private var photoPlaceholder: some View {
        Rectangle()
            .fill(Color(.secondarySystemBackground))
            .overlay {
                Image(systemName: "smoke.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brown.opacity(0.5))
            }
    }

    // MARK: - 店舗情報

    private var storeInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            nameAndStatusRow
            Text(store.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !store.flavors.isEmpty { flavorTags }
            infoRows
            if !store.openingHours.isEmpty { openingHoursSection }
        }
        .padding(.horizontal)
        .overlay(alignment: .topTrailing) {
            if viewModel.isDetailLoading {
                ProgressView().padding(4)
            }
        }
    }

    private var nameAndStatusRow: some View {
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
    }

    private var flavorTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.flavors, id: \.self) { flavor in
                    Text(flavor)
                        .font(.caption)
                        .foregroundStyle(Color.brown)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.brown.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var infoRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let rating = store.rating {
                ratingRow(rating: rating, total: store.userRatingsTotal)
            }
            if store.hasPrivateRoom {
                Label("個室あり", systemImage: "door.left.hand.closed")
            }
            if let priceText = store.priceLevelText {
                Label(priceText, systemImage: "yensign")
            }
            if let phone = store.phoneNumber, !phone.isEmpty {
                phoneLink(phone: phone)
            }
            if let website = store.websiteURL, let url = URL(string: website) {
                websiteLink(url: url)
            }
        }
        .font(.subheadline)
    }

    private func ratingRow(rating: Double, total: Int?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill").foregroundStyle(.yellow)
            Text(String(format: "%.1f", rating))
            if let total {
                Text("(\(total)件)").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func phoneLink(phone: String) -> some View {
        if let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "-" || $0 == "+" })") {
            Link(destination: url) {
                Label(phone, systemImage: "phone")
                    .foregroundStyle(.brown)
            }
        }
    }

    private func websiteLink(url: URL) -> some View {
        Link(destination: url) {
            Label("ウェブサイト", systemImage: "globe")
                .foregroundStyle(.brown)
        }
    }

    private var openingHoursSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("営業時間").font(.subheadline).bold()
            ForEach(store.openingHours, id: \.self) { line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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

    private func toggleFavorite() {
        withAnimation { store.isFavorite.toggle() }
    }

    /// 最近見た店舗を記録する。20件を超えた場合は最古を削除する
    private func recordRecentlyViewed() {
        let storeID = store.placeID
        let descriptor = FetchDescriptor<RecentlyViewed>(
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        guard let all = try? modelContext.fetch(descriptor) else { return }
        // 既存エントリがあれば更新して重複を避ける
        if let existing = all.first(where: { $0.storeID == storeID }) {
            existing.viewedAt = Date()
        } else {
            modelContext.insert(RecentlyViewed(
                storeID: storeID,
                storeName: store.name,
                storeAddress: store.address
            ))
            // 21件目以降を削除
            all.dropFirst(19).forEach { modelContext.delete($0) }
        }
    }

    private var shareText: String {
        var lines = [store.name, store.address]
        let encodedName = store.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? store.name
        lines.append("https://maps.apple.com/?q=\(encodedName)")
        return lines.joined(separator: "\n")
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
            .environment(StoreViewModel(repository: MockStoreRepository()))
    }
}
