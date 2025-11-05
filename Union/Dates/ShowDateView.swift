//
//  ShowDate.swift
//  Union
//
//  Created by Graham Nadel on 10/20/25.
//

import Foundation
import SwiftUI

struct ShowDate: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    let performance: Performance
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading) {
                if performance.isFestivalShow {
                    HStack {
                        Image(systemName: "sun.max")
                            .foregroundColor(.yellow)
                        Text("Festival Show at The Rockwell")
                    }
                }
                Text(performance.teamName)
                    .font(.headline)
                    .foregroundColor(performance.isFestivalShow ? .purple : .primary)
                Text("Performers: \(performance.performers.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Favorite indicators
            VStack(spacing: 4) {
                if scheduleViewModel.favoriteTeams.contains(performance.teamName) {
                    Image(systemName: "star.fill")
                        .foregroundColor(scheduleViewModel.favoriteTeamColor)
                }
                if performance.performers.contains(where: { scheduleViewModel.favoritePerformers.contains($0) }) {
                    Image(systemName: "star.fill")
                        .foregroundColor(scheduleViewModel.favoritePerformerColor)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
