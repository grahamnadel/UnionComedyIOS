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
    let showTime: Date
    var performers: [String]
}
