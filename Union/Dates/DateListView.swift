import SwiftUI

struct DateListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var editingPerformance: Performance?
    @State private var newShowTime = Date()
    @State private var searchText = ""   // Search field text
    @State private var selectedPerformance: Performance? = nil
    @State private var showType: ShowType? = nil
    
    // Filtered and grouped performances
    private var groupedPerformances: [(key: Date, value: [Performance])] {
        let calendar = Calendar.current

        // Step 1: Filter by search text and show type
        let filtered = festivalViewModel.performances.filter { performance in
            let matchesSearch =
                searchText.isEmpty ||
                performance.teamName.localizedCaseInsensitiveContains(searchText) ||
                performance.performers.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })

            let matchesShowType: Bool
            if let selectedType = showType {
                matchesShowType = ShowType.dateToShow(date: performance.showTime) == selectedType.displayName
            } else {
                matchesShowType = true
            }

            return matchesSearch && matchesShowType
        }

        // Step 2: Group by day
        let grouped = Dictionary(grouping: filtered) { performance in
            calendar.startOfDay(for: performance.showTime)
        }

        // Step 3: Sort by date
        return grouped.sorted { $0.key < $1.key }
    }
    
    private var groupedPerformancesByTime: [(key: Date, value: [Performance])] {
        let filtered = festivalViewModel.performances.filter { performance in
            let matchesSearch =
                searchText.isEmpty ||
                performance.teamName.localizedCaseInsensitiveContains(searchText) ||
                performance.performers.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })

            let matchesShowType: Bool
            if let selectedType = showType {
                matchesShowType = ShowType.dateToShow(date: performance.showTime) == selectedType.displayName
            } else {
                matchesShowType = true
            }

            return matchesSearch && matchesShowType
        }

        // Group by exact showTime
        let grouped = Dictionary(grouping: filtered) { performance in
            performance.showTime
        }

        return grouped.sorted { $0.key < $1.key }
    }


    
    var body: some View {
        VStack {
//            NavigationLink(
//                "Calendar",
//                destination: ColorCodedCalendar(
//                    selectedDate: .constant(Date()),         // fixed binding for demo
//                    month: Date(),                           // current month
//                    eventDates: [Date(), Date().addingTimeInterval(86400)] // today and tomorrow
//                )
//            )
            // 🔍 Combined search for team or performer
            SearchBar(searchCategory: "team or performer", searchText: $searchText)
                .padding(.horizontal)
            
            Picker("Show Type", selection: $showType) {
                Text("Select Show Type").tag(nil as ShowType?)
                ForEach(ShowType.allCases) { type in
                    Text(type.displayName)
                        .tag(type as ShowType?)
                }
            }
            
            List {
                ForEach(groupedPerformancesByTime, id: \.key) { showTime, performances in
                    Section(header: Text(showTime, style: .date)) {
                        if let showType = ShowType.dateToShow(date: showTime) {
                            HStack {
                                Text(showType).bold()
                                Spacer()
                                Text(showTime.formatted(.dateTime.hour().minute()))
                            }
                        }
                        ForEach(performances, id: \.id) { performance in
                            ShowDate(performance: performance)
                                .onTapGesture {
                                    selectedPerformance = performance
                                }
                                .onLongPressGesture {
                                    if authViewModel.role == .owner {
                                        editingPerformance = performance
                                        newShowTime = performance.showTime
                                    }
                                }
                        }
                        .onDelete(perform: authViewModel.role == .owner ? { indexSet in
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
