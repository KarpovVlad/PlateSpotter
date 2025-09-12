import SwiftUI

struct ProfileMenuView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showProfileEdit = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(authVM.fullName.isEmpty ? "Користувач" : authVM.fullName)
                                .font(.headline)
                            Text(authVM.email ?? "—")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section {
                    Button { showProfileEdit = true } label: {
                        Label("Профіль", systemImage: "pencil")
                    }
                    Button { showSettings = true } label: {
                        Label("Налаштування", systemImage: "gearshape")
                    }
                }
                Section {
                    Button { authVM.logout() } label: {
                        Label("Вийти з аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Мій профіль")
            .sheet(isPresented: $showProfileEdit) {
                EditProfileView().environmentObject(authVM)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(authVM)
            }
        }
    }
}
