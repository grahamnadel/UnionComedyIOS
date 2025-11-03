//
//  DateInputView.swift
//  Union
//
//  Created by Graham Nadel on 10/28/25.
//

import Foundation
import SwiftUI

struct DateInput: View {
    let selectedShowType: ShowType?
    @Binding var newShowDate: Date
    
    var body: some View {
        if selectedShowType == .special || selectedShowType == nil {
            // Use a full date/time picker for special
            DatePicker("Date & Time", selection: $newShowDate, displayedComponents: [.date, .hourAndMinute])
        } else if let weekday = selectedShowType?.weekday {
            // Restrict picker to this weekday only
            DatePicker(
                "\(weekday)s",
                selection: Binding(
                    get: { newShowDate },
                    set: { newValue in
                        let calendar = Calendar.current
                        
                        // Use the helper to get the target weekday number
                        if let targetWeekday = weekdayNumber(from: weekday) {
                            let newWeekday = calendar.component(.weekday, from: newValue)
                            
                            if newWeekday == targetWeekday {
                                // Allow if it matches the target weekday
                                newShowDate = newValue
                            } else {
                                // Snap to the *nearest* next valid weekday
                                if let nextMatching = calendar.nextDate(
                                    after: newValue,
                                    matching: DateComponents(weekday: targetWeekday),
                                    matchingPolicy: .nextTime
                                ) {
                                    newShowDate = nextMatching
                                }
                            }
                        } else {
                            // Fallback if weekday string is invalid
                            newShowDate = newValue
                        }
                    }
                ),
                in: validDateRange(for: weekday), // Use the helper for range
                displayedComponents: [.date]
            )
        }
    }
    
    // MARK: - Date Helper Functions (Must be accessible to DateInput)
    
    /// Calculates the date range (3 months forward/backward) for a specific weekday.
    private func validDateRange(for weekdayString: String?) -> ClosedRange<Date> {
        // ... (implementation is the same as in the original code)
        guard let dayString = weekdayString,
              let targetWeekday = weekdayNumber(from: dayString) else {
            let today = Calendar.current.startOfDay(for: Date())
            let past = Calendar.current.date(byAdding: .year, value: -1, to: today)!
            let future = Calendar.current.date(byAdding: .year, value: 5, to: today)!
            return past...future
        }

        let calendar = Calendar.current
        let today = Date()
        
        let nextDate = calendar.nextDate(
            after: today,
            matching: DateComponents(weekday: targetWeekday),
            matchingPolicy: .nextTime,
            direction: .forward
        ) ?? today

        let startDate = calendar.date(byAdding: .year, value: -1, to: nextDate)!
        let endDate = calendar.date(byAdding: .year, value: 5, to: nextDate)!
        
        return startDate...endDate
    }

    /// Converts a weekday string to its Calendar component number.
    private func weekdayNumber(from day: String) -> Int? {
        switch day.lowercased() {
        case "sunday": return 1
        case "monday": return 2
        case "tuesday": return 3
        case "wednesday": return 4
        case "thursday": return 5
        case "friday": return 6
        case "saturday": return 7
        default: return nil
        }
    }
}

// You also need the 'combineDate' logic if you haven't moved it.
// A great place for it is an extension on ShowType (if it has the necessary info)
// or a standalone function in AddPerformanceView.
