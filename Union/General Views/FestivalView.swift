import Foundation
import SwiftUI

//            New Feature:

struct FestivalView: View {
    enum sortSelection: String, CaseIterable {
        case date = "Shows"
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
            VStack(spacing: 0) {
                VStack {
                    SegmentedButtons(selection: $selected, options: availableOptions)
                        .padding()
                }
                .background(.black)
                .ignoresSafeArea(edges: .horizontal)
                
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
                    NavigationLink(destination: AccountView(showingDeleteConfirmation: $showingDeleteConfirmation)) {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.blue)
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
        if let name = authViewModel.name {
            if authViewModel.role != .audience {
                print("name for deletion: \(name)")
                scheduleViewModel.removePerformerFromFirebase(teamName: nil, performerName: name)
                scheduleViewModel.removePerformerFromTeamsCollection(performerName: name, team: nil)
                scheduleViewModel.removePerformerFromFestivalTeamsCollection(performerName: name)
                scheduleViewModel.removePerformerFromPerformersCollection(performerName: name)
            }
            scheduleViewModel.removeFromUsersCollection(name: name)
        } else {
            print("Could not unwrap name")
        }
    }
}


struct SegmentedButtons<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T
    let options: [T]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(option.rawValue)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(selection == option ? Color.clear : Color.purple)
                            .foregroundColor(selection == option ? .purple : .white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
