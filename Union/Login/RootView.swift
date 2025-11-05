import SwiftUI
import Foundation
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    
    var body: some View {
        Group {
            if let _ = authViewModel.user {
                if let role = authViewModel.role {
                    if !authViewModel.approved && role != .audience {
                        Text("Your \(role.rawValue.capitalized) account is pending approval.")
                            .font(.headline)
                            .padding()
                        
                        Button("Log Out") {
                            authViewModel.signOut()
                        }
                    } else {
                        TabView {
                            FestivalView()
                                .task {
                                    if authViewModel.role == .owner {
                                        await scheduleViewModel.fetchPendingUsers()
                                        await scheduleViewModel.fetchUsers()
                                    }
                                }
                                .tabItem { Label("Schedule", systemImage: "calendar") }

                                 InfoView()
                                     .tabItem { Label("Info", systemImage: "info.circle") }
                        }
                    }
                } else {
                    ProgressView("Loading user data…")
                }
            } else {
                InitialLoginView()
            }
        }
        .onAppear {
            Task {
                if let loginInfo = KeychainHelper.load() {
                    do {
                        try await authViewModel.signIn(email: loginInfo.email, password: loginInfo.password)
                    } catch {
                        print("Auto-login failed: \(error.localizedDescription)")
                    }
                    
                }
            }
        }
    }
}
