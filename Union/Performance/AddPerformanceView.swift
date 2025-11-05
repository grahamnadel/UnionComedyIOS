import SwiftUI
import PhotosUI

struct AddPerformanceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    
    @State private var date = Date.nextFriday730PM
    @State var selectedDates: Set<Date> = Set()
    @State private var teamName = ""
    @State private var selectedTeamName: String? = nil
    @State private var newTeamNameInput = ""
    @State private var performerInput = ""
    @State private var performerInputs: Set<PerformerInput> = Set()
    
    @State private var showOverbookAlert = false
    @State private var overbookedDates: [Date] = []
    @State private var proceedAnyway = false
    
    @State private var redundantPerformances: [Performance] = []
    
    @State private var selectedShowType: ShowType? = nil
    @State private var today: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.startOfDay(for: now) // strips time, locks to local midnight
    }()
    
    
    init(date: Date?, showType: ShowType?) {
        if let date = date {
            _selectedDates = State(initialValue: Set([date]))
        } else {
            _selectedDates = State(initialValue: Set())
        }
        
        if let showType = showType {
            _selectedShowType = State(initialValue: showType)
        } else {
            _selectedShowType = State(initialValue: nil)
        }
    }

    
    var isShowTypeSelected: Bool {
        selectedShowType != nil && selectedShowType != .special
    }
    
    // Computed property to get all unique team names from performances
