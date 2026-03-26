import SwiftUI

struct MiniCardView: View {
    let store: Store
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brown.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "smoke.fill")
                    .foregroundStyle(Color.brown)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(store.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let price = store.priceLevel {
                    Text(String(repeating: "¥", count: price))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // お気に入りボタン
            Button {
                store.isFavorite.toggle()
            } label: {
                Image(systemName: store.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(store.isFavorite ? .red : .gray)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    MiniCardView(store: .mock)
        .frame(height: 140)
}
