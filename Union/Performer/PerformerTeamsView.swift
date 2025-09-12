import SwiftUI

struct PerformerTeamsView: View {
    let teamsForPerformer: [String]
    let performancesForPerformer: [Performance]
    var body: some View {
        List {
            Section("Teams") {
                ForEach(teamsForPerformer, id: \.self) { teamName in
                    VStack(alignment: .leading) {
                        Text(teamName)
                            .font(.headline)
                        
                        // Show all performances for this team with this performer
                        ForEach(performancesForPerformer.filter { $0.teamName == teamName }, id: \.id) { performance in
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
                }
            }
        }
        .navigationTitle("Team Selection")
    }
}
