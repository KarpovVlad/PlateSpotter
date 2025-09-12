import SwiftUI
import Vision
import UIKit

struct RecognizedPlate: Identifiable {
    let id = UUID()
    let number: String
}

struct PhotoRecognitionView: View {
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var recognizedPlate: RecognizedPlate?
    @State private var recognitionError: String?

    var body: some View {
        VStack {
            Spacer()

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .padding()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    .frame(height: 300)
                    .overlay(Text("Немає зображення").foregroundColor(.gray))
                    .padding()
            }

            HStack(spacing: 16) {
                Button(action: { showImagePicker = true }) {
                    Label("Завантажити фото", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    if let img = selectedImage {
                        recognizePlate(from: img)
                    }
                }) {
                    Label("Розпізнати", systemImage: "viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            if let error = recognitionError {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top)
            }

            Spacer()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, onImagePicked: { image in
                self.selectedImage = image
            })
        }
        .sheet(item: $recognizedPlate) { plate in
            ResultView(plateNumber: plate.number)
        }
        .navigationTitle("Розпізнати фото")
    }

    func normalizePlate(_ text: String) -> String {
        var cleaned = text.uppercased()
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")
        cleaned = cleaned.replacingOccurrences(of: "-", with: "")

        let map: [Character: Character] = [
            "А": "A", "В": "B", "Е": "E", "Т": "T", "О": "O",
            "Х": "X", "С": "C", "К": "K", "М": "M", "Н": "H",
            "Р": "P", "У": "Y", "І": "I"
        ]
        cleaned = String(cleaned.map { map[$0] ?? $0 })

        return cleaned
    }

    func recognizePlate(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.recognitionError = "Помилка: \(error.localizedDescription)"
                }
                return
            }
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }

            let pattern = "^[A-Z]{2}[0-9]{4}[A-Z]{2}$"

            for obs in results {
                guard let candidate = obs.topCandidates(1).first else { continue }
                var text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                text = normalizePlate(text)

                if text.range(of: pattern, options: .regularExpression) != nil {
                    DispatchQueue.main.async {
                        self.recognizedPlate = RecognizedPlate(number: text)
                        self.recognitionError = nil
                    }
                    return
                }
            }

            DispatchQueue.main.async {
                self.recognitionError = "Помилка перевірки: Номер не знайдено на фото"
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.recognitionError = "VNImageRequestHandler error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImagePicked(uiImage)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
