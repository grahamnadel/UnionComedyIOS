import SwiftUI

struct DateListView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var editingPerformance: Performance?
    @State private var newShowTime = Date()
    @State private var searchText = ""
    @State private var selectedPerformances: Performances?
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
            VStack {
                HStack {
                    SearchBar(searchCategory: "team or performer", searchText: $searchText)
                    
                    Button {
                        showFilterMenu.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .imageScale(.large)
                            .padding(8)
                            .foregroundColor(.yellow)
                    }
                    .accessibilityLabel("Filter by show type")
                }
                .padding(.horizontal)
            }
            .background(.purple)
            // 📅 ScrollView with grouped shows
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedPerformancesByTime, id: \.key) { showTime, performances in
                        VStack(alignment: .leading, spacing: 12) {
                            // Show type and time
                            if let festivalStart = scheduleViewModel.festivalStartDate,
                               let festivalEndDate = scheduleViewModel.festivalEndDate,
                               let festivalLocation = scheduleViewModel.festivalLocation {
                                
                                if showTime < festivalStart || showTime > festivalEndDate {
//                                    if let showType = ShowType.dateToShow(date: showTime) {
                                        PerformancesLogisticsView(showTime: showTime)
                                        HStack(spacing: 16) {
                                            Spacer()
                                            ForEach(performances, id: \.id) { performance in
                                                ShowDate(performance: performance)
                                                    .frame(width: 150)
                                                    .contextMenu {
                                                            if authViewModel.role == .owner {
                                                                Button("Edit Performance") {
                                                                    editingPerformance = performance
                                                                }
                                                                
                                                                Button(role: .destructive) {
                                                                    performanceToDelete = performance
                                                                    showDeleteAlert = true
                                                                } label: {
                                                                    Label("Delete Performance", systemImage: "trash")
                                                                }
                                                            }
                                                        }
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        Divider()
                                            .padding(.horizontal)
//                                    }
                                } else {
                                    HStack {
                                        Text("Festival Show: at \(festivalLocation)")
                                            .bold()
                                            .foregroundColor(.purple)
                                        Spacer()
                                        Text(showTime.formatted(.dateTime.hour().minute()))
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPerformances = Performances(performances: performances)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.vertical)
            }
            
            .refreshable {
                scheduleViewModel.loadData()
                scheduleViewModel.loadTeams()
                scheduleViewModel.loadPerformers()
            }
        }
        .onChange(of: editingPerformance) {
            newShowTime = editingPerformance?.showTime ?? Date()
        }
        .sheet(isPresented: $showFilterMenu) {
            NavigationView {
                List {
                    Button("All Shows") {
                        showType = nil
                        showFilterMenu = false
                    }
                    ForEach(ShowType.allCases) { type in
                        if type != .classShow {
                            Button(type.displayName) {
                                showType = type
                                showFilterMenu = false
                            }
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
        
        // Edit + Detail + Delete alert
        .sheet(item: $editingPerformance) { performance in
            EditShowDateView(performance: performance, newShowTime: newShowTime)
        }
        .sheet(item: $selectedPerformances) { performance in
            ShowtimeDetailView(performances: performance)
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
