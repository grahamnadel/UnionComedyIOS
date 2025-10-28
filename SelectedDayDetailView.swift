////
////  SelectedDayDetailView.swift
////  Union
////
////  Created by Graham Nadel on 10/27/25.
////
//import SwiftUI
//import Foundation
//// Displays detailed information about the selected date.
//struct SelectedDayDetailView: View {
//    let day: ScheduleDay
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("Details for \(day.date, style: .date)")
//                .font(.headline)
//            
//            HStack {
//                Text("Overall Status:")
//                Text(day.capacityState.label)
//                    .fontWeight(.bold)
//                    .foregroundColor(day.capacityState.color)
//            }
//            
//            Text("Total Teams Booked: \(day.bookedSlots) / 4")
//            
//            // Display Show details
//            ForEach(day.shows.indices, id: \.self) { index in
//                let show = day.shows[index]
//                HStack {
//                    Text("Show \(index + 1):")
//                    Text("\(show.teams.count) / 2 Teams Booked")
//                        .foregroundColor(show.teams.count == 2 ? .red : .green)
//                }
//            }
//        }
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.1)))
//        .padding(.horizontal)
//    }
//}
