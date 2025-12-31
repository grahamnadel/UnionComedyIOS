import SwiftUI

struct TeamListView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var teamToDelete: String?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var teamList: [String] {
        if authViewModel.role == .owner {
            return filteredAllTeams
        } else {
            return filteredHouseTeams
        }
    }
    
    var filteredAllTeams: [String] {
        scheduleViewModel.teams
            .filter {
                searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                if $0.houseTeam != $1.houseTeam {
                    return $0.houseTeam && !$1.houseTeam
                } else {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            }
            .map { $0.name }
    }
    
    var filteredHouseTeams: [String] {
        scheduleViewModel.teams
            .filter { $0.houseTeam }
            .filter {
                searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            .map { $0.name }
    }

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    SearchBar(searchCategory: "team", searchText: $searchText)
                        .padding(.horizontal)
                }
                .background(.purple)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(teamList, id: \.self) { team in
                            NavigationLink(destination: TeamDetailView(teamName: team)) {
                                VStack {
                                    ZStack(alignment: .topTrailing) {
                                        Image(team.lowercased())
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        if favoritesViewModel.favoriteTeams.contains(team) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(favoritesViewModel.favoriteTeamColor)
                                                .padding(8)
                                        }
                                    }
                                }
                            }
                            .contextMenu {
                                if authViewModel.role == .owner {
                                    Button(role: .destructive) {
                                        teamToDelete = team
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete Team", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    scheduleViewModel.loadData()
                    scheduleViewModel.loadTeams()
                    scheduleViewModel.loadPerformers()
                }
                .onAppear {
                    scheduleViewModel.loadTeams()
                }
            }
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
