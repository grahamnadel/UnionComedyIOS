import SwiftUI

struct PerformerImageView: View {
    let performerURL: URL?
    let performerName: String // Add this to handle initials

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.purple.opacity(0.6), lineWidth: 3)
                .scaleEffect(1.06)

            Group {
                if let performerURL {
                    AsyncImage(url: performerURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        VStack {
                            placeholder
                            Text("Placeholder")
                        }
                        
                    }
                } else {
                    placeholder
                }
            }
            .clipShape(Circle())
        }
    }

    private var placeholder: some View {
        ZStack {
            // Professional Gradient Background
            LinearGradient(
                colors: [Color.purple, Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Initials Text
            Text(getInitials(from: performerName))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
                .minimumScaleFactor(0.5) // Prevents clipping if initials are long
                .padding(8)
        }
    }

    // Helper function to extract initials
    private func getInitials(from name: String) -> String {
        let words = name.components(separatedBy: " ")
        let initials = words.compactMap { $0.first }
        return String(initials.prefix(2)).uppercased()
    }
}
