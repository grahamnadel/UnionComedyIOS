import SwiftUI

//// Detail view showing all performances for a given performer
struct PerformanceDetailView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    let performance: Performance
    
    var body: some View {
        VStack {
            ForEach(performance.performers, id: \.self) { performer in
                PerformerDetailView(performer: performer)
            }
            .navigationTitle("Performance")
        }
    }
}
