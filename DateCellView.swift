////
////  DateCellView.swift
////  Union
////
////  Created by Graham Nadel on 10/27/25.
////
//import SwiftUI
//import Foundation
///// Displays the day number and applies the capacity color background.
//struct DateCellView: View {
//    let day: ScheduleDay
//    @Binding var selectedDate: Date
//    
//    private var isSelected: Bool {
//        Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
//    }
//    
//    var body: some View {
//        VStack {
//            Text("\(Calendar.current.component(.day, from: day.date))")
//                .font(.body)
//                .fontWeight(isSelected ? .bold : .regular)
//                .frame(width: 40, height: 40)
//                .background(
//                    ZStack {
//                        // Background color based on capacity
//                        day.capacityState.color
//                            .cornerRadius(8)
//                        
//                        // Selection Border
//                        if isSelected {
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(Color.black, lineWidth: 3)
//                        }
//                    }
//                )
//                .foregroundColor(.white)
//        }
//        .padding(5)
//    }
//}
