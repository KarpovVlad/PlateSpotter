import SwiftUI

struct BrandsListView: View {
    @State private var brands: [String] = []
    @State private var isLoading = true
    @State private var searchText = ""

    var filteredBrands: [String] {
        if searchText.isEmpty {
            return brands
        } else {
            return brands.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List {
            if isLoading {
                ProgressView("Завантаження брендів")
            } else {
                ForEach(filteredBrands, id: \.self) { brand in
                    NavigationLink(brand, destination: ModelsListView(brand: brand))
                }
            }
        }
        .navigationTitle("Марки авто")
        .searchable(text: $searchText, prompt: "Пошук марки")
        .task {
            await loadBrands()
        }
    }
    
    func loadBrands() async {
        guard let url = URL(string: "\(APIConfig.baseURL)/cars/brands") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([String].self, from: data)
            await MainActor.run {
                self.brands = decoded.sorted()
                self.isLoading = false
            }
        } catch {
            print("Помилка завантаження брендів:", error)
        }
    }
}
