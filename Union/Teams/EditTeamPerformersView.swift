import SwiftUI

struct EditTeamPerformersView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    
    let teamName: String
    @State private var showCreatePerformer = false
    
    var body: some View {
        List {
            Section("Performers") {
                ForEach(scheduleViewModel.knownPerformers.sorted(), id: \.self) { performer in
                    HStack {
                        Text(performer)
                        Spacer()
                        
                        // Toggle for adding/removing a performer from this team
                        Toggle("", isOn: binding(for: performer))
                            .labelsHidden()
                            .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Edit \(teamName)")
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCreatePerformer = true
                }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showCreatePerformer) {
            CreatePerformerView(teamName: teamName)
        }
    }
    
    /// Creates a binding for the toggle to add/remove a performer from the team.
    private func binding(for performer: String) -> Binding<Bool> {
        return Binding<Bool>(
            get: {
                // Check if the performer is in any performance for this team
                scheduleViewModel.performances
                    .filter { $0.teamName == teamName }
                    .contains { $0.performers.contains(performer) }
            },
            set: { isOn in
                if isOn {
                    // Add the performer to the team
                    scheduleViewModel.addPerformer(named: performer, toTeam: teamName)
                } else {
                    // Remove the performer from the team
//                    scheduleViewModel.deletePerformer(named: performer, fromTeam: teamName)
                    scheduleViewModel.removePerformerFromTeamsCollection(performerName: performer)
                    scheduleViewModel.removePerformerFromFestivalTeamsCollection(performerName: performer)
                    
                    // Refresh UI
                    scheduleViewModel.loadData()
                }
            }
        )
    }
}
