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
                        "履歴なし",
                        systemImage: "clock",
                        description: Text("チェックインすると履歴が表示されます")
                    )
                } else {
                    List {
                        ForEach(checkIns) { checkIn in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(checkIn.store?.name ?? "不明な店舗")
                                    .font(.headline)
                                Text(checkIn.date.formatted(date: .long, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let note = checkIn.note {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { modelContext.delete(checkIns[$0]) }
                        }
                    }
                }
            }
            .navigationTitle("チェックイン履歴")
            .toolbar {
                EditButton()
            }
        }
    }
}

#Preview {
    CheckInHistoryView()
        .modelContainer(for: [Store.self, CheckIn.self], inMemory: true)
}
