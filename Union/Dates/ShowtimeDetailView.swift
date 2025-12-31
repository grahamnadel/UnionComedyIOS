import SwiftUI

struct ShowtimeDetailView: View {
    let performances: Performances
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var performerURLs: [String:URL] = [:]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack {
                    Image("UnionLogoCrop")
                        .resizable()
                        .scaledToFit()
                }
                .background(.black)
                List {
                    Section {
                        VStack(spacing: 4) {
                            Text("SHOWTIME")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Divider()
                            
                            Text(
                                performances.performances[0].showTime.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    ForEach(performances.performances, id: \.id) { performance in
                        Section(
                            header: VStack(spacing: 8) {
                                HStack {
                                    Text(performance.teamName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    FavoriteTeamButton(teamName: performance.teamName)
                                }
                            }
                        ) {
//                            FIXME: not showing performers
                            ForEach(performance.performers, id: \.self) { performer in
                                NavigationLink(value: performer) {
                                    PerformerRowContent(
                                        performer: performer,
                                        performerURL: performerURLs[performer]
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
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

