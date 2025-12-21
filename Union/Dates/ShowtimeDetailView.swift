import SwiftUI

struct ShowtimeDetailView: View {
    let performances: Performances
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var performerURLs: [String:URL] = [:]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Image("Logo-Union-Letterd")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .mask(
                        GeometryReader { geo in
                            Rectangle()
                                .frame(height: geo.size.height * 2 / 3)
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                    )

                ForEach(performances.performances, id: \.id) { performance in
                    
                    // Team name + favorite toggle
                    ZStack {
                        Text(performance.teamName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Spacer()
                            FavoriteTeamButton(teamName: performance.teamName)
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
        }
        .task {
            await loadPerformerURLs()
        }
    }
    
    private func loadPerformerURLs() async {
//        for performance in performances {
//            let performers = performance.performers
//            for performer in performers {
//                if performerURLs[performer] == nil {
//                    print("getting performer image url")
//                    if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
//                        performerURLs[performer] = url
//                    }
//                }
//            }
//        }
    }
}

