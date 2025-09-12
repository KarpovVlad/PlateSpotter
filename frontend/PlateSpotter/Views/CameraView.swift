import SwiftUI

struct CameraView: View {
    var body: some View {
        VStack {
            Text("Тут буде інтеграція з камерою")
                .font(.title3)
                .padding()

            NavigationLink(destination: ResultView(plateNumber: "AI0030YB")) {
                Text("Симулювати розпізнавання")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Сканування")
    }
}
