import SwiftUI

struct PerformanceRow: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    let performance: Performance
    @State private var performerURLs: [String: URL] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(performance.teamName)
                .font(.headline)
            Text(performance.showTime, style: .date)
                .font(.subheadline)
            Text(performance.showTime, style: .time)
                .font(.subheadline)
        }
        
        ForEach(performance.performers, id: \.self) { performer in
            NavigationLink(destination: PerformerDetailView(performer: performer)) {
                HStack {
                    AsyncImage(url: performerURLs[performer]) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
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
                }
                .padding(.vertical, 4)
            }
        }
        .task {
            await loadPerformerURLs()
        }
    }
    
    private func loadPerformerURLs() async {
        for performer in performance.performers {
            if performerURLs[performer] == nil {
                if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
                    performerURLs[performer] = url
                }
            }
        }
    }
}
