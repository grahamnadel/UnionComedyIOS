import SwiftUI

struct EditTeamPerformersView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    
    let teamName: String
    @State private var showCreatePerformer = false
    @State private var tempSelections: [String: Bool] = [:] // Local toggle state
    
    var body: some View {
        List {
            Section("Performers") {
                ForEach(scheduleViewModel.knownPerformers.sorted(), id: \.self) { performer in
                    HStack {
                        Text(performer)
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { tempSelections[performer] ?? isPerformerInTeam(performer) },
                            set: { tempSelections[performer] = $0 }
                        ))
                        .labelsHidden()
                        .tint(.blue)
                    }
                }
            }
            
            // Confirm button section
            Section {
                Button("Confirm Changes") {
                    applyChanges()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Edit \(teamName)")
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreatePerformer = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showCreatePerformer) {
            CreatePerformerView(teamName: teamName)
        }
    }
    
    /// Helper: Check if a performer is currently in the team
    private func isPerformerInTeam(_ performer: String) -> Bool {
        scheduleViewModel.performances
            .filter { $0.teamName == teamName }
            .contains { $0.performers.contains(performer) }
    }
    
    /// Apply all toggle changes to Firestore
    private func applyChanges() {
        for (performer, isOn) in tempSelections {
            if isOn && !isPerformerInTeam(performer) {
                scheduleViewModel.addPerformer(named: performer, toTeam: teamName)
            } else if !isOn && isPerformerInTeam(performer) {
                scheduleViewModel.removePerformerFromTeamsCollection(performerName: performer)
                scheduleViewModel.removePerformerFromFestivalTeamsCollection(performerName: performer)
            }
        }
        
        // Reload the data once after all updates
        scheduleViewModel.loadData()
        scheduleViewModel.loadTeams()
        scheduleViewModel.loadPerformers()
        
        // Clear temp selections
        tempSelections.removeAll()
    }
}
