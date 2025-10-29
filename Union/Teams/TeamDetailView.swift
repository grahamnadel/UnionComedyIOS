import SwiftUI

struct TeamDetailView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let teamName: String
    @State private var performerURLs: [String: URL] = [:]
    
    var team: Team? {
        scheduleViewModel.teams.first { $0.name == teamName }
    }
    
    var performancesForTeam: [Performance] {
        scheduleViewModel.performances
            .filter { $0.teamName == teamName }
            .sorted { $0.showTime < $1.showTime }
    }
    
    var body: some View {
        VStack {
            List {
                // MARK: - Performances
                if !performancesForTeam.isEmpty {
                    Section(header: Text("Performances")) {
                        ForEach(performancesForTeam, id: \.id) { performance in
                            PerformanceRow(performance: performance)
                        }
                        // ✅ Only owners can delete
                        .onDelete { indexSet in
                            if authViewModel.role == .owner {
                                for index in indexSet {
                                    let perf = performancesForTeam[index]
                                    scheduleViewModel.deletePerformance(perf)
                                }
                            }
                        }
                    }
                } else {
                    
                    // MARK: - Performers
                    if let team = team {
                        Section(header: Text("Performers")) {
                            ForEach(team.performers, id: \.self) { performer in
                                NavigationLink(destination: PerformerDetailView(performer: performer)) {
                                    HStack {
                                        AsyncImage(url: performerURLs[performer]) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Text(performer)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .task {
                                await loadPerformerURLs()
                            }
                        }
                    }
                }
            }
            
            // MARK: - Favorite Button
            Button {
                scheduleViewModel.toggleFavoriteTeam(teamName)
            } label: {
                Image(systemName: scheduleViewModel.favoriteTeams.contains(teamName) ? "star.fill" : "star")
                    .foregroundColor(scheduleViewModel.favoriteTeamColor)
            }
        }
        .navigationTitle(teamName)
        .toolbar {
            // Owners can still edit performers
            if authViewModel.role == .owner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditTeamPerformersView(teamName: teamName)) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
    }
    
    private func loadPerformerURLs() async {
        if let team = team {
            for performer in team.performers {
                if performerURLs[performer] == nil {
                    if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
                        performerURLs[performer] = url
                    }
                }
            }
        }
    }
}
