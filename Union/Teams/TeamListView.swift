import SwiftUI

struct TeamListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    
    var sortedTeams: [String] {
        // Get all unique team names from performances
        let teams = Set(festivalViewModel.performances.map { $0.teamName })
        return teams.sorted()
    }
    
    var body: some View {
        NavigationStack {
            List(sortedTeams, id: \.self) { team in
                NavigationLink(destination: TeamDetailView(team: team)) {
                    Text(team)
                }
            }
            .navigationTitle("Sort By")
        }
    }
}

