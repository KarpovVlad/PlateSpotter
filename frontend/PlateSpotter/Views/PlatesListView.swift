import SwiftUI

struct PlatesListView: View {
    let region: String
    let plates: [String]
    
    var body: some View {
        List {
            ForEach(plates.sorted(), id: \.self) { plate in
                NavigationLink(destination: ResultView(plateNumber: plate)) {
                    Text(plate)
                }
            }
        }
        .navigationTitle("Регіон \(region)")
    }
}
