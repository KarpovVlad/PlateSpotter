import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { ContentView() }
                .tabItem { Label("Головна", systemImage: "magnifyingglass") }
                .tag(0)

            if authVM.isAuthenticated && !authVM.isGuest {
                NavigationStack { CarSearchView() }
                    .tabItem { Label("Пошук авто", systemImage: "square.grid.2x2") }
                    .tag(1)

                NavigationStack { CameraRecognitionView() }
                    .tabItem { Label("Сканер", systemImage: "camera.viewfinder") }
                    .tag(2)

                NavigationStack { PhotoRecognitionView() }
                    .tabItem { Label("Фото", systemImage: "photo.artframe") }
                    .tag(3)

                NavigationStack { ProfileMenuView() }
                    .tabItem { Label("Профіль", systemImage: "person.crop.circle") }
                    .tag(4)
            }
        }
        .onChange(of: selectedTab) { newValue in
            if !authVM.isAuthenticated && newValue != 0 {
                selectedTab = 0
            }
        }
    }
}
