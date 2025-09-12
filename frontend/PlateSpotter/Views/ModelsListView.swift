import SwiftUI

struct ModelsListView: View {
    let brand: String
    @State private var models: [String] = []
    @State private var isLoading = true
    @State private var searchText = ""

    var filteredModels: [String] {
        if searchText.isEmpty {
            return models
        } else {
            return models.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List {
            if isLoading {
                ProgressView("Завантаження моделей")
            } else {
                ForEach(filteredModels, id: \.self) { model in
                    NavigationLink(model,
                                   destination: GroupedPlatesView(brand: brand, model: model))
                }
            }
        }
        .navigationTitle(brand)
        .searchable(text: $searchText, prompt: "Пошук моделі")
        .task {
            await loadModels()
        }
    }
    
    func loadModels() async {
        guard let url = URL(string: "\(APIConfig.baseURL)/cars/\(brand)/models") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([String].self, from: data)
            await MainActor.run {
                self.models = decoded.sorted()
                self.isLoading = false
            }
        } catch {
            print("Помилка завантаження моделей:", error)
        }
    }
}

