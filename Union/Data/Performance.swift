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
    let teamName: String
    var showTime: Date
    var performers: [String]
}

//FIXME: is this necessary if I have a Team struct? or that I have performances. What is the difference? why not just load an array of Performances?
struct TeamData: Identifiable, Codable, Hashable {
    var id: String
    var teamName: String
    var showTimes: [Date]
    var performers: [String]
}

