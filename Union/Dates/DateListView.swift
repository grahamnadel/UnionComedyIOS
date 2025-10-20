import SwiftUI

struct DateListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var editingPerformance: Performance?
    @State private var newShowTime = Date()
    @State private var searchText = ""   // Search field text

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
                            .onTapGesture {
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
            NavigationView {
                VStack(spacing: 20) {
                    Text("Edit Show Time")
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(alignment: .leading) {
                        Text("Team: \(performance.teamName)")
                            .font(.headline)
                        Text("Performers: \(performance.performers.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    DatePicker("Show Time", selection: $newShowTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)

                    Spacer()
                }
                .padding()
                .navigationTitle("Edit Performance")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            editingPerformance = nil
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            updatePerformanceTime(performance)
                            editingPerformance = nil
                        }
                    }
                }
            }
        }
    }

    private func updatePerformanceTime(_ performance: Performance) {
        if let index = festivalViewModel.performances.firstIndex(where: { $0.id == performance.id }) {
            festivalViewModel.performances[index].showTime = newShowTime
        }
    }
}
