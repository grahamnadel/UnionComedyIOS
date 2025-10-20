//
//  User.swift
//  Union
//
//  Created by Graham Nadel on 10/20/25.
//

import Foundation


// For use in push notifications when saving User favorites/data to the cloud
struct User: Identifiable, Codable {
    var id: String
    var favoriteTeams: [String]
    var favoritePerformers: [String]
    var pushToken: String?  // For push notifications
}
