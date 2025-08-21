import SwiftUI

//// Detail view showing all performances for a given performer
struct PerformerDetailView: View {
    let performer: String
    let performerURL: URL?
    @ObservedObject var festivalViewModel: FestivalViewModel
    
    var performancesForPerformer: [Performance] {
        festivalViewModel.performances.filter { $0.performers.contains(performer) }
            .sorted { $0.showTime < $1.showTime }
    }
    
    var body: some View {
        VStack {
            AsyncImage(url: performerURL) { image in
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
            .frame(width: 250, height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            List(performancesForPerformer, id: \.id) { performance in
                VStack(alignment: .leading) {
                    Text(performance.teamName)
                        .font(.headline)
                    Text(performance.showTime, style: .date)
                        .font(.subheadline)
                    Text(performance.showTime, style: .time)
                        .font(.subheadline)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle(performer)
        }
    }
}
