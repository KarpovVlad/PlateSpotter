import Foundation

enum APIEnvironment {
    case simulator      // iOS Simulator
    case deviceLocal
    case deviceNgrok    // ngrok
}

struct APIConfig {
    static let current: APIEnvironment = .simulator

    static var baseURL: String {
        switch current {
        case .simulator:
            return "http://127.0.0.1:8000"
        case .deviceLocal:
            return "http://127.0.0.1:8000" // заміни на свій локальний IP
        case .deviceNgrok:
            return "-"
        }
    }
}

