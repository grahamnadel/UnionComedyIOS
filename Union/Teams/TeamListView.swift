import SwiftUI

struct TeamListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var searchText = ""   // Search field text
    
    // Filtered & sorted teams
    var filteredTeams: [String] {
        let teams = Set(festivalViewModel.performances.map { $0.teamName })
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
                // 🔍 Add the Search Bar
                SearchBar(searchCategory: "team", searchText: $searchText)
                    .padding(.horizontal)
                
                List(filteredTeams, id: \.self) { team in
                    HStack {
                        Text(team)
                            .font(.body)
                        
                        Spacer()
                        
                        // Show star if team is a favorite
                        if festivalViewModel.favoriteTeams.contains(team) {
                            Image(systemName: "star.fill")
                                .foregroundColor(festivalViewModel.favoriteTeamColor)
                        }
                    }
                    .contentShape(Rectangle())  // Make entire row tappable
                    .background(
                        NavigationLink("", destination: TeamDetailView(teamName: team))
                            .opacity(0) // Invisible link for full-row navigation
                    )
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    festivalViewModel.loadData()
                }
            }
            .navigationTitle("Teams")
        }
    }
}
