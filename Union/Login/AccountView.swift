import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingDeleteConfirmation: Bool
    
    var body: some View {
        ZStack {
            // 1. Consistent Background
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

            VStack(spacing: 20) {
                // Header to match the brand style
                Text("ACCOUNT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple.opacity(0.8))
                    .kerning(2)
                    .padding(.top, 40)

                Spacer()
                
                // 2. Styled Sign Out Button
                Button {
                    authViewModel.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.05))
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                
                // 3. Styled Delete Account Button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
