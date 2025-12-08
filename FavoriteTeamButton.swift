//
//  FavoriteTeamButton.swift
//  Union
//
//  Created by Graham Nadel on 12/8/25.
//

import Foundation
import SwiftUI

struct FavoriteTeamButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    let teamName: String
    
    var body: some View {
        Button(action: {
            Task {
                if let index = authViewModel.favoriteTeams?.firstIndex(of: teamName) {
                    authViewModel.favoriteTeams?.remove(at: index)
                } else {
                    authViewModel.favoriteTeams?.append(teamName)
                }
                if let favoriteTeams = authViewModel.favoriteTeams, let name = authViewModel.name, let favoritePerformers = authViewModel.favoritePerformers {
                    await authViewModel.updateUserData(name: name, favoriteTeams: favoriteTeams, favoritePerformers: favoritePerformers)
                }
            }
        }) {
            Image(systemName:
                authViewModel.favoriteTeams?.contains(teamName) == true
                ? "star.fill"
                : "star"
            )
                .foregroundColor(favoritesViewModel.favoriteTeamColor)
                .imageScale(.large)
        }
    }
}
