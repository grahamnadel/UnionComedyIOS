import Foundation
import SwiftUI

struct FestivalView: View {
    enum sortSelection: String, CaseIterable {
        case date = "Shows"
        case performers = "Cast"
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
            ZStack {
                // Modern gradient background
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
                        Text(headerTitle)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(headerSubtitle)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Segmented Control
                    ModernSegmentedButtons(selection: $selected, options: availableOptions)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    
                    // Content Views
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
            }
            .toolbar {
                // Trailing plus button (only if owner logged in)
                if authViewModel.role == .owner {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddPerformance = true
                        } label: {
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
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: AccountView(showingDeleteConfirmation: $showingDeleteConfirmation)) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.purple.opacity(0.8))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    callDeleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.")
            }
            .alert("Error Deleting Account", isPresented: $showingErrorAlert) {
                Button("OK") { }
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
    
    var headerTitle: String {
        switch selected {
        case .date:
            return "Shows"
        case .performers:
            return "Cast"
        case .teams:
            return "Teams"
        case .pendingApproval:
            return "Admin"
        }
    }
    
    var headerSubtitle: String {
        switch selected {
        case .date:
            return "Browse upcoming performances"
        case .performers:
            return "View all performers"
        case .teams:
            return "Manage your performance groups"
        case .pendingApproval:
            return "Review pending requests"
        }
    }
    
    func callDeleteAccount() {
        FirebaseManager.shared.deleteAccount { error in
            if let error = error as? NSError {
                if error.code == 17014 {
                    self.errorMessage = "Please enter your current password to confirm the deletion."
                    self.showingReAuthPrompt = true
                } else {
                    self.errorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            } else if error != nil {
                errorMessage = "An unknown error occurred while trying to delete your account."
                showingErrorAlert = true
            } else {
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


struct ModernSegmentedButtons<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T
    let options: [T]
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selection == option ? .white : Color.white.opacity(0.5))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.58, green: 0.29, blue: 0.96),
                                                Color(red: 0.92, green: 0.35, blue: 0.61)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
                                    .matchedGeometryEffect(id: "selectedTab", in: animation)
                            }
                        }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
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
