// ViewModel.swift
import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

class ViewModel: ObservableObject {
    @Published var voteCounts: [String: Int] = [:]
    @Published var hasVoted = false
    @Published var teams = [
        Team(name: "Team 1", id: UUID(), color: .blue),
        Team(name: "Team 2", id: UUID(), color: .red)
    ]
    let correctPassword = "UnionComedy"
    
    private var db = Firestore.firestore()

    init() {
        FirebaseManager.shared.listenToVoteCounts { [weak self] counts in
            Task { @MainActor in
                self?.voteCounts = counts
            }
        }
    }
    
    func resetVotes() {
        FirebaseManager.shared.resetVotes()
    }
    

    func voteFor(_ team: Team) {
        FirebaseManager.shared.voteForTeam(team.name)
        hasVoted = true
    }
    
    
    func fetchVotes() {
        db.collection("votes").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching votes: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No votes found")
                return
            }

            // Count votes by team
            var counts: [String: Int] = [:]
            for document in documents {
                if let team = document.data()["team"] as? String {
                    counts[team, default: 0] += 1
                }
            }

            DispatchQueue.main.async {
                self.voteCounts = counts
            }
        }
    }
}
