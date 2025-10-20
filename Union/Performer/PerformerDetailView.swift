import SwiftUI

// Detail view showing all teams for a given performer
struct PerformerDetailView: View {
    let performer: String
    let performerURL: URL?
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    
    var performancesForPerformer: [Performance] {
        festivalViewModel.performances.filter { $0.performers.contains(performer) }
            .sorted { $0.showTime < $1.showTime }
    }
    
    // Get unique teams for this performer
    var teamsForPerformer: [String] {
        let teams = Set(performancesForPerformer.map { $0.teamName })
        return Array(teams).sorted()
    }
    
    var body: some View {
        VStack {
            PerformerImageView(performerURL: performerURL ?? nil)
            .frame(width: 250, height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .navigationTitle(performer)
            
            PerformerTeamsView(
                teamsForPerformer: teamsForPerformer,
                performancesForPerformer: performancesForPerformer
            )
            
//            if festivalViewModel.isAdminLoggedIn {
//                NavigationLink("Manage Teams") {
//                    TeamsListView(performerName: performer)
//                }
//            }
        }
    }
}
