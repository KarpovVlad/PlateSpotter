import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var historyManager: HistoryManager
    @State private var inputPlate: String = ""
    @State private var status: LookupStatus? = nil
    @State private var selectedPlate: String? = nil
    @State private var navigateToResult = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loginError: String?
    @State private var guestMode: Bool = false
    @State private var isRegister = false
    enum LookupStatus {
        case success, notFound, error, loading
    }
    private var isSignedInOrGuest: Bool {
        return authVM.token != nil || guestMode
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("PlateSpotter")
                    .font(.largeTitle)
                    .bold()
                NavigationLink(
                    destination: selectedPlate.map { ResultView(plateNumber: $0) },
                    isActive: $navigateToResult
                ) {
                    EmptyView()
                }
                .hidden()
                
                if !isSignedInOrGuest {
                    loginPanel
                }
                
                if authVM.token != nil || guestMode {
                    searchPanel
                    Divider().padding(.horizontal)
                }
                
                if (authVM.token != nil || guestMode), !historyManager.history.isEmpty {
                    Text("Останні перевірки")
                        .font(.headline)
                        .padding(.top, 8)

                    List {
                        ForEach(historyManager.history, id: \.self) { plate in
                            NavigationLink(destination: ResultView(plateNumber: plate)) {
                                Text(plate)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }

                Spacer()
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authVM.token == nil && !guestMode {
                        Menu {
                            Button("Увійти (guest)") {
                                guestMode = true
                                historyManager.loadLocalHistory()
                            }
                            Button("Логін тест (email)") {
                                let vm = authVM
                                vm.login(email: "test@example.com", password: "password") { success, message in
                                    DispatchQueue.main.async {
                                        if success, let token = vm.token {
                                            guestMode = false
                                            historyManager.syncServerHistory(token: token)
                                        } else {
                                            loginError = message ?? "Не вдалося увійти (тест)."
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "person.crop.circle.badge.plus")
                        }
                    } else {
                        Button("Вийти") {
                            authVM.logout()
                            guestMode = false
                            historyManager.loadLocalHistory()
                        }
                    }
                }
            }
            .onAppear {
                if let token = authVM.token {
                    historyManager.syncServerHistory(token: token)
                } else {
                    historyManager.loadLocalHistory()
                }
            }
            .onChange(of: authVM.token) { newToken in
                if let token = newToken {
                    guestMode = false
                    historyManager.syncServerHistory(token: token)
                } else if !guestMode {
                    historyManager.loadLocalHistory()
                }
            }
        }
    }

    private var loginPanel: some View {
        VStack(spacing: 10) {
            Text(isRegister ? "Створити акаунт" : "Увійти в акаунт")
                .font(.headline)

            Toggle("Створити акаунт", isOn: $isRegister)
                .padding(.horizontal)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if let err = loginError {
                Text(err).foregroundColor(.red).font(.caption)
            }
            HStack(spacing: 12) {
                Button(action: {
                    if isRegister {
                        authVM.register(email: email, password: password) { ok, msg in
                            if ok, let t = authVM.token {
                                guestMode = false
                                loginError = nil
                                historyManager.syncServerHistory(token: t)
                            } else {
                                loginError = msg ?? "Не вдалося зареєструватися."
                            }
                        }
                    } else {
                        authVM.login(email: email, password: password) { ok, msg in
                            if ok, let t = authVM.token {
                                guestMode = false
                                loginError = nil
                                historyManager.syncServerHistory(token: t)
                            } else {
                                loginError = msg ?? "Не вдалося увійти."
                            }
                        }
                    }
                }) {
                    Text(isRegister ? "Зареєструватися" : "Увійти")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    guestMode = true
                    historyManager.loadLocalHistory()
                }) {
                    Text("Гість").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            SignInWithAppleButton(
                onRequest: { request in
                    authVM.authManager.handleAppleRequest(request)
                },
                onCompletion: { result in
                    authVM.authManager.handleAppleResult(result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            .padding(.horizontal)
            .cornerRadius(8)
            .padding(.top, 6)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var searchPanel: some View {
        VStack(spacing: 8) {
            TextField("Введіть номер (наприклад: АІ1234НК)", text: $inputPlate)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.allCharacters)

            Button(action: {
                Task { await lookupPlate() }
            }) {
                Text("Перевірити")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            if let status = status {
                switch status {
                case .loading:
                    ProgressView()
                case .success:
                    Text("Дані знайдено")
                        .foregroundColor(.green)
                case .notFound:
                    Text("Номер не знайдено")
                        .foregroundColor(.red)
                case .error:
                    Text("Сталася помилка")
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    func transliterate(_ plate: String) -> String {
        let map: [Character: String] = [
            "А": "A", "В": "B", "С": "C", "Е": "E", "Н": "H",
            "І": "I", "К": "K", "М": "M", "О": "O", "Р": "P",
            "Т": "T", "Х": "X", "У": "Y"
        ]
        return plate.uppercased().map { map[$0] ?? String($0) }.joined()
    }

    func isValidPlate(_ plate: String) -> Bool {
        let pattern = #"^[A-ZА-ЯІЇЄҐ]{2}\d{4}[A-ZА-ЯІЇЄҐ]{2}$"#
        return plate.range(of: pattern, options: .regularExpression) != nil
    }

    func lookupPlate() async {
        let original = inputPlate.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard isValidPlate(original) else {
            status = .error
            return
        }

        let plate = transliterate(original)
        guard let url = URL(string: "\(APIConfig.baseURL)/api/lookup?plate=\(plate)") else {
            status = .error
            return
        }

        status = .loading

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200:
                    if let token = authVM.token {
                        historyManager.addServerHistory(token: token, plate: plate)
                    } else {
                        historyManager.addLocalHistory(plate)
                    }
                    selectedPlate = plate
                    navigateToResult = true
                    status = .success
                case 404:
                    status = .notFound
                default:
                    status = .error
                }
            }
        } catch {
            status = .error
        }
    }
}
