import SwiftUI

struct DateListView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var editingPerformance: Performance?
    @State private var newShowTime = Date()
    @State private var searchText = ""
    @State private var selectedPerformance: Performance?
    @State private var showType: ShowType?
    @State private var showDeleteAlert = false
    @State private var performanceToDelete: Performance?
    @State private var showFilterMenu = false
    @State private var showingFestivalImage = false
    
    // MARK: - Filter + Group
    private var groupedPerformancesByTime: [(key: Date, value: [Performance])] {
        let filtered = scheduleViewModel.performances.filter { performance in
            let matchesSearch =
            searchText.isEmpty ||
            performance.teamName.localizedCaseInsensitiveContains(searchText) ||
            performance.performers.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            
            let matchesShowType: Bool
            if let selectedType = showType {
                matchesShowType = ShowType.dateToShow(date: performance.showTime)?.displayName == selectedType.displayName
            } else {
                matchesShowType = true
            }
            
            return matchesSearch && matchesShowType
        }
        
        let grouped = Dictionary(grouping: filtered) { $0.showTime }
        return grouped.sorted { $0.key < $1.key }
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            UpcomingShowPushTestView()
//            PushTestView()
            // 🔍 Search bar + hamburger filter button
            HStack {
                SearchBar(searchCategory: "team or performer", searchText: $searchText)
                
                Button {
                    showFilterMenu.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .imageScale(.large)
                        .padding(8)
                        .foregroundColor(.purple)
                }
                .accessibilityLabel("Filter by show type")
            }
            .padding(.horizontal)

            
            // 📅 List of grouped shows
            List {
                if let festivalStart = scheduleViewModel.festivalStartDate,
                   let festivalEndDate = scheduleViewModel.festivalEndDate {
//                    TODO: fix so that this only appears during the festival
//                    if Date() >= festivalStart && Date() <= festivalEndDate {
//                        Image("Image")
//                            .resizable()
//                            .scaledToFit()
//                    }
                }
                ForEach(groupedPerformancesByTime, id: \.key) { showTime, performances in
                    Section(header: Text(showTime, style: .date)) {
                        
                        // ✅ Keep festival / non-festival label logic
                        if let festivalStart = scheduleViewModel.festivalStartDate,
                           let festivalEndDate = scheduleViewModel.festivalEndDate,
                           let festivalLocation = scheduleViewModel.festivalLocation {
                            
                            if showTime < festivalStart || showTime > festivalEndDate {
                                if let showType = ShowType.dateToShow(date: showTime)?.displayName {
                                    HStack {
                                        Text(showType)
                                            .bold()
                                        Spacer()
                                        Text(showTime.formatted(.dateTime.hour().minute()))
                                    }
                                }
                            } else {
                                HStack {
                                    Text("Festival Show: at \(festivalLocation)")
                                        .bold()
                                        .foregroundColor(.purple)
                                    Spacer()
                                    Text(showTime.formatted(.dateTime.hour().minute()))
                                }
                            }
                        }
                        
                        // 🎭 Each performance
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
                            if let index = indexSet.first {
                                performanceToDelete = performances[index]
                                showDeleteAlert = true
                            }
                        } : nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                scheduleViewModel.loadData()
                scheduleViewModel.loadTeams()
                scheduleViewModel.loadPerformers()
            }
        }
        
        // 📱 Filter sheet (opened by hamburger)
        .sheet(isPresented: $showFilterMenu) {
            NavigationView {
                List {
                    Button("All Shows") {
                        showType = nil
                        showFilterMenu = false
                    }
                    ForEach(ShowType.allCases) { type in
                        Button(type.displayName) {
                            showType = type
                            showFilterMenu = false
                        }
                    }
                }
                .navigationTitle("Filter Shows")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showFilterMenu = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        
        // 🧾 Edit + Detail + Delete alert
        .sheet(item: $editingPerformance) { performance in
            EditShowDateView(performance: performance, newShowTime: newShowTime)
        }
        .sheet(item: $selectedPerformance) { performance in
            ShowtimeDetailView(performance: performance)
        }
        .alert(isPresented: $showDeleteAlert) {
            SimpleAlert.confirmDeletion(
                title: "Delete Performance?",
                message: "This will delete the selected performance permanently.",
                confirmAction: {
                    if let performance = performanceToDelete {
                        scheduleViewModel.deletePerformance(performance)
                    }
                }
            )
        }
    }
}
