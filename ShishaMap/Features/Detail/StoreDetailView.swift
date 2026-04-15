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
        let refs = store.photoReferences
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
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(AppConstants.API.photoMaxWidth)&photoreference=\(ref)&key=\(apiKey)")
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
        let sanitized = String(phone.unicodeScalars.filter {
            AppConstants.Validation.allowedPhoneCharacters.contains($0)
        })
        if !sanitized.isEmpty, let url = URL(string: "tel:\(sanitized)") {
            Link(destination: url) {
                Label(phone, systemImage: "phone")
                    .foregroundStyle(.brown)
            }
        }
    }

    @ViewBuilder
    private func websiteLink(url: URL) -> some View {
        if let scheme = url.scheme?.lowercased(),
           AppConstants.Validation.allowedURLSchemes.contains(scheme) {
            Link(destination: url) {
                Label("ウェブサイト", systemImage: "globe")
                    .foregroundStyle(.brown)
            }
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
                Label("ナビ", systemImage: "map.fill")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Button { showCheckInSheet = true } label: {
                Label("チェックイン", systemImage: "location.fill")
                    .bold()
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
            all.dropFirst(AppConstants.Data.maxRecentlyViewed - 1).forEach { modelContext.delete($0) }
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
                        .onChange(of: note) { _, newValue in
                            if newValue.count > AppConstants.Validation.maxCheckInNoteLength {
                                note = String(newValue.prefix(AppConstants.Validation.maxCheckInNoteLength))
                            }
                        }
                    Text("\(note.count)/\(AppConstants.Validation.maxCheckInNoteLength)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("チェックイン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        let record = CheckIn(date: .now, note: trimmed.isEmpty ? nil : trimmed, store: store)
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
