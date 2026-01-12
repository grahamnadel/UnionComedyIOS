import SwiftUI

struct ShowtimeDetailView: View {
    let performances: Performances
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var performerURLs: [String:URL] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background matching other views
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
                    VStack {
                        Image("UnionLogoCrop")
                            .resizable()
                            .scaledToFit()
                    }
                    .background(.black)
                    .ignoresSafeArea(edges: .top)
                    
                    // Show time card
                    VStack(spacing: 4) {
                        Text("SHOWTIME")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                        
                        VStack(spacing: 4) {
                            Text(performances.performances[0].showTime, style: .date)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(performances.performances[0].showTime, style: .time)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .background(.ultraThinMaterial.opacity(0.3))
                            .cornerRadius(20)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    // Teams and performers
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(performances.performances, id: \.id) { performance in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Team header
                                    HStack {
                                        Text(performance.teamName)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        FavoriteTeamButton(teamName: performance.teamName)
                                    }
                                    .padding(16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.15),
                                                Color.pink.opacity(0.1)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                    
                                    // Performers
                                    VStack(spacing: 0) {
                                        ForEach(Array(performance.performers.enumerated()), id: \.element) { index, performer in
                                            NavigationLink(value: performer) {
                                                HStack(spacing: 14) {
                                                    PerformerRowContent(
                                                        performer: performer,
                                                        performerURL: performerURLs[performer]
                                                    )
                                                    .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundColor(.white.opacity(0.3))
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color.white.opacity(0.02))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            if index < performance.performers.count - 1 {
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.05))
                                                    .frame(height: 1)
                                                    .padding(.leading, 80)
                                            }
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                        .background(.ultraThinMaterial.opacity(0.3))
                                        .cornerRadius(20)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationDestination(for: String.self) { performer in
                PerformerDetailView(performer: performer)
            }
        }
        
        .task {
            await loadPerformerURLs()
        }
    }
    
    private func loadPerformerURLs() async {
        for performance in performances.performances {
            let performers = performance.performers
            for performer in performers {
                if performerURLs[performer] == nil {
                    print("getting performer image url")
                    if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
                        performerURLs[performer] = url
                    }
                }
            }
        }
    }
}
