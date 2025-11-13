import SwiftUI

struct ShowtimeDetailView: View {
    let performance: Performance
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @State var performerURLs: [String:URL] = [:]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(height: 80) // or any thickness you like
                        .frame(maxWidth: .infinity, alignment: .top)
                        .ignoresSafeArea()
                    Text("PLAYBILL")
                        .font(.title)
                }
                // Team name + favorite toggle
                ZStack {
                    Text(performance.teamName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            if let index = favoritesViewModel.favoriteTeams.firstIndex(of: performance.teamName) {
                                favoritesViewModel.favoriteTeams.remove(at: index)
                            } else {
                                favoritesViewModel.favoriteTeams.append(performance.teamName)
                            }
                        }) {
                            Image(systemName: favoritesViewModel.favoriteTeams.contains(performance.teamName) ? "star.fill" : "star")
                                .foregroundColor(favoritesViewModel.favoriteTeamColor)
                                .imageScale(.large)
                        }
                    }
                }
                
                // Show date
                Text("\(performance.showTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                
                Divider()
                
                
                List {
                    Section(header:
                                Text("THE CAST")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    ) {
                        ForEach(performance.performers, id: \.self) { performer in
                            //                    NavigationLink(destination: PerformerDetailView(performer: performer)) {
                            NavigationLink {
                                // Apply the .id(performer) to the DESTINATION view
                                // This is often the most effective stabilization point.
                                PerformerDetailView(performer: performer)
                                    .id(performer)
                            } label: {
                                // Use the decoupled view as the label
                                PerformerRowContent(performer: performer, performerURL: performerURLs[performer])
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
        }
        .task {
            await loadPerformerURLs()
        }
    }
    
    private func loadPerformerURLs() async {
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

