import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var showPending = true
    @State private var searchText = ""

    var body: some View {
        VStack {
            // Search field
            TextField("Search by name…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Toggle for pending/all users
            Toggle(showPending ? "Pending Users" : "All Users", isOn: $showPending)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 8) {
                    if showPending {
                        Text(festivalViewModel.pendingUsers.isEmpty ? "No pending Approvals" : "Pending Approvals")
                            .font(.headline)

                        ForEach($festivalViewModel.pendingUsers.filter { $0.name.wrappedValue.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }, id: \.id) { $pendingUser in
                            HStack {
                                Spacer()
                                Toggle(isOn: $pendingUser.approved) {
                                    Text("Approval of \(pendingUser.name) as a \(pendingUser.role)")
                                }
                                .onChange(of: pendingUser.approved) { newValue in
                                    Task {
                                        await festivalViewModel.updateApproval(for: pendingUser)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        ForEach($festivalViewModel.users.filter { $0.name.wrappedValue.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }, id: \.id) { $appUser in
                            HStack {
                                Text("\(appUser.name)")
                                Spacer()
                                Picker("Role", selection: $appUser.role) {
                                    Text("Audience").tag(UserRole.audience)
                                    Text("Performer").tag(UserRole.performer)
                                    Text("Coach").tag(UserRole.coach)
                                    Text("Owner").tag(UserRole.owner)
                                }
                                .pickerStyle(.menu)
                                .onChange(of: appUser.role) { newValue in
                                    Task {
                                        await festivalViewModel.updateApproval(for: appUser)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .refreshable {
            await festivalViewModel.fetchPendingUsers()
            await festivalViewModel.fetchUsers()
        }
    }
}
