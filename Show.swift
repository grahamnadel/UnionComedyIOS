//
//  Show.swift
//  Union
//
//  Created by Graham Nadel on 10/27/25.
//

import Foundation

//TODO: Change Team to Performance?
struct Show: Identifiable {
    let id = UUID()
    let showType: ShowType
    var performances: [Performance] // Max 2
}
