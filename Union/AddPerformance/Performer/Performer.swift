//
//  PerformerInput.swift
//  Union
//
//  Created by Graham Nadel on 8/7/25.
//

import Foundation


struct PerformerInput: Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var imageData: Data? = nil

    func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())  // hash only by name
    }
    
    static func == (lhs: PerformerInput, rhs: PerformerInput) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased()
    }
}

