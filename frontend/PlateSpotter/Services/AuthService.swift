import Foundation

class AuthService {
    static func guestLogin(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/guest") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let resp = try? JSONDecoder().decode([String: String].self, from: data),
                  let token = resp["access_token"] else {
                completion(.failure(NSError(domain: "AuthService", code: -1)))
                return
            }
            completion(.success(token))
        }.resume()
    }
}
