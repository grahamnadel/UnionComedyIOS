//
//  DateSelectionSection.swift
//  Union
//
//  Created by Graham Nadel on 10/28/25.
//

import Foundation
import SwiftUI

struct DateSelectionSection: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @Binding var selectedShowType: ShowType?
    @Binding var newShowDate: Date
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
            DateInput(selectedShowType: selectedShowType, newShowDate: $newShowDate)
            
            Button("Add Date") {
                let dateToAdd: Date
                if let type = selectedShowType, type != .special, type != .classShow, let defaultTime = type.defaultTime {
                    print("type.defaultTime: \(String(describing: type.defaultTime))")
                    dateToAdd = combineDate(date: newShowDate, hour: defaultTime.hour, minute: defaultTime.minute)
                    print("dateToAdd: \(String(describing: dateToAdd))")
                } else {
                    dateToAdd = newShowDate
                }
                selectedDates.insert(dateToAdd)
            }
            .disabled(selectedDates.contains(date))
        }
        .onChange(of: selectedShowType) {
            if let showType = selectedShowType {
                if let nextShowDate = getNextWeekdayDate() {
                    print("nextShowDate: \(String(describing: nextShowDate))")
                    newShowDate = nextShowDate
                }
            } else {
                print("Could not unwrap showType for \(String(describing: selectedShowType))")
            }
        }
    }
    
    // Get the next non-fully booked show, prioritizing underbooked
    private func getNextWeekdayDate() -> Date? {
        if let showType = selectedShowType {
            let unBookedShows = scheduleViewModel.unBooked[showType]
            let underBookedShows = scheduleViewModel.underBooked[showType]
            print("unBookedShows: \(unBookedShows ?? []), underBookedShows: \(underBookedShows ?? [])")
            
            if let unBookedShows = unBookedShows, !unBookedShows.isEmpty, let underBookedShows = underBookedShows, !underBookedShows.isEmpty {
                let firstUnBookedShow = unBookedShows.first!
                let firstUnderBookedShow = underBookedShows.first!
                if firstUnBookedShow < firstUnderBookedShow {
                    return firstUnBookedShow
                } else if firstUnderBookedShow < firstUnBookedShow {
                    return firstUnderBookedShow
                } else {
                    print("Error: There should not be an underbooked show and an unbooked show at the same time")
                }
            } else if let unBookedShows = unBookedShows, !unBookedShows.isEmpty {
                let firstUnBookedShow = unBookedShows.first!
                return firstUnBookedShow
            } else if let underBookedShows = underBookedShows, !underBookedShows.isEmpty {
                let firstUnderBookedShow = underBookedShows.first!
                return firstUnderBookedShow
            }
        } else {
            print("Could not unwrap showtype")
        }
        return nil
    }
    

    private func combineDate(date: Date, hour: Int, minute: Int) -> Date {
        // 1. Get the current calendar, but ensure it uses the current device time zone
        print("date day: \(String(describing: Calendar.current.component(.day, from: date)))")
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current // Explicitly lock the TimeZone
        
        // 2. Use the simplified setter for greater consistency

        guard let combinedDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) else {
            // Fallback safety
            print("Error with combinedDate")
            return date
        }
        
        // The resulting Date object now consistently represents the exact moment (e.g., 9:00 PM local)
        return combinedDate
    }
}
