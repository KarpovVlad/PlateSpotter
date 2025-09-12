import Foundation

struct UserMeResponse: Codable {
    let userId: String
    let tokenType: String
    let expiresIn: Int
}
