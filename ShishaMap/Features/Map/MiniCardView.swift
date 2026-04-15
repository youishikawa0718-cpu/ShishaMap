import SwiftUI

struct MiniCardView: View {
    let store: Store
    var onTapDetail: (() -> Void)?

    var body: some View {
        Button {
            onTapDetail?()
        } label: {
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
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .tint(.primary)
    }
}

#Preview {
    NavigationStack {
        MiniCardView(store: .mock)
    }
}
