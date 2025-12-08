import Foundation
import SwiftUI

struct FavoritePerformerButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    let performerName: String
    
    var body: some View {
        Button(action: {
            Task {
                if let index = authViewModel.favoritePerformers?.firstIndex(of: performerName) {
                    authViewModel.favoritePerformers?.remove(at: index)
                } else {
                    authViewModel.favoritePerformers?.append(performerName)
                }
                if let favoriteTeams = authViewModel.favoriteTeams, let name = authViewModel.name, let favoritePerformers = authViewModel.favoritePerformers {
                    await authViewModel.updateUserData(name: name, favoriteTeams: favoriteTeams, favoritePerformers: favoritePerformers)
                }
            }
        }) {
            Image(systemName:
                    authViewModel.favoritePerformers?.contains(performerName) == true
                ? "star.fill"
                : "star"
            )
            .foregroundColor(favoritesViewModel.favoritePerformerColor)
                .imageScale(.large)
        }
    }
}
