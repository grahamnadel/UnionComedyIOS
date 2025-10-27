import SwiftUI

struct ShowtimeDetailView: View {
    let performance: Performance
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    
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
//                    TODO: Add url once I have the images for performers
                    NavigationLink(destination: PerformerDetailView(performer: performer)) {
                        Text(performer)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Performance Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

