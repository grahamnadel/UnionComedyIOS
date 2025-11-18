////
////  RestrictedCalendar.swift
////  Union
////
////  Created by Graham Nadel on 10/27/25.
////
//
//import Foundation
//import SwiftUI
//
//struct RestrictedCalendarPicker: View {
//    @Binding var selectedDate: Date
//    let allowedWeekday: Int // 1 = Sunday, 2 = Monday, etc.
//    let dateRange: ClosedRange<Date>
//
//    private let calendar = Calendar.current
//    
//    private var allDaysInRange: [Date] {
//        guard let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: dateRange.lowerBound)),
//              let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: dateRange.upperBound)),
//              let months = calendar.dateComponents([.month], from: startMonth, to: endMonth).month else { return [] }
//        
//        var days: [Date] = []
//        for offset in 0...months {
//            if let monthDate = calendar.date(byAdding: .month, value: offset, to: startMonth),
//               let range = calendar.range(of: .day, in: .month, for: monthDate) {
//                for day in range {
//                    if let fullDate = calendar.date(byAdding: .day, value: day - 1, to: monthDate) {
//                        days.append(fullDate)
//                    }
//                }
//            }
//        }
//        return days
//    }
//
//    var body: some View {
//        let columns = Array(repeating: GridItem(.flexible()), count: 7)
//        
//        VStack(alignment: .leading) {
//            Text("Pick a date").font(.headline)
//            LazyVGrid(columns: columns, spacing: 8) {
//                ForEach(allDaysInRange, id: \.self) { date in
//                    let weekday = calendar.component(.weekday, from: date)
//                    let isAllowed = weekday == allowedWeekday
//                    
//                    Button {
//                        if isAllowed { selectedDate = date }
//                    } label: {
//                        Text("\(calendar.component(.day, from: date))")
//                            .frame(maxWidth: .infinity, minHeight: 40)
//                            .background(
//                                isAllowed
//                                ? (calendar.isDate(date, inSameDayAs: selectedDate)
//                                    ? Color.purple.opacity(0.4)
//                                    : Color.purple.opacity(0.15))
//                                : Color.gray.opacity(0.1)
//                            )
//                            .foregroundColor(isAllowed ? .primary : .gray)
//                            .clipShape(RoundedRectangle(cornerRadius: 6))
//                    }
//                    .disabled(!isAllowed)
//                }
//            }
//        }
//        .padding(.vertical)
//    }
//}
