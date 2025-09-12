import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false
    @State private var saveMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Особисті дані")) {
                    TextField("Ім'я та прізвище", text: $fullName)
                        .textInputAutocapitalization(.words)
                    TextField("Біографія", text: $bio)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                if let message = saveMessage {
                    Text(message)
                        .foregroundColor(message.contains("Помилка") ? .red : .green)
                        .font(.footnote)
                }
            }
            .navigationTitle("Редагувати профіль")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Зберегти") {
                            saveProfile()
                        }
                    }
                }
            }
            .onAppear {
                fullName = authVM.fullName
                bio = authVM.bio
            }
        }
    }

    private func saveProfile() {
            isSaving = true
            saveMessage = nil
            authVM.updateProfile(name: fullName, bio: bio) { success, message in
                isSaving = false
                if success {
                    saveMessage = "Профіль оновлено"
                    authVM.fullName = fullName
                    authVM.bio = bio
                } else {
                    saveMessage = "Помилка: \(message ?? "невідома")"
                }
            }
        }
    }
