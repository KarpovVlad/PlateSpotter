import SwiftUI
import AVFoundation
import Vision

struct CameraRecognitionView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session)
                .edgesIgnoringSafeArea(.all)
            
            ForEach(viewModel.detectedPlates, id: \.self) { plate in
                PlateOverlay(plate: plate) {
                    viewModel.navigateToResult(for: plate.text)
                }
            }
        }
        .onAppear { viewModel.startSession() }
        .onDisappear { viewModel.stopSession() }
        .sheet(item: $viewModel.selectedPlate) { plate in
            ResultView(plateNumber: plate.number)
        }
    }
}

struct PlateOverlay: View {
    let plate: DetectedPlate
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let rect = plate.boundingBox.scaled(to: geometry.size)
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.orange, lineWidth: 2.5)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    
                    Text(plate.text)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Color.orange.opacity(0.7))
                        .cornerRadius(4)
                        .position(x: rect.midX, y: rect.maxY + 12)
                }
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.queue")
    
    @Published var detectedPlates: [DetectedPlate] = []
    @Published var selectedPlate: PlateSelection?
    
    func startSession() {
        configureCamera()
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    private func configureCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }
        
        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        
        session.commitConfiguration()
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { [weak self] request, _ in
            self?.handleTextRecognition(request)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([request])
    }
    
    private func handleTextRecognition(_ request: VNRequest) {
        guard let results = request.results as? [VNRecognizedTextObservation] else { return }
        var plates: [DetectedPlate] = []
        
        for observation in results {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string.uppercased()
            if text.range(of: "^[A-Z]{2}[0-9]{4}[A-Z]{2}$", options: .regularExpression) != nil {
                plates.append(DetectedPlate(text: text, boundingBox: observation.boundingBox))
            }
        }
        
        DispatchQueue.main.async {
            self.detectedPlates = plates
        }
    }
    
    func navigateToResult(for plate: String) {
        selectedPlate = PlateSelection(number: plate)
    }
}

struct DetectedPlate: Hashable {
    let text: String
    let boundingBox: CGRect
}

struct PlateSelection: Identifiable {
    let id = UUID()
    let number: String
}

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        CGRect(
            x: self.minX * size.width,
            y: (1 - self.maxY) * size.height,
            width: self.width * size.width,
            height: self.height * size.height
        )
    }
}

