//
//  data.swift
//  Union
//
//  Created by Graham Nadel on 8/5/25.
//

import Foundation
import SwiftUI

//TODO: change to having a Team which contains an array of names
struct Performance: Identifiable, Codable, Hashable {
    var id = UUID()
    let teamName: String
    var showTime: Date
    var performers: [String]
}

struct Team: Identifiable {
    var name: String
    let id: UUID
    let color: Color
}

struct FestivalData: Codable {
    var performances: [Performance]
    var knownPerformers: [String]
}

