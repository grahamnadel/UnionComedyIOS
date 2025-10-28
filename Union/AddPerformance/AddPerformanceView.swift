import SwiftUI
import PhotosUI

struct AddPerformanceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    
    @State private var date = Date()
    @State private var selectedDates: Set<Date> = Set()
    @State private var teamName = ""
    @State private var selectedTeamName: String? = nil
    @State private var newTeamNameInput = ""
    @State private var performerInput = ""
    @State private var performerInputs: Set<PerformerInput> = Set()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedPerformerForPhoto: UUID? = nil
    
    @State private var performanceTeamCount: Int? = nil
    
    @State private var selectedShowType: ShowType? = nil
    @State private var customDate = Date()
    var isShowTypeSelected: Bool {
        selectedShowType != nil && selectedShowType != .custom
    }
    
    // Computed property to get all unique team names from performances
    var allTeams: [String] {
        let teams = Set(festivalViewModel.performances.map { $0.teamName })
        return Array(teams).sorted()
    }
    
    // This computed property filters suggestions for the user as they type.
    var filteredSuggestions: [String] {
        let existingNames = Set(performerInputs.map(\.name))
        // Ensure performerInput is not empty to avoid showing all suggestions initially.
        guard !performerInput.isEmpty else { return [] }
        
        return festivalViewModel.knownPerformers
            .filter { name in
                name.lowercased().contains(performerInput.lowercased()) &&
                !existingNames.contains(name)
            }
            .sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Team Details
                TeamDetailSection(
                                    allTeams: allTeams,
                                    selectedTeamName: $selectedTeamName,
                                    teamName: $teamName // Bind the final teamName here
                                )
                DateSelectionSection(
                                    selectedShowType: $selectedShowType,
                                    customDate: $customDate,
                                    selectedDates: $selectedDates,
                                    date: $date
                                )
                // MARK: - Add Dates
                DateInput(selectedShowType: selectedShowType, customDate: $customDate)
                
                // MARK: - List of Selected Dates
                if !selectedDates.isEmpty {
                    Section(header: Text("Dates to Add")) {
                        let sortedDates = selectedDates.sorted()
                        ForEach(sortedDates, id: \.self) { selectedDate in
                            Text(selectedDate, style: .date) + Text(", ") + Text(selectedDate, style: .time)
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
                    Button("Save") { savePerformance() }
                        .disabled(teamName.isEmpty || performerInputs.isEmpty || selectedDates.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let item = selectedPhoto,
                       let data = try? await item.loadTransferable(type: Data.self) {
                        // Logic to associate the selected photo data with the correct performer
                        if let performerId = selectedPerformerForPhoto,
                           let index = performerInputs.firstIndex(where: { $0.id == performerId }) {
                            var performerToUpdate = performerInputs[index]
                            performerToUpdate.imageData = data
                            performerInputs.update(with: performerToUpdate)
                        }
                    }
                }
            }
            .onAppear {
                if let firstTeam = allTeams.first {
                    selectedTeamName = firstTeam
                    teamName = firstTeam
                }
            }
            .onChange(of: selectedTeamName) {
                // Clear existing performers
                performerInputs.removeAll()
                if let newTeam = selectedTeamName {
                    teamName = newTeam
                    
                    // Find all performers for this team
                    let existingPerformers = festivalViewModel.performances
                        .filter { $0.teamName == newTeam }
                        .flatMap { $0.performers }
                    
                    // Add unique performers to the selected list
                    for performerName in Set(existingPerformers) {
                        performerInputs.insert(PerformerInput(name: performerName))
                    }
                } else {
                    teamName = ""
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func addPerformerManually() {
        let trimmedName = performerInput.trimmingCharacters(in: .whitespaces)
        // The Set's Hashable conformance handles uniqueness (case-insensitively).
        if !trimmedName.isEmpty {
            performerInputs.insert(PerformerInput(name: trimmedName))
            performerInput = ""
        }
    }
    
    private func savePerformance() {
        // Create the performance object and add it via the view model.
        let teamToSave = teamName.isEmpty ? newTeamNameInput : teamName
        
        let selectedDatesArray = Array(selectedDates)
        festivalViewModel.createPerformance(id: UUID().uuidString, teamName: teamToSave, performerIds: performerInputs.map { $0.name }, dates: selectedDatesArray)
        
        // Save any images that were associated with performers.
        for performer in performerInputs {
            if let imageData = performer.imageData {
                Task { @MainActor in
                    await festivalViewModel.savePerformerImage(for: performer.name, imageData: imageData)
                }
            }
        }
        
        dismiss()
    }
}
