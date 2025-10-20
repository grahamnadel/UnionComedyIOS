import SwiftUI

//// Detail view showing all performances for a given performer
struct PerformanceDetailView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    let performance: Performance
    
    var body: some View {
        VStack {
            ForEach(performance.performers, id: \.self) { performer in
                PerformerDetailView(performer: performer, performerURL: nil)
            }
            .navigationTitle("Performance")
        }
    }
}
//TODO: Add back in when doing images/pictures
//                let performerURL = festivalViewModel.getImageURL(for: performer)
//                AsyncImage(url: performerURL) { image in
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                } placeholder: {
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(Color.gray.opacity(0.3))
//                        .overlay(
//                            Image(systemName: "person.fill")
//                                .foregroundColor(.gray)
//                        )
//                }
//                .frame(width: 250, height: 250)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
