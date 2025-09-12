import Foundation

struct HistoryItem: Codable, Identifiable {
    let plate_number: String
    let timestamp: String?
    var id: String { plate_number + (timestamp ?? "") }
}
class HistoryAPI {
    static let shared = HistoryAPI()
    private init() {}
    func fetchHistory(token: String, completion: @escaping ([HistoryItem]) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/history/") else { completion([]); return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, response, error in
            guard let data = data,
                  let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            DispatchQueue.main.async { completion(items) }
        }.resume()
    }

    func addHistory(token: String, plateNumber: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/history/") else { completion(false); return }
        let body = ["plate_number": plateNumber]
        guard let data = try? JSONSerialization.data(withJSONObject: body, options: []) else { completion(false); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                DispatchQueue.main.async { completion(true) }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
}
