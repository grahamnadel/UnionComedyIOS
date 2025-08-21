import SwiftUI
import PhotosUI

struct AddPerformanceView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var festivalViewModel: FestivalViewModel

    @State private var date = Date()
    @State private var teamName = ""
    @State private var performerInput = ""
    @State private var performerInputs: Set<PerformerInput> = Set()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedPerformerForPhoto: UUID? = nil

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
                // MARK: - Performance Details
                Section(header: Text("Performance Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Team Name", text: $teamName)
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
                        .disabled(teamName.isEmpty || performerInputs.isEmpty)
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
        let newPerformance = Performance(
            teamName: teamName,
            showTime: date,
            performers: performerInputs.map { $0.name }
        )
        festivalViewModel.addPerformance(newPerformance)

        // Save any images that were associated with performers.
        for performer in performerInputs {
            if let imageData = performer.imageData {
                festivalViewModel.saveImage(for: performer.name, imageData: imageData)
            }
        }
        
        dismiss()
    }
}
