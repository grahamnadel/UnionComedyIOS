import SwiftUI

struct EditTeamPerformersView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    
    let teamName: String
    @State private var showCreatePerformer = false
    @State private var tempSelections: [String: Bool] = [:]
    @State private var draftHouseTeam = false
    @State private var teamPerformers: Set<String> = []
    
    var body: some View {
        List {
            Section("Performers") {
                ForEach(scheduleViewModel.knownPerformers.sorted(), id: \.self) { performer in
                    HStack {
                        Text(performer)
                        Spacer()
                        
//                        Toggle("", isOn: Binding(
//                            get: { tempSelections[performer] ?? isPerformerInTeam(performer) },
//                            set: { tempSelections[performer] = $0 }
//                        ))
                        Toggle("", isOn: Binding(
                            get: { teamPerformers.contains(performer) },
                            set: { isOn in
                                if isOn {
                                    teamPerformers.insert(performer)
                                } else {
                                    teamPerformers.remove(performer)
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(.purple)
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
        .onAppear {
            teamPerformers = Set(scheduleViewModel.teams
                .filter { $0.name == teamName }
                .flatMap { $0.performers })
            print("Team Performers: \(teamPerformers)")
        }
        .navigationTitle("Edit \(teamName)")
        .listStyle(.insetGrouped)
        .refreshable {
            scheduleViewModel.loadData()
            scheduleViewModel.loadTeams()
            scheduleViewModel.loadPerformers()
        }
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
        for performer in teamPerformers {
            Task {
//                Add new performers
                if !isPerformerInTeam(performer) {
                    scheduleViewModel.addPerformer(named: performer, toTeam: teamName)
                }
            }
//          Remove performers
            if let team = scheduleViewModel.teams.first(where: { $0.name == teamName }) {
                //  Loop through performers currently on the team
                for performer in team.performers {
                    Task {
                        // If this performer is NOT in teamPerformers, remove them
                        if !teamPerformers.contains(performer) {
                            scheduleViewModel.removePerformerFromTeamsCollection(performerName: performer, team: teamName)
                            scheduleViewModel.removePerformerFromFestivalTeamsCollection(performerName: performer)
                        }
                    }
                }
            }
            
            scheduleViewModel.loadData()
            scheduleViewModel.loadTeams()
            scheduleViewModel.loadPerformers()
        }
        
//        for (performer, isOn) in tempSelections {
//            Task {
//                if isOn && !isPerformerInTeam(performer) {
//                    scheduleViewModel.addPerformer(named: performer, toTeam: teamName)
//                } else if !isOn && isPerformerInTeam(performer) {
//                    scheduleViewModel.removePerformerFromTeamsCollection(performerName: performer)
//                    scheduleViewModel.removePerformerFromFestivalTeamsCollection(performerName: performer)
//                }
//                scheduleViewModel.loadData()
//                scheduleViewModel.loadTeams()
//                scheduleViewModel.loadPerformers()
//                tempSelections.removeAll()
//            }
//        }
    }
}
