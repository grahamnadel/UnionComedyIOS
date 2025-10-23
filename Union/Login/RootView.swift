import SwiftUI
import Foundation

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var festivalViewModel: FestivalViewModel

    var body: some View {
        Group {
            if let _ = authViewModel.user {
                if let role = authViewModel.role {
                    if !authViewModel.approved && role != .audience {
                        Text("Your \(role.rawValue.capitalized) account is pending approval.")
                            .font(.headline)
                            .padding()
                    } else {
                        FestivalView()
                            .task {
                                await festivalViewModel.fetchPendingUsers()
                            }
                    }
                } else {
                    ProgressView("Loading user data…")
                }
            } else {
                InitialLoginView()
            }
        }
    }
}
