import Foundation

struct UserService {
    func fetchCurrentUser(token: String) {
        guard let url = URL(string: "\(APIConfig.baseURL)/user/me") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("Sending token header: Bearer \(token)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                print("Response: \(responseStr)")
            }
        }.resume()
    }
}

