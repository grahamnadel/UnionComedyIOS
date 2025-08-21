//
//  Item.swift
//  Union
//
//  Created by Graham Nadel on 6/18/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
