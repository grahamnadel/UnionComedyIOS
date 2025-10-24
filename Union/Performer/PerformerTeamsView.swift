import SwiftUI

struct PerformerTeamsView: View {
    let teamsForPerformer: [String]
    let performancesForPerformer: [Performance]
    let name: String
    var body: some View {
        List {
            Section("Teams") {
                ForEach(teamsForPerformer, id: \.self) { teamName in
                    VStack(alignment: .leading) {
                        Text(teamName)
                            .font(.headline)
//                        
//                        // Show all performances for this team with this performer
                        ForEach(performancesForPerformer.filter { $0.teamName == teamName }, id: \.id) { performance in
                            HStack {
//                FIXME: Performance
                                Text(performance.showTime, style: .date)
                                    .font(.caption)
                                Spacer()
//                FIXME: Performance
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
        .navigationTitle("\(name)'s Teams")
    }
}
