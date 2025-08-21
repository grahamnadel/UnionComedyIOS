import SwiftUI

struct SelectedPerformerList: View {
    var selected: [PerformerInput]
    var onRemove: (IndexSet) -> Void // Note the updated signature
//    var onPickPhoto: (PerformerInput) -> Void

    var body: some View {
        // Use a List to get native swipe-to-delete behavior
        List {
            ForEach(selected) { performer in
                HStack {
                    Text(performer.name)
                    Spacer()
//                    Button(action: { onPickPhoto(performer) }) {
//                        Image(systemName: "photo")
//                            .foregroundColor(.blue)
//                    }
                    .buttonStyle(BorderlessButtonStyle()) // Prevents the whole row from being tappable
                }
            }
            .onDelete(perform: onRemove)
        }
    }
}
