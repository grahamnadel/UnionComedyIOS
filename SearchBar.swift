import SwiftUI

struct SearchBar: View {
    let searchCategory: String
    @Binding var searchText: String   // <-- Add this binding

    var body: some View {
        VStack {
            TextField("Search for a \(searchCategory)", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
        }
    }
}
