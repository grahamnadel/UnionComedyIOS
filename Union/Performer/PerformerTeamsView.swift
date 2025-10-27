import SwiftUI

// FIXME: Not showing Teams
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
            ForEach(performancesForPerformer, id: \.id) { performance in
                HStack {
                    Text("\(performance.teamName)")
//                    TODO: Make this format a view and make it consistent for all views
                    Spacer()
                    Text(performance.showTime, style: .date)
                        .font(.caption)
                    Spacer()
                    Text(performance.showTime, style: .time)
                        .font(.caption)
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
