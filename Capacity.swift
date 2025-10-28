//
//  Capacity.swift
//  Union
//
//  Created by Graham Nadel on 10/27/25.
//

import Foundation
import SwiftUI
/// Defines the visual state of a date based on overall team capacity.
enum CapacityState {
    case available // 0 teams booked (4 slots free)
    case partial   // 1 to 3 teams booked
    case full      // 4 teams booked (0 slots free)

    /// Computed color property for the date cell background.
    var color: Color {
        switch self {
        case .available: return Color.green.opacity(0.7)
        case .partial: return Color.yellow.opacity(0.7)
        case .full: return Color.red.opacity(0.7)
        }
    }

    /// Computed label property for display.
    var label: String {
        switch self {
        case .available: return "Fully Open"
        case .partial: return "Partial Bookings"
        case .full: return "Fully Booked"
        }
    }
}
