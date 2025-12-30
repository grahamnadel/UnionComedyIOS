//
//  ColorCodedCalendar.swift
//  Union
//
//  Created by Graham Nadel on 10/27/25.
//

import Foundation
import SwiftUI

struct ColorCodedCalendar: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @Binding var selectedDate: Date
    @State var selectedDates: [Date] = []
    let calendar = Calendar.current
    let month: Date
    // New property: Pass in a list of dates that contain events.
    let eventDates: [Date]
    
    // --- Helper Properties for Calendar Logic ---
    
    // 1. Calculates the very first date of the month.
    private var startOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
    }
    
    // 2. Calculates the day-of-week index (1=Sunday, 2=Monday...) of the 1st of the month,
    // then subtracts 1 to get the number of leading empty spaces needed.
    private var leadingPaddingDays: Int {
        let weekday = calendar.component(.weekday, from: startOfMonth)
        // If calendar starts on Sunday (1), padding is 0. If Monday (2), padding is 1, etc.
        return weekday - 1
    }
    
    // 3. Generates an array of all dates in the month.
    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }
    
    // --- View Body ---
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        VStack {
            Button("Test") {
                findDays()
            }
            Text(month, format: .dateTime.month(.wide).year())
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 8) {
                // MARK: Weekday Headers
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol.prefix(2))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: Padding Days (The Fix for Alignment)
                ForEach(0..<leadingPaddingDays, id: \.self) { _ in
                    Text("") // Empty space to align the 1st of the month
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                
                // MARK: Month Days
                ForEach(daysInMonth, id: \.self) { date in
                    let day = calendar.component(.day, from: date)
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isSpecial = eventDates.contains { calendar.isDate($0, inSameDayAs: date) }
                    
                    Button {
                        selectedDate = date
                    } label: {
                        Text("\(day)")
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                isSelected ? Color.purple.opacity(0.4)
                                : isSpecial ? Color.orange.opacity(0.7) // Changed color for events
                                : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(isSpecial ? .white : .primary)
                    }
                    // Styling for event dates
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSpecial ? .orange : .clear, lineWidth: 2)
                    )
                }
            }
        }
        .padding()
        .onAppear {
            findDays()
        }
    }
    
    private func findDays() {
        for performance in scheduleViewModel.performances {
            selectedDates.append(performance.showTime)
        
        }
    }
}

//#Preview {
//    // Example event dates: The 1st, 5th, and 10th of the current month.
//    let today = Date()
//    let calendar = Calendar.current
//    let eventDates = [
//        calendar.date(byAdding: .day, value: 0, to: calendar.startOfDay(for: today))!,
//        calendar.date(byAdding: .day, value: 4, to: calendar.startOfDay(for: today))!,
//        calendar.date(byAdding: .day, value: 9, to: calendar.startOfDay(for: today))!
//    ]
//
//    ColorCodedCalendar(selectedDate: .constant(Date()), month: Date(), eventDates: [Date()])
//}
