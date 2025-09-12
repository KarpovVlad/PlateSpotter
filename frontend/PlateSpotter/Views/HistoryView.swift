import SwiftUI

struct HistoryView: View {
    let plateNumber: String
    @State private var history: [CarInfo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Завантаження історії")
            } else if let error = errorMessage {
                Text("Помилка: \(error)").foregroundColor(.red).padding()
            } else if history.isEmpty {
                Text("Для номера \(plateNumber) історія порожня.")
                    .foregroundColor(.secondary).padding()
            } else {
                List(history, id: \.vin) { car in
                    VStack(alignment: .leading) {
                        Text("\(car.make) \(car.model)").font(.headline)
                        Text("Рік: \(car.year), VIN: \(car.vin)")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Історія \(plateNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchHistory() }
    }


    func fetchHistory() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/plate_history/\(plateNumber)") else {
            self.errorMessage = "Невірна URL-адреса"
            self.isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                    self.history = []
                    self.errorMessage = nil
                } else if let data = data {
                    do {
                        self.history = try JSONDecoder().decode([CarInfo].self, from: data)
                    } catch {
                        self.errorMessage = "Помилка декодування: \(error.localizedDescription)"
                    }
                }
                self.isLoading = false
            }
        }.resume()
    }
}

