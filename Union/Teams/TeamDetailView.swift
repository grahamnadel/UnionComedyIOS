//
//  TeamDetailView.swift
//  Union
//
//  Created by Graham Nadel on 8/14/25.
//

import Foundation
import SwiftUI


// Detail view showing all performances for a given team
struct TeamDetailView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let teamName: String
    
    var performancesForTeam: [Performance] {
        festivalViewModel.performances
            .filter { $0.teamName == teamName }
            .sorted { $0.showTime < $1.showTime }
    }
    
    var body: some View {
        VStack {
            List {
                if authViewModel.role == .owner {
                    ForEach(performancesForTeam, id: \.id) { performance in
                        PerformanceRow(performance: performance)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let perf = performancesForTeam[index]
                            festivalViewModel.deletePerformance(perf)
                        }
                    }
                } else {
                    ForEach(performancesForTeam, id: \.id) { performance in
                        PerformanceRow(performance: performance)
                    }
                }
            }
            Button {
                festivalViewModel.toggleFavoriteTeam(teamName)
            } label: {
                Image(systemName: festivalViewModel.favoriteTeams.contains(teamName) ? "star.fill" : "star")
                    .foregroundColor(festivalViewModel.favoriteTeamColor)
            }
        }
        .navigationTitle(teamName)
        .toolbar {
            if authViewModel.role == .owner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditTeamPerformersView(teamName: teamName)) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
    }
}
