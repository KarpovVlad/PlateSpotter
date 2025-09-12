import Foundation

@MainActor
class HistoryManager: ObservableObject {
    @Published var history: [String] = []
    private let localKey = "plateHistory"
    private let maxItems = 10

    init() {
        loadLocalHistory()
    }

    func loadLocalHistory() {
        history = UserDefaults.standard.stringArray(forKey: localKey) ?? []
    }

    func addLocalHistory(_ plate: String) {
        let p = plate.uppercased()
        history.removeAll(where: { $0 == p })
        history.insert(p, at: 0)
        if history.count > maxItems { history = Array(history.prefix(maxItems)) }
        UserDefaults.standard.set(history, forKey: localKey)
    }

    func syncServerHistory(token: String) {
        HistoryAPI.shared.fetchHistory(token: token) { items in
            self.history = items.map { $0.plate_number }
        }
    }

    func addServerHistory(token: String, plate: String) {
        HistoryAPI.shared.addHistory(token: token, plateNumber: plate) { success in
            if success { self.syncServerHistory(token: token) }
        }
    }
}
