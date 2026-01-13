import SwiftUI

struct TeamDetailView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @State private var performerURLs: [String: URL] = [:]
    @State private var isHouseTeam: Bool = false
    let teamName: String
    
    var team: Team? {
        scheduleViewModel.teams.first { $0.name == teamName }
    }
    
    var performancesForTeam: [Performance] {
        scheduleViewModel.performances
            .filter { $0.teamName == teamName }
            .sorted { $0.showTime < $1.showTime }
    }
    
    var body: some View {
        ZStack {
            // 1. Consistent Gradient Background
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
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Styled Team Name
                    Text(teamName.uppercased())
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .kerning(2)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background {
                            // Ensure the Capsule is the ONLY thing here
                            Capsule()
                                .fill(.white.opacity(0.1))
                                .background(.ultraThinMaterial)
                                // This clipShape ensures the blur doesn't leak into a rectangle
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                        }
                        .padding(.top, 20)
                    
                    // House/Indie Toggle for Owners
                    if authViewModel.role == .owner {
                        Toggle(isOn: $isHouseTeam) {
                            Text(isHouseTeam ? "House Team" : "Indie Team")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                        .padding(.horizontal)
                        .onChange(of: isHouseTeam) { newValue in
                             if let currentTeam = team,
                               let index = scheduleViewModel.teams.firstIndex(where: { $0.id == currentTeam.id }) {
                                 scheduleViewModel.teams[index].houseTeam = newValue
                                 scheduleViewModel.updateTeamType(teamName: teamName, isHouseTeam: newValue)
                             }
                        }
                    }

                    // 3. Performances Section
                    VStack(spacing: 12) {
                        Label("PERFORMANCES", systemImage: "calendar")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.purple.opacity(0.8))
                            .padding(.horizontal)
                        
                        if !performancesForTeam.isEmpty {
                            ForEach(performancesForTeam, id: \.id) { performance in
                                TeamListPerformanceRow(performance: performance)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
                                    .padding(.horizontal)
                            }
                        } else {
                            Text("No performances scheduled.")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                    
                    // 4. Performers Section (Grid/Card style)
                    if let team = team {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("PERFORMERS", systemImage: "person.3.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.purple.opacity(0.8))
                                .padding(.horizontal)
                            
                            VStack(spacing: 10) {
                                ForEach(team.performers, id: \.self) { performer in
                                    HStack {
                                        AsyncImage(url: performerURLs[performer]) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.white.opacity(0.1)
                                                .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.3)))
                                        }
                                        .frame(width: 44, height: 44)
                                        .clipShape(Circle())
                                        
                                        Text(performer)
                                            .font(.headline)
                                            .foregroundColor(favoritesViewModel.favoritePerformers.contains(performer) ? favoritesViewModel.favoritePerformerColor : .white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    FavoriteTeamButton(teamName: teamName)
                        .padding(.vertical)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let team = team { isHouseTeam = team.houseTeam }
        }
        .task { await loadPerformerURLs() }
        .toolbar {
            if authViewModel.role == .owner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditTeamPerformersView(teamName: teamName)) {
                        Image(systemName: "pencil.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.purple)
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
