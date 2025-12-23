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
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    let performance: Performance
    var isHouseTeam: Bool {
            scheduleViewModel.teams.first(where: { $0.name == performance.teamName })?.houseTeam ?? false
        }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading) {
//                TODO: only make an image if there is one
                if isHouseTeam {
                    Image(performance.teamName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(performance.teamName)
                        .font(.caption)
                }
            }

            Spacer()

            // Favorite indicators
            VStack(spacing: 4) {
                if favoritesViewModel.favoriteTeams.contains(performance.teamName) {
                    Image(systemName: "star.fill")
                        .foregroundColor(favoritesViewModel.favoriteTeamColor)
                }
                if performance.performers.contains(where: { favoritesViewModel.favoritePerformers.contains($0) }) {
                    Image(systemName: "star.fill")
                        .foregroundColor(favoritesViewModel.favoritePerformerColor)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
