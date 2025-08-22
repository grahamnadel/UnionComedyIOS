import SwiftUI

struct TeamsListView: View {
    @ObservedObject var festivalViewModel: FestivalViewModel
    let performerName: String
    
    // Get all unique teams in the festival
    var allTeams: [String] {
        let teams = Set(festivalViewModel.performances.map { $0.teamName })
        return Array(teams).sorted()
    }
    
    var body: some View {
        List {
            ForEach(allTeams, id: \.self) { teamName in
                HStack {
                    VStack(alignment: .leading) {
                        Text(teamName)
                            .font(.headline)
                        
                        // Show all performances for this team
                        let teamPerformances = festivalViewModel.performances
                            .filter { $0.teamName == teamName }
                            .sorted { $0.showTime < $1.showTime }
                        
                        ForEach(teamPerformances, id: \.id) { performance in
                            HStack {
                                Text(performance.showTime, style: .date)
                                    .font(.caption)
                                Spacer()
                                Text(performance.showTime, style: .time)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    Spacer()
                    
                    Toggle("", isOn: binding(for: teamName))
                        .labelsHidden()
                }
            }
        }
        .navigationTitle("All Teams")
        .listStyle(.insetGrouped)
    }
    
    private func binding(for teamName: String) -> Binding<Bool> {
        return Binding<Bool>(
            get: {
                // Check if performer is in any performance of this team
                festivalViewModel.performances
                    .filter { $0.teamName == teamName }
                    .contains { $0.performers.contains(performerName) }
            },
            set: { isOn in
                if isOn {
                    // Add performer to all performances of this team
                    for i in 0..<festivalViewModel.performances.count {
                        if festivalViewModel.performances[i].teamName == teamName &&
                           !festivalViewModel.performances[i].performers.contains(performerName) {
                            festivalViewModel.performances[i].performers.append(performerName)
                        }
                    }
                    festivalViewModel.knownPerformers.insert(performerName)
                } else {
                    // Remove performer from all performances of this team
                    for i in 0..<festivalViewModel.performances.count {
                        if festivalViewModel.performances[i].teamName == teamName {
                            festivalViewModel.performances[i].performers.removeAll { $0 == performerName }
                        }
                    }
                }
            }
        )
    }
}
