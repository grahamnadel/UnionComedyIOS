//
//  data.swift
//  Union
//
//  Created by Graham Nadel on 8/5/25.
//

import Foundation
import SwiftUI

struct Performance: Identifiable, Codable, Hashable {
    var id = UUID()
    var teamName: String
    var showTime: Date
    var performers: [String]
}

struct Performances: Identifiable, Codable, Hashable {
    var id = UUID()
    var performances: [Performance]
}

//FIXME: is this necessary if I have a Team struct? or that I have performances. What is the difference? why not just load an array of Performances?
struct TeamData: Identifiable, Codable, Hashable {
    var id: String
    var teamName: String
    var showTimes: [Date]
    var performers: [String]
}

struct Team: Identifiable, Decodable, Hashable {
    var name: String
    let id: String
    var performers: [String]
    var houseTeam = false
}
