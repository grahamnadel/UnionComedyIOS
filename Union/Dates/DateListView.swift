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
        VStack(spacing: 0) {
            VStack {
                HStack {
                    SearchBar(
                        searchCategory: "team or performer",
                        searchText: $searchText,
                        onFilterTap: {
                            showFilterMenu.toggle()
                        }
                    )
                }
                .padding(.top)
                .padding(.horizontal)
            }
//            .background(.purple)
            
            // 📅 ScrollView with grouped shows
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedPerformancesByTime, id: \.key) { showTime, performances in
                        DateListItemView(
                            editingPerformance: $editingPerformance,
                            showDeleteAlert: $showDeleteAlert,
                            performanceToDelete: $performanceToDelete,
                            showTime: showTime,
                            performances: performances
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPerformances = Performances(performances: performances)
                        }
                        .padding(.horizontal)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                        .padding(.vertical, 4)
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
