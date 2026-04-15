import SwiftData
import SwiftUI

struct CheckInHistoryView: View {
    @Query(sort: \CheckIn.date, order: .reverse)
    private var checkIns: [CheckIn]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if checkIns.isEmpty {
                    ContentUnavailableView(
                        "チェックイン履歴なし",
                        systemImage: "clock",
                        description: Text("店舗詳細画面からチェックインできます")
                    )
                } else {
                    List {
                        ForEach(checkIns) { checkIn in
                            checkInRow(checkIn)
                        }
                        .onDelete(perform: deleteCheckIns)
                    }
                }
            }
            .navigationTitle("履歴")
        }
    }

    private func checkInRow(_ checkIn: CheckIn) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let store = checkIn.store {
                Text(store.name).font(.headline)
                Text(store.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Label(checkIn.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let note = checkIn.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private func deleteCheckIns(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(checkIns[index])
        }
    }
}

#Preview {
    CheckInHistoryView()
        .modelContainer(for: [Store.self, CheckIn.self], inMemory: true)
}
