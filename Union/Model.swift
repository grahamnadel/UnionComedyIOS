////
////  Model.swift
////  Union
////
////  Created by Graham Nadel on 6/18/25.
////
//
//import Foundation
////import Firebase
//
//struct Election {
//    private var voteCounts: [String: Int] = [:]
//    private var hasVoted = false
//    
//    init() {
//        listenForVotes()
//    }
//    
//    mutating func vote(for team: Team) {
//        FirebaseManager.shared.voteForTeam(team.name)
//        self.hasVoted = true
//    }
//    
//    private mutating func listenForVotes() {
//        FirebaseManager.shared.listenToVoteCounts { counts in
//            Task { @MainActor in
//                self.voteCounts = counts
//            }
//        }
//    }
//}
