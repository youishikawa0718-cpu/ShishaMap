import Foundation
import SwiftData

@Model
final class CheckIn {
    var date: Date
    var note: String?
    var store: Store?

    init(date: Date = .now, note: String? = nil, store: Store? = nil) {
        self.date = date
        self.note = note
        self.store = store
    }
}