//    TODO: change this to getting the list of teams
    var allTeams: [String] {
        let teams = Set(scheduleViewModel.teams.map { $0.name })
        return Array(teams).sorted()
    }
    
    // This computed property filters suggestions for the user as they type.
    var filteredSuggestions: [String] {
        let existingNames = Set(performerInputs.map(\.name))
        // Ensure performerInput is not empty to avoid showing all suggestions initially.
        guard !performerInput.isEmpty else { return [] }
        
        return scheduleViewModel.knownPerformers
            .filter { name in
                name.lowercased().contains(performerInput.lowercased()) &&
                !existingNames.contains(name)
            }
            .sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
// MARK: - Add Dates
                DateSelectionSection(
                    selectedShowType: $selectedShowType,
                    newShowDate: $today,
                    selectedDates: $selectedDates,
                    date: $date
                )
                
// MARK: - Team Details
                TeamDetailSection(
                    allTeams: allTeams,
                    selectedTeamName: $selectedTeamName,
                    teamName: $teamName
                )
                
                // MARK: - List of Selected Dates
                if !selectedDates.isEmpty {
                    Section(header: Text("Dates to Add")) {
                        let sortedDates = selectedDates.sorted()
                        ForEach(sortedDates, id: \.self) { selectedDate in
                            HStack {
                                Text(selectedDate, style: .date) + Text(", ") + Text(selectedDate, style: .time)
                                    .foregroundColor(
                                        // The coloring condition is now correct
                                        redundantPerformances.contains(where: { $0.showTime == selectedDate })
                                        ? .red
                                        : .green
                                    )
                                
                                // Display an indicator if the team is already booked for this time
                                if redundantPerformances.contains(where: { $0.showTime == selectedDate }) {
                                    Spacer()
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .help("Team already scheduled for this time.")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let sortedDates = selectedDates.sorted()
                            let datesToRemove = indexSet.map { sortedDates[$0] }
                            selectedDates.subtract(datesToRemove)
                        }
                    }
                }
                
                // MARK: - Add Performers
                Section(header: Text("Add Performers")) {
                    HStack {
                        TextField("Performer Name", text: $performerInput)
                        Button("Add") {
                            addPerformerManually()
                        }
                        .disabled(performerInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    PerformerSelectionList(performerInputs: $performerInputs)
                }
                
                // MARK: - Selected Performers List
                // This section only appears if at least one performer has been added.
                if !performerInputs.isEmpty {
                    Section(header: Text("Selected Performers")) {
                        // A sorted array is created from the Set to provide a stable
                        // order for the List, which is necessary for swipe-to-delete.
                        let sortedPerformers = performerInputs.sorted { $0.name < $1.name }
                        
                        SelectedPerformerList(
                            selected: sortedPerformers,
                            onRemove: { indexSet in
                                // The indexSet from the swipe action corresponds to the
                                // indices in our temporary 'sortedPerformers' array.
                                let performersToRemove = indexSet.map { sortedPerformers[$0] }
                                
                                // We then remove each of those performers from the original 'performerInputs' Set.
                                for performer in performersToRemove {
                                    performerInputs.remove(performer)
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("New Performance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePerformance()
                        scheduleViewModel.loadData()
                    }
                    .disabled(teamName.isEmpty || performerInputs.isEmpty || selectedDates.isEmpty || !redundantPerformances.isEmpty )
                }
            }
            .alert(isPresented: $showOverbookAlert) {
                Alert(
                    title: Text("Overbooking Warning"),
                    message: Text(
                        "The following shows would be overbooked:\n" +
                        overbookedDates.map {
                            if let showType = ShowType.dateToShow(date: $0) {
                                return "\(showType.displayName) at \($0.formatted(.dateTime.hour().minute()))"
                            } else {
                                return $0.formatted(.dateTime.hour().minute())
                            }
                        }.joined(separator: "\n")
                    ),
                    primaryButton: .destructive(Text("Cancel")) {
                        // Just dismiss the alert
                    },
                    secondaryButton: .default(Text("Proceed")) {
                        // User wants to proceed anyway
                        proceedAnyway = true
                        savePerformance()
                    }
                )
            }
            .onAppear {
                if let firstTeam = allTeams.first {
                    selectedTeamName = firstTeam
                    teamName = firstTeam
                }
                // Recalculate redundancy immediately if dates/team were passed in init
                if !selectedDates.isEmpty && !teamName.isEmpty {
                    redundantPerformances = blockRedundantTeamSave()
                }
            }
            .onChange(of: selectedTeamName) {
                // Clear existing performers
                performerInputs.removeAll()
                if let newTeam = selectedTeamName {
                    teamName = newTeam
                    
                    // Find all performers for this team
                    let existingPerformers = scheduleViewModel.performances
                        .filter { $0.teamName == newTeam }
                        .flatMap { $0.performers }
                    
                    // Add unique performers to the selected list
                    for performerName in Set(existingPerformers) {
                        performerInputs.insert(PerformerInput(name: performerName))
                    }
                } else {
                    teamName = ""
                }
                // Recalculate redundancy when team changes
                redundantPerformances = blockRedundantTeamSave()
            }
            .onChange(of: selectedDates) {
                redundantPerformances = blockRedundantTeamSave()
            }
            // Note: Removed redundant onChange(of: selectedTeamName) since the logic is in the other onChange
        }
    }
    
    // MARK: - Helper Functions
    
    // Function to check if the current team is already booked for any selected date
    private func blockRedundantTeamSave() -> [Performance] {
        print("called blockRedundantTeamSave")
        var redundantShows: [Performance] = []
        
        // Use the current teamName from state
        let currentTeam = teamName
        
        // Only proceed if a team name is actually set
        guard !currentTeam.isEmpty else { return [] }
        
        for date in selectedDates {
            let filteredShows = scheduleViewModel.performances.filter { $0.showTime == date }
            for show in filteredShows {
                // Check if any existing show at this time has the same team name
                if show.teamName == currentTeam {
                    print("blocked show: \(show)")
                    redundantShows.append(show)
                }
            }
        }
        return redundantShows
    }
    
    private func addPerformerManually() {
        let trimmedName = performerInput.trimmingCharacters(in: .whitespaces)
        // The Set's Hashable conformance handles uniqueness (case-insensitively).
        if !trimmedName.isEmpty {
            performerInputs.insert(PerformerInput(name: trimmedName))
            performerInput = ""
        }
    }
    
    private func savePerformance() {
        let teamToSave = teamName.isEmpty ? newTeamNameInput : teamName
        let selectedDatesArray = Array(selectedDates)
        
        // Check for overbooked dates
        var overbooked: [Date] = []
        for date in selectedDatesArray {
            if let showType = ShowType.dateToShow(date: date),
               let requiredTeams = showType.requiredTeamCount {
                
                let existingCount = scheduleViewModel.performances.filter { $0.showTime == date }.count
                if existingCount + 1 > requiredTeams {
                    overbooked.append(date)
                }
            }
        }
        
        if !overbooked.isEmpty && !proceedAnyway {
            // Trigger alert
            overbookedDates = overbooked
            showOverbookAlert = true
            return
        }
        
        // Save performance if no overbooking or user chooses to proceed
        print("DEBUG selectedDatesArray: \(selectedDatesArray)")
        scheduleViewModel.createPerformance(
            id: UUID().uuidString,
            teamName: teamToSave,
            performerIds: performerInputs.map { $0.name },
            dates: selectedDatesArray
        )
        
        dismiss()
    }

}

extension Date {
    static var nextFriday730PM: Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Find the date of the next Friday (weekday 6)
        let nextFriday = calendar.nextDate(
            after: now,
            matching: DateComponents(weekday: 6), // Friday is 6 in Gregorian
            matchingPolicy: .nextTime,
            direction: .forward
        ) ?? now
        
        // 2. Set the time to 7:30 PM (19:30:00)
        let targetDate = calendar.date(
            bySettingHour: 19, // 7 PM
            minute: 30,
            second: 0,
            of: nextFriday
        ) ?? nextFriday
        
        return targetDate
    }
}
