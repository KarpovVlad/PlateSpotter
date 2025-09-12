import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL = APIConfig.baseURL

    func fetchPlateInfo(plate: String, completion: @escaping (Result<CarInfo, Error>) -> Void) {
        let urlString = "\(baseURL)/search?plate=\(plate)"
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let carInfo = try JSONDecoder().decode(CarInfo.self, from: data)
                completion(.success(carInfo))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum APIError: Error {
    case invalidURL
    case noData
}

