import SwiftUI

struct CommentsView: View {
    let plateNumber: String
    @EnvironmentObject var authVM: AuthViewModel
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Завантаження коментарів…")
            } else {
                List(comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.author)
                            .font(.headline)
                        Text(comment.text)
                        Text(comment.timestamp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                TextField("Ваш коментар", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Надіслати") {
                    sendComment()
                }
                .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Коментарі")
        .onAppear {
            fetchComments()
        }
    }
    
    func fetchComments() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/comments/\(plateNumber)") else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([Comment].self, from: data) {
                    DispatchQueue.main.async {
                        comments = decoded
                        isLoading = false
                    }
                }
            }
        }.resume()
    }
    
    func sendComment() {
        guard let token = authVM.token else { return }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/comments/\(plateNumber)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["text": newComment])
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let http = response as? HTTPURLResponse, http.statusCode == 201 {
                DispatchQueue.main.async {
                    fetchComments()
                    newComment = ""
                }
            }
        }.resume()
    }
}

struct Comment: Identifiable, Codable {
    let id: Int
    let author: String
    let text: String
    let timestamp: String
}

