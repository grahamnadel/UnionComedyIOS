import SwiftUI

struct ShowtimeDetailView: View {
    let performance: Performance
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State var performerURLs: [String:URL] = [:]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Team name + favorite toggle
                HStack {
                    Text("Team: \(performance.teamName)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        if let index = festivalViewModel.favoriteTeams.firstIndex(of: performance.teamName) {
                            festivalViewModel.favoriteTeams.remove(at: index)
                        } else {
                            festivalViewModel.favoriteTeams.append(performance.teamName)
                        }
                    }) {
                        Image(systemName: festivalViewModel.favoriteTeams.contains(performance.teamName) ? "star.fill" : "star")
                            .foregroundColor(festivalViewModel.favoriteTeamColor)
                            .imageScale(.large)
                    }
                }
                // Show date
                Text("Show Date: \(performance.showTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.headline)
                
                Divider()
                
                // Performers list
                Text("Performers")
                    .font(.headline)
                
                List(performance.performers, id: \.self) { performer in
                    NavigationLink(destination: PerformerDetailView(performer: performer)) {
                        HStack {
//                            TODO: This is reused. Make a separate file
                            AsyncImage(url: performerURLs[performer]) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                                .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Performance Details")
            .navigationBarTitleDisplayMode(.inline)
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
                if let url = await festivalViewModel.getPerformerImageURL(for: performer) {
                    performerURLs[performer] = url
                }
            }
        }
    }
}

