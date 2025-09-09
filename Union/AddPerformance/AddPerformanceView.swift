import SwiftUI
import PhotosUI

struct AddPerformanceView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var festivalViewModel: FestivalViewModel

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
                Section(header: Text("Team Details")) {
                    Picker("Team Name", selection: $selectedTeamName) {
                        // Option to create a new team
                        Text("New Team...").tag(nil as String?)
                        
                        ForEach(allTeams, id: \.self) { team in
                            Text(team).tag(team as String?)
                        }
                    }
                    
                    // Show a text field only if "New Team..." is selected
                    if selectedTeamName == nil {
                        TextField("New Team Name", text: $newTeamNameInput)
                            .onChange(of: newTeamNameInput) { _ in
                                teamName = newTeamNameInput
                            }
                    }
                }

                // MARK: - Add Dates
                Section(header: Text("Add Dates")) {
                    DatePicker("Show Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Button("Add Date") {
                        selectedDates.insert(date)
                    }
                    .disabled(selectedDates.contains(date))
                }
                
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
                    
                    PerformerSelectionList(
                        festivalViewModel: festivalViewModel,
                        performerInputs: $performerInputs
                    )
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
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let item = newItem,
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
            .onChange(of: selectedTeamName) { newTeam in
                // Clear existing performers
                performerInputs.removeAll()
                if let newTeam = newTeam {
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
        
        for date in selectedDates {
            let newPerformance = Performance(
                teamName: teamToSave,
                showTime: date,
                performers: performerInputs.map { $0.name }
            )
            festivalViewModel.addPerformance(newPerformance)
        }

        // Save any images that were associated with performers.
        for performer in performerInputs {
            if let imageData = performer.imageData {
                festivalViewModel.saveImage(for: performer.name, imageData: imageData)
            }
        }
        
        dismiss()
    }
}
