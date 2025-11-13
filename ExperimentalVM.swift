import Foundation
import Combine // <-- Import Combine for the Debounce operation
import SwiftUI

class FavoritesViewModel: ObservableObject {
    
    // 1. Keep @Published for immediate UI reaction
    @Published var favoritePerformers: [String] = []
    @Published var favoriteTeams: [String] = []
    @AppStorage("favoriteTeams") private var favoriteTeamsData: Data = Data()
    @AppStorage("favoriteExperimentalPerformers") private var favoritePerformersData: Data = Data()
    private var cancellables = Set<AnyCancellable>()
    let favoritePerformerColor = Color.purple
    let favoriteTeamColor = Color.yellow

    init() {
        // Load initial favorites (important!)
        loadFavorites()
        
        // 3. Setup a debounced subscriber to handle saving
        // This subscription watches for changes to 'favoritePerformers'
        $favoritePerformers
            .dropFirst() // Ignore the initial value when the view model is initialized
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main) // Wait 1 second after the last change
            .sink { [weak self] _ in
                // Only call the heavy persistence function after the UI has settled
                self?.saveFavorites()
            }
            .store(in: &cancellables)
    }
    
    // Update: Remove saveFavorites() call from here
    func toggleFavoritePerformer(_ name: String) {
        if favoritePerformers.contains(name) {
            favoritePerformers.removeAll { $0 == name }
        } else {
            favoritePerformers.append(name)
        }
        // NOTE: saveFavorites() IS GONE. It will be called automatically by the debouncer.
    }
    
    
    func toggleFavoriteTeam(_ team: String) {
        if favoriteTeams.contains(team) {
            favoriteTeams.removeAll { $0 == team }
        } else {
            favoriteTeams.append(team)
        }
    }
    
    // Persistence function remains private
    private func saveFavorites() {
        if let teamData = try? JSONEncoder().encode(favoriteTeams) {
            favoriteTeamsData = teamData
        }
        if let performerData = try? JSONEncoder().encode(favoritePerformers) {
            favoritePerformersData = performerData
        }
    }
    
    // Add a loading function to populate the @Published array on init
    private func loadFavorites() {
        if let loadedTeams = try? JSONDecoder().decode([String].self, from: favoriteTeamsData) {
            favoriteTeams = loadedTeams
        }
        if let decodedPerformers = try? JSONDecoder().decode([String].self, from: favoritePerformersData) {
            favoritePerformers = decodedPerformers
        }
    }
}
