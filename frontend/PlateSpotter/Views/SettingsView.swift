import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Зовнішній вигляд")) {
                    Toggle("Темна тема", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _ in
                            UIApplication.shared.windows.first?.overrideUserInterfaceStyle =
                                isDarkMode ? .dark : .light
                        }
                }
                Section {
                    Text("Версія застосунка: 1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Налаштування")
        }
    }
}

