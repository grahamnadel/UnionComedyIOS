import SwiftUI

struct TeamListView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""   // Search field text
    @State private var showDeleteAlert = false
    @State private var teamToDelete: String?

    var filteredTeams: [String] {
        let teams = scheduleViewModel.teams.map { $0.name }
        if searchText.isEmpty {
            return teams.sorted()
        } else {
            return teams.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }.sorted()
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(searchCategory: "team", searchText: $searchText)
                    .padding(.horizontal)

                List {
                    ForEach(filteredTeams, id: \.self) { team in
                        HStack {
                            Text(team)
                                .font(.body)
                            
                            Spacer()
                            
                            if scheduleViewModel.favoriteTeams.contains(team) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(scheduleViewModel.favoriteTeamColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .background(
                            NavigationLink("", destination: TeamDetailView(teamName: team))
                                .opacity(0)
                        )
                        .padding(.vertical, 4)
                    }
                    // Enable deletion only for owners
                    .onDelete { indexSet in
                        guard authViewModel.role == .owner else { return }
                        if let index = indexSet.first {
                            teamToDelete = filteredTeams[index]
                            showDeleteAlert = true
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    scheduleViewModel.loadData()
                    scheduleViewModel.loadTeams()
                }
            }
            .navigationTitle("Teams")
        }
        .alert(isPresented: $showDeleteAlert) {
            SimpleAlert.confirmDeletion(
                title: "Delete Team?",
                message: "This will remove the team and all its performances.",
                confirmAction: {
                    if let team = teamToDelete {
                        scheduleViewModel.deleteTeam(named: team)
                    }
                }
            )
        }
    }
}
