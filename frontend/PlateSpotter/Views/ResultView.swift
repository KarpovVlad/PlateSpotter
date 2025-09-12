import SwiftUI

struct ResultView: View {
    let plateNumber: String

    @EnvironmentObject var authVM: AuthViewModel
    @State private var isLoading = true
    @State private var carInfo: CarInfo?
    @State private var errorMessage: String?
    @State private var relatedLinks: LinksGroupedResponse?
    @State private var isLoadingLinks = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Завантаження")
                } else if let car = carInfo {
                    Form {
                        Section(header: Text("Номерний знак")) {
                            Text(plateNumber)
                        }

                        Section(header: Text("Інформація про авто")) {
                            HStack {
                                Text("VIN")
                                Spacer()
                                Text(car.vin)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Марка")
                                Spacer()
                                Text(car.make)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Модель")
                                Spacer()
                                Text(car.model)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Рік випуску")
                                Spacer()
                                Text(String(car.year))
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Обʼєм двигуна")
                                Spacer()
                                Text(formatEngineCapacity(car.engineCapacity))
                                    .foregroundColor(.secondary)
                            }
                            
                            NavigationLink(destination: HistoryView(plateNumber: plateNumber)) {
                                    Label("Історія номерного знаку", systemImage: "clock.arrow.circlepath")
                                }
                        }
                        
                        if authVM.token != nil {
                            NavigationLink(destination: CommentsView(plateNumber: plateNumber)) {
                                Text("Коментарі")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 16)
                        }

                        
                        Section(header: Text("Згадування на сторонніх сайтах")) {
                            if isLoadingLinks {
                                ProgressView("Завантаження посилань…")
                            } else if let grouped = relatedLinks {
                                if grouped.links.stat_vin.count > 0 {
                                    DisclosureGroup("Stat.vin (\(grouped.links.stat_vin.count))") {
                                        ForEach(grouped.links.stat_vin.items, id: \.self) { link in
                                            if let url = URL(string: link) {
                                                Link(destination: url) {
                                                    Text(link)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)
                                                }
                                            }
                                        }
                                    }
                                }
                                if grouped.links.autoria.count > 0 {
                                    DisclosureGroup("Auto.ria (\(grouped.links.autoria.count))") {
                                        ForEach(grouped.links.autoria.items, id: \.self) { link in
                                            if let url = URL(string: link) {
                                                Link(destination: url) {
                                                    Text(link)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)
                                                }
                                            }
                                        }
                                    }
                                }
                                if grouped.links.bidfax.count > 0 {
                                    DisclosureGroup("Bidfax (\(grouped.links.bidfax.count))") {
                                        ForEach(grouped.links.bidfax.items, id: \.self) { link in
                                            if let url = URL(string: link) {
                                                Link(destination: url) {
                                                    Text(link)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)
                                                }
                                            }
                                        }
                                    }
                                }
                                if grouped.links.instagram.count > 0 {
                                    DisclosureGroup("Instagram (\(grouped.links.instagram.count))") {
                                        ForEach(grouped.links.instagram.items, id: \.self) { link in
                                            if let url = URL(string: link) {
                                                Link(destination: url) {
                                                    Text(link)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            } else {
                                Text("Дане авто не зʼявлялось на сторонніх сайтах.")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else if let error = errorMessage {
                    Text("Помилка: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationTitle("Інфо про авто")
            .onAppear {
                fetchCarInfo(for: plateNumber)
            }
        }
    }

    func fetchCarInfo(for plate: String) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/lookup?plate=\(plate)") else {
            self.errorMessage = "Невірна URL-адреса"
            self.isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Помилка запиту: \(error.localizedDescription)"
                } else if let data = data {
                    do {
                        let result = try JSONDecoder().decode(CarInfo.self, from: data)
                        self.carInfo = result
                        self.fetchRelatedLinks(vin: result.vin)
                    } catch {
                        self.errorMessage = "Помилка декодування: \(error.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Невідомий формат відповіді"
                }
                self.isLoading = false
            }
        }.resume()
    }
    
    func fetchRelatedLinks(vin: String) {
        guard let url = URL(string: "\(APIConfig.baseURL)/cars/\(vin)/links") else { return }
        isLoadingLinks = true

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                defer { self.isLoadingLinks = false }
                
                if let error = error {
                    print("Помилка завантаження посилань: \(error.localizedDescription)")
                    return
                }
                
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(LinksGroupedResponse.self, from: data)
                        self.relatedLinks = response
                    } catch {
                        print("Помилка декодування LinksGroupedResponse: \(error)")
                    }
                }
            }
        }.resume()
    }
    
    func formatEngineCapacity(_ capacity: String?) -> String {
        guard let capacity = capacity,
              let cc = Double(capacity) else {
            return "—"
        }
        let liters = cc / 1000.0
        let rounded = ceil(liters * 10) / 10.0
        return String(format: "%.1f", rounded)
    }
}

struct RelatedLinksGroup: Codable {
    let count: Int
    let items: [String]
}

struct RelatedLinksContainer: Codable {
    let stat_vin: RelatedLinksGroup
    let autoria: RelatedLinksGroup
    let bidfax: RelatedLinksGroup
    let instagram: RelatedLinksGroup
}

struct LinksGroupedResponse: Codable {
    let vin: String
    let links: RelatedLinksContainer
}
