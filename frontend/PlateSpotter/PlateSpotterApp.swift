import SwiftUI

@main
struct PlateSpotterApp: App {
    @StateObject var authManager = AuthManager()
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var historyManager = HistoryManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authManager)
                .environmentObject(authVM)
                .environmentObject(historyManager)
        }
    }
}
