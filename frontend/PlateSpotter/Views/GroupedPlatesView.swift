import SwiftUI

struct GroupedPlatesView: View {
    let brand: String
    let model: String
    @State private var groupedPlates: [String: [String]] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""

    var filteredRegions: [String] {
        let keys = groupedPlates.keys.sorted()
        if searchText.isEmpty {
            return keys
        } else {
            return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Завантаження")
            } else if let error = errorMessage {
                Text("Помилка: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(filteredRegions, id: \.self) { region in
                        NavigationLink(destination: PlatesListView(region: region,
                                                                  plates: groupedPlates[region] ?? [])) {
                            HStack {
                                Text(region)
                                    .font(.headline)
                                Spacer()
                                Text("\(groupedPlates[region]?.count ?? 0)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("\(brand) \(model)")
        .searchable(text: $searchText, prompt: "Пошук регіону")
        .onAppear {
            fetchGroupedPlates()
        }
    }
    
    private func fetchGroupedPlates() {
        guard let url = URL(string: "\(APIConfig.baseURL)/cars/\(brand)/\(model)/plates/grouped") else {
            self.errorMessage = "Невірна URL-адреса"
            self.isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let data = data {
                    do {
                        let decoded = try JSONDecoder().decode([String: [String]].self, from: data)
                        self.groupedPlates = decoded
                    } catch {
                        self.errorMessage = "Помилка декодування: \(error.localizedDescription)"
                    }
                }
                self.isLoading = false
            }
        }.resume()
    }
}
