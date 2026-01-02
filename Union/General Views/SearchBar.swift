import SwiftUI

struct SearchBar: View {
    let searchCategory: String
    @Binding var searchText: String
    var onFilterTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            TextField(
                "",
                text: $searchText,
                prompt: Text("Search for a \(searchCategory)")
                    .foregroundColor(.purple.opacity(0.5))
            )
            .padding(.vertical, 10)
            .foregroundColor(.white)

            if let onFilterTap {
                Button(action: onFilterTap) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .imageScale(.medium)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.purple)
                        .padding(.leading, 6)
                }
                .accessibilityLabel("Filter by show type")
            }
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .stroke(.purple)
        )
    }
}
