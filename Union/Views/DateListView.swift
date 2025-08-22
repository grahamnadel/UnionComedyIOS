import SwiftUI

struct DateListView: View {
    @ObservedObject var festivalViewModel: FestivalViewModel
    
    // Group performances by date (ignoring time)
    private var groupedPerformances: [(key: Date, value: [Performance])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: festivalViewModel.performances) { performance in
            calendar.startOfDay(for: performance.showTime)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        List {
            ForEach(groupedPerformances, id: \.key) { date, performances in
                Section(header: Text(date, style: .date)) {
                    ForEach(performances, id: \.id) { performance in
                        VStack(alignment: .leading) {
                            Text(performance.teamName)
                                .font(.headline)
                            Text(performance.showTime, style: .time)
                                .font(.subheadline)
                            Text("Performers: \(performance.performers.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            festivalViewModel.deletePerformance(performances[index])
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sort By")
    }
}
