import SwiftUI
import Foundation
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var isCheckingLogin = true
    
    var body: some View {
        Group {
            if isCheckingLogin {
                LoadingScreen()
            } else {
                if let _ = authViewModel.user {
                    if let _ = authViewModel.role {
                        // Main Content Tabs
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
                    } else {
                        ProgressView("Loading user data…")
                    }
                } else {
                    InitialLoginView()
                }
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
                isCheckingLogin = false
            }
        }
    }
}
