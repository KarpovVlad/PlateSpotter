import SwiftUI
import AuthenticationServices

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName = ""
    @Published var userID: String = ""
    @Published var authToken: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var isGuest: Bool = false
    var canSeeHistory: Bool {
            return isLoggedIn || isGuest
        }
    
    func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                self.userName = credential.fullName?.givenName ?? "Apple User"
                self.userID = credential.user
                self.isAuthenticated = true
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    func signInWithEmail(email: String, password: String) {
        self.userName = email
        self.userID = UUID().uuidString
        self.isAuthenticated = true
    }
    
    func signInAsGuest() {
        self.userName = "Гість"
        self.userID = UUID().uuidString
        self.isAuthenticated = true
    }
    
    func loginAsGuest() {
            guard let url = URL(string: "\(APIConfig.baseURL)/auth/guest") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["access_token"] as? String {
                    DispatchQueue.main.async {
                        self.authToken = token
                        print("Guest token received: \(token)")
                    }
                } else {
                    print(" Failed to get token")
                }
            }.resume()
        }
    func logout() {
        self.isAuthenticated = false
        self.userName = ""
        self.userID = ""
    }
}
