//
//  Team.swift
//  Union
//
//  Created by Graham Nadel on 10/16/25.
//

import Foundation
import SwiftUI
//This is the Team structure for cage match

struct Team: Identifiable, Decodable, Hashable {
    var name: String
    let id: String
    var performers: [String]
    var houseTeam = false
}
