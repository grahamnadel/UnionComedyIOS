import SwiftUI


struct PerformerSuggestionList: View {
    let suggestions: [String]
    @Binding var selected: [PerformerInput]
    var onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(suggestions, id: \.self) { name in
                Button(action: {
                    // Add to selected performers
                    onSelect(name)
                }) {
                    HStack {
                        Text(name)
                        Spacer()
                        if selected.contains(where: { $0.name == name }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}
