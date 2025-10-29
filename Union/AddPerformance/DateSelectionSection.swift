//
//  DateSelectionSection.swift
//  Union
//
//  Created by Graham Nadel on 10/28/25.
//

import Foundation
import SwiftUI

struct DateSelectionSection: View {
    @Binding var selectedShowType: ShowType?
    @Binding var specialDate: Date
    @Binding var selectedDates: Set<Date>
    @Binding var date: Date
    
    var body: some View {
        Section(header: Text("Add Dates")) {
            Picker("Show Type", selection: $selectedShowType) {
                Text("Special Date/Time").tag(nil as ShowType?)
                
                ForEach(ShowType.allCases.filter { $0 != .special }) { type in
                    Text(type.displayName).tag(type as ShowType?)
                }
            }
            
            // Use a specific subview for the DatePicker logic
            DateInput(selectedShowType: selectedShowType, specialDate: $specialDate)

            Button("Add Date") {
                let dateToAdd: Date
                if let type = selectedShowType, type != .special, let defaultTime = type.defaultTime {
                    dateToAdd = combineDate(date: specialDate, hour: defaultTime.hour, minute: defaultTime.minute)
                } else {
                    dateToAdd = specialDate
                }
                selectedDates.insert(dateToAdd)
            }
            .disabled(selectedDates.contains(date))
        }
    }
    
    private func combineDate(date: Date, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        
        // Extract year, month, day from the input date
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Create the new components with the static time
        var timeComponents = DateComponents()
        timeComponents.year = dayComponents.year
        timeComponents.month = dayComponents.month
        timeComponents.day = dayComponents.day
        timeComponents.hour = hour
        timeComponents.minute = minute
        timeComponents.second = 0
        
        // Return the new combined Date, or the original if creation fails
        return calendar.date(from: timeComponents) ?? date
    }
}
