import SwiftUI

struct PerformerImageView: View {
    let performerURL: URL?

    var body: some View {
        ZStack {
            // Outer ring (larger)
            Circle()
                .stroke(Color.purple.opacity(0.6), lineWidth: 3)
                .scaleEffect(1.06)

            // Inner image / placeholder
            Group {
                if let performerURL {
                    AsyncImage(url: performerURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholder
                    }
                } else {
                    placeholder
                }
            }
            .clipShape(Circle())
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 40))
            )
    }
}
