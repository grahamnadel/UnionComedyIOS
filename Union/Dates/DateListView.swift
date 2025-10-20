import SwiftUI

struct DateListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var editingPerformance: Performance?
    @State private var newShowTime = Date()
    @State private var searchText = ""   // Search field text
    @State private var selectedPerformance: Performance? = nil
    
    // Filtered and grouped performances
    private var groupedPerformances: [(key: Date, value: [Performance])] {
        let calendar = Calendar.current
        
        // Step 1: Filter by team or performer
        let filtered = festivalViewModel.performances.filter { performance in
            searchText.isEmpty ||
            performance.teamName.localizedCaseInsensitiveContains(searchText) ||
            performance.performers.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
        
        // Step 2: Group by date (ignore time)
        let grouped = Dictionary(grouping: filtered) { performance in
            calendar.startOfDay(for: performance.showTime)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack {
            // 🔍 Combined search for team or performer
            SearchBar(searchCategory: "team or performer", searchText: $searchText)
                .padding(.horizontal)
            
            List {
                ForEach(groupedPerformances, id: \.key) { date, performances in
                    Section(header: Text(date, style: .date)) {
                        ForEach(performances, id: \.id) { performance in
                            ShowDate(performance: performance)
                                .onTapGesture {
                                    selectedPerformance = performance
                                }
                                .onLongPressGesture {
                                    if festivalViewModel.isAdminLoggedIn {
                                        editingPerformance = performance
                                        newShowTime = performance.showTime
                                    }
                                }
                        }
                        .onDelete(perform: festivalViewModel.isAdminLoggedIn ? { indexSet in
                            for index in indexSet {
                                festivalViewModel.deletePerformance(performances[index])
                            }
                        } : nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Performances")
            .refreshable {
                festivalViewModel.loadData()
            }
        }
        .sheet(item: $editingPerformance) { performance in
            EditShowDateView(performance: performance, newShowTime: newShowTime)
        }
        .sheet(item: $selectedPerformance) { performance in
            ShowtimeDetailView(performance: performance)
        }
    }
}
