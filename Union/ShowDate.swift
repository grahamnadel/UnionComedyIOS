//
//  ShowDate.swift
//  Union
//
//  Created by Graham Nadel on 10/20/25.
//

import Foundation
import SwiftUI

struct ShowDate: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    let performance: Performance
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading) {
                Text(performance.teamName)
                    .font(.headline)
//                Text(performance.showTime, style: .time)
//                    .font(.subheadline)
                Text("Performers: \(performance.performers.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Favorite indicators
            VStack(spacing: 4) {
                if festivalViewModel.favoriteTeams.contains(performance.teamName) {
                    Image(systemName: "star.fill")
                        .foregroundColor(festivalViewModel.favoriteTeamColor)
                }
                if performance.performers.contains(where: { festivalViewModel.favoritePerformers.contains($0) }) {
                    Image(systemName: "star.fill")
                        .foregroundColor(festivalViewModel.favoritePerformerColor)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
