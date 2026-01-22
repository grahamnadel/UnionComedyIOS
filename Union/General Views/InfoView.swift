import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background (matching FestivalView)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.13, blue: 0.20),
                        Color(red: 0.25, green: 0.15, blue: 0.35),
                        Color(red: 0.15, green: 0.13, blue: 0.20)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the Theatre")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Location, hours, and contact info")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Logo
                    Image("UnionLogoCrop")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 24)
                    
                    // Info Cards
                    ScrollView {
                        VStack(spacing: 12) {
                            infoCard(
                                title: "Location",
                                icon: "mappin.and.ellipse",
                                lines: ["593 Somerville Ave", "Somerville, MA"]
                            )
                            
                            infoCard(
                                title: "Contact",
                                icon: "envelope.fill",
                                lines: ["info@unioncomedy.com"]
                            )
                            
                            infoCard(
                                title: "Hours",
                                icon: "clock.fill",
                                lines: [
                                    "Friday–Saturday: 7–10pm",
                                    "Sunday: 5–8pm"
                                ]
                            )
                            
                            infoCard(
                                title: "Festival Location",
                                icon: "star.fill",
                                lines: ["255 Elm St", "Somerville, MA 02144"]
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    @ViewBuilder
    private func infoCard(title: String, icon: String, lines: [String]) -> some View {
        VStack(spacing: 12) {
            // Icon and Title
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.96),
                                    Color(red: 0.92, green: 0.35, blue: 0.61)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .background(.ultraThinMaterial.opacity(0.3))
                .cornerRadius(16)
        )
    }
}
