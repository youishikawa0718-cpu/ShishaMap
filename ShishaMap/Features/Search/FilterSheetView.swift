import SwiftUI

struct FilterSheetView: View {
    @Binding var filter: FilterCriteria
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("条件") {
                    Toggle("営業中のみ", isOn: $filter.openNow)
                    Toggle("個室あり", isOn: $filter.hasPrivateRoom)
                }

                Section("価格帯（最大）") {
                    Picker("価格帯", selection: $filter.maxPriceLevel) {
                        Text("〜¥2k").tag(1)
                        Text("〜¥3k").tag(2)
                        Text("〜¥5k").tag(3)
                        Text("全て").tag(4)
                    }
                    .pickerStyle(.segmented)
                }

                Section("検索半径") {
                    Slider(value: $filter.radiusMeters, in: 500...5000, step: 500) {
                        Text("半径")
                    } minimumValueLabel: {
                        Text("500m")
                    } maximumValueLabel: {
                        Text("5km")
                    }
                    Text("\(Int(filter.radiusMeters))m")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("リセット") {
                        filter = FilterCriteria()
                    }
                }
            }
        }
    }
}

#Preview {
    FilterSheetView(filter: .constant(FilterCriteria()))
}
