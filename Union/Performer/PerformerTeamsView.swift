import SwiftUI

struct PerformerTeamsView: View {
    let teamsForPerformer: [String]
    let performancesForPerformer: [Performance]
    let name: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Team Name")
                Spacer()
                Text("Date")
                    .font(.caption)
                Spacer()
                Text("Time")
                    .font(.caption)
            }
            .padding()
            
            ForEach(teamsForPerformer, id: \.self) { team in
                // Find performances for this team
                let teamPerformances = performancesForPerformer.filter { $0.teamName == team }
                
                if teamPerformances.isEmpty {
                    // Team has no performances
                    HStack {
                        Text(team)
                        Spacer()
                        Text("-")
                            .font(.caption)
                        Spacer()
                        Text("-")
                            .font(.caption)
                    }
                } else {
                    // Team has performances: show each
                    ForEach(teamPerformances, id: \.id) { performance in
                        HStack {
                            Text(performance.teamName)
                            Spacer()
                            Text(performance.showTime, style: .date)
                                .font(.caption)
                            Spacer()
                            Text(performance.showTime, style: .time)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .onAppear {
            print("PerformerTeamsView performances: \(performancesForPerformer)")
        }
        .navigationTitle("\(name)'s Teams")
    }
}
