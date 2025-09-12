import Foundation

struct UserModel: Codable {
    let userId: Int
    let email: String
    let authProvider: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case authProvider = "auth_provider"
    }
}

