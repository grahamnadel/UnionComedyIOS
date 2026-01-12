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
    var isFollowing: Bool {
        authViewModel.favoriteTeams?.contains(teamName) ?? false
    }
    
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
            FollowButton(isFollowing: isFollowing)
                .foregroundColor(favoritesViewModel.favoriteTeamColor)
                .imageScale(.large)
        }
    }
}
