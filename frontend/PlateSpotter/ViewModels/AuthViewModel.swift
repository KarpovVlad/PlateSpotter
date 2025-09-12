import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authManager = AuthManager()
    @Published var token: String? {
        didSet {
            if let t = token {
                UserDefaults.standard.set(t, forKey: "authToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        }
    }
    @Published var isGuest = false
    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var tokenType: String?
    @Published var fullName: String = ""
    @Published var bio: String = ""
    @Published var currentUser: UserModel?
    @Published var email: String? = nil

    init() {
        self.token = UserDefaults.standard.string(forKey: "authToken")
        if let token = self.token {
            Task {
                await self.checkUser(token: token)
                fetchCurrentUser()
            }
        }
    }
    
    func register(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/register") else {
            completion(false, "Bad URL"); return
        }
        let body: [String: String] = ["email": email, "password": password]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false, "Encoding error"); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = httpBody

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let http = response as? HTTPURLResponse, http.statusCode == 409 {
                DispatchQueue.main.async { completion(false, "Email вже зайнятий") }
                return
            }
            guard let data = data,
                  let resp = try? JSONDecoder().decode([String:String].self, from: data),
                  let token = resp["access_token"] else {
                DispatchQueue.main.async { completion(false, "Реєстрація не вдалася") }
                return
            }
            DispatchQueue.main.async {
                self.token = token
                self.isAuthenticated = true
                self.isGuest = false
                completion(true, nil)
            }
        }.resume()
    }
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/login") else {
            completion(false, "Bad URL"); return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email, "password": password]
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(false, "Encoding error"); return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("Auth login error:", error)
                DispatchQueue.main.async { completion(false, "Помилка з'єднання") }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(false, "Немає відповіді від сервера") }
                return
            }

            if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = parsed["access_token"] as? String {
                DispatchQueue.main.async {
                    self.token = access
                    self.isAuthenticated = true
                    self.isGuest = false
                    Task { await self.checkUser(token: access) }
                    completion(true, nil)
                }
            } else {
                let respStr = String(data: data, encoding: .utf8) ?? "<no-data>"
                print("Auth login: unexpected response:", respStr)
                DispatchQueue.main.async { completion(false, "Невірний email або пароль") }
            }
        }.resume()
    }

    func loginAsGuest(completion: @escaping (Bool) -> Void = {_ in}) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/guest") else {
            completion(false); return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("Guest login error:", error)
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = parsed["access_token"] as? String {
                DispatchQueue.main.async {
                    self.token = access
                    Task { await self.checkUser(token: access) }
                    completion(true)
                }
            } else {
                print("Guest login: unexpected response:", String(data: data, encoding: .utf8) ?? "<no-data>")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    func logout() {
        token = nil
        isGuest = false
        isAuthenticated = false
        userId = nil
        tokenType = nil
        email = nil
    }

    func checkUser(token: String) async {
        guard let url = URL(string: "\(APIConfig.baseURL)/user/me") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                print("checkUser: http status \(http.statusCode), body:", String(data: data, encoding: .utf8) ?? "")
                DispatchQueue.main.async {
                    self.isGuest = false
                    self.isAuthenticated = false
                    self.userId = nil
                    self.tokenType = nil
                    self.email = nil
                }
                return
            }

            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let userIdInt = obj?["user_id"] as? Int
            let userIdStr = (obj?["userId"] as? String) ?? (userIdInt != nil ? String(userIdInt!) : nil)
            let authProvider = (obj?["auth_provider"] as? String)
                ?? (obj?["tokenType"] as? String)
                ?? (obj?["token_type"] as? String)
                ?? "email"
            let email = obj?["email"] as? String

            DispatchQueue.main.async {
                self.userId = userIdStr
                self.tokenType = authProvider
                self.email = email
                self.isGuest = authProvider.lowercased() == "guest"
                self.isAuthenticated = !self.isGuest
            }
        } catch {
            print("checkUser error:", error)
            DispatchQueue.main.async {
                self.isGuest = false
                self.isAuthenticated = false
                self.email = nil
            }
        }
    }

    func fetchCurrentUser() {
        guard let token = token else { return }
        var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/user/me")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("fetchCurrentUser error:", error)
                return
            }
            guard let data = data else { return }
            do {
                let userProfile = try JSONDecoder().decode(UserModel.self, from: data)
                DispatchQueue.main.async {
                    self.currentUser = userProfile
                }
            } catch {
                print("fetchCurrentUser decode error:", error)
            }
        }.resume()
    }
}

extension AuthViewModel {
    func exchangeAppleIdentityToken(_ identityToken: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/apple") else {
            completion(false); return
        }
        let body: [String: String] = ["identity_token": identityToken]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            completion(false); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = httpBody
        URLSession.shared.dataTask(with: req) { data, resp, err in
            guard let data = data,
                  let dict = try? JSONDecoder().decode([String:String].self, from: data),
                  let t = dict["access_token"] else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async {
                self.token = t
                completion(true)
            }
        }.resume()
    }
}

extension AuthViewModel {
    func updateProfile(name: String, bio: String, completion: @escaping (Bool, String?) -> Void) {
        guard let token = self.token,
              let url = URL(string: "\(APIConfig.baseURL)/user/update") else {
            completion(false, "No token")
            return
        }
        
        let body: [String: String] = [
            "name": name,
            "bio": bio
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            completion(false, "Encoding error")
            return
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = httpBody
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, "Connection error: \(error.localizedDescription)") }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(false, "No data") }
                return
            }
            
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let serverMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                DispatchQueue.main.async { completion(false, serverMsg) }
                return
            }
            
            DispatchQueue.main.async {
                self.fullName = name
                self.bio = bio
                completion(true, nil)
            }
        }.resume()
    }
}
