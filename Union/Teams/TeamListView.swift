import SwiftUI

struct TeamListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var searchText = ""   // <-- NEW: search text
    
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
                    NavigationLink(destination: TeamDetailView(team: team)) {
                        Text(team)
                    }
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
