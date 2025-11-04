//
//  BookingStatusView.swift
//  Union
//
//  Created by Graham Nadel on 11/4/25.
//

import Foundation
import SwiftUI

struct BookingStatusView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var selectedShowType: ShowType = .special
    @State private var selectedBookingStatus: BookingStatus = .unBooked
    
    var dates: [ShowType : [Date]] {
        scheduleViewModel.getBookingDates(for: selectedBookingStatus)
    }
    
    var body: some View {
        Text("Bookings")
        HStack {
            Picker("Select View", selection: $selectedShowType) {
                ForEach(ShowType.allCases, id: \.self) { option in
                    if option != .special {
                        Text(option.rawValue).tag(option)
                    } else if option == .special {
                        Text("All Show Types")
                    }
                }
            }
            
            Picker("Booking Status", selection: $selectedBookingStatus) {
                ForEach(BookingStatus.allCases, id: \.self) { option in
                    Text(option.localizedDescription).tag(option)
                }
            }
        }
        
        ForEach(dates.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key.rawValue) { key, dates in
            //                Make this bring up addPerformance with the current performance pulled up
            if key == selectedShowType || selectedShowType == .special {
                Text(key.displayName)
                ForEach(dates, id: \.self) { showDate in
                    NavigationLink("\(showDate.formatted(.dateTime.month(.abbreviated).day()))", destination: AddPerformanceView(date: showDate, showType: selectedShowType))
                }
            }
        }
    }
}
