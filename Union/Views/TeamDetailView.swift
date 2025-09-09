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
    let team: String
    @ObservedObject var festivalViewModel: FestivalViewModel
    
    var performancesForTeam: [Performance] {
        festivalViewModel.performances
            .filter { $0.teamName == team }
            .sorted { $0.showTime < $1.showTime }
    }
    
    var body: some View {
        List {
            if festivalViewModel.isAdminLoggedIn {
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
        .navigationTitle(team)
        .toolbar {
            if festivalViewModel.isAdminLoggedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditTeamPerformersView(festivalViewModel: festivalViewModel, teamName: team)) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
    }
}
