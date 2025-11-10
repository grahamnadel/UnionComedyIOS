import Foundation
import SwiftUI

//            New Feature:

struct FestivalView: View {
    enum sortSelection: String, CaseIterable {
        case date = "Date"
        case performers = "Performers"
        case teams = "Teams"
        case pendingApproval = "Admin"
    }
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var selected: sortSelection = .date
    @State private var showAddPerformance = false
    @State private var showingErrorAlert = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var showingReAuthPrompt = false
    
    var availableOptions: [sortSelection] {
        if authViewModel.role == .owner {
            return sortSelection.allCases
        } else {
            return sortSelection.allCases.filter { $0 != .pendingApproval }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Select View", selection: $selected) {
                    ForEach(availableOptions, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selected {
                case .date:
                    DateListView()
                case .performers:
                    PerformerListView()
                case .teams:
                    TeamListView()
                case .pendingApproval:
                    AdminView()
                }
                
                Spacer()
            }
            .toolbar {
                // Trailing plus button (only if owner logged in)
                if authViewModel.role == .owner {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddPerformance = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Sign Out") {
                            authViewModel.signOut()
                        }
                        Button(role: .destructive, action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete Account", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    callDeleteAccount() // Function to handle the actual call
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.")
            }
            // ➡️ Error Alert
            .alert("Error Deleting Account", isPresented: $showingErrorAlert) {
                Button("OK") {
                    // Depending on the error (e.g., requiresRecentLogin), you might
                    // need to prompt the user to re-authenticate here.
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingReAuthPrompt) {
                ReAuthView()
            }
            .sheet(isPresented: $showAddPerformance) {
                AddPerformanceView(date: nil, showType: nil)
            }
        }
    }
    
    func callDeleteAccount() {
        FirebaseManager.shared.deleteAccount { error in
            if let error = error as? NSError {
                        if error.code == 17014 { // AuthErrorCode.requiresRecentLogin
                            // ⚠️ Instead of just showing an error, trigger the password prompt UI
                            self.errorMessage = "Please enter your current password to confirm the deletion."
                            // ➡️ Set a new state to trigger the specialized re-auth sheet/alert
                            self.showingReAuthPrompt = true
                        } else {
                            // Other Firebase error
                            self.errorMessage = error.localizedDescription
                            self.showingErrorAlert = true
                        }
                    } else if error != nil {
                // Handle non-NSError errors
                errorMessage = "An unknown error occurred while trying to delete your account."
                showingErrorAlert = true
            } else {
                // Success: The sign out happens automatically after successful deletion
                // You can add a success confirmation if necessary, but typically the app
                // will transition back to the sign-in view because the auth state changes.
                print("Account deletion sequence initiated.")
            }
        }
        if authViewModel.role != .audience {
            if let name = authViewModel.name {
                scheduleViewModel.removePerformerFromFirebase(teamName: nil, performerName: name)
                scheduleViewModel.removePerformerFromTeamsCollection(performerName: name)
                scheduleViewModel.removePerformerFromFestivalTeamsCollection(performerName: name)
                scheduleViewModel.removePerformerFromPerformersCollection(performerName: name)
                scheduleViewModel.removeFromUsersCollection(name: name)
            }
        }
    }
}
