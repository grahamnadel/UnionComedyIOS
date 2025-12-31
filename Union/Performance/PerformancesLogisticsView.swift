//
//  PerformancesLogisticsView.swift
//  Union
//
//  Created by Graham Nadel on 12/23/25.
//

import Foundation
import SwiftUI

struct PerformancesLogisticsView: View {
    let showTime: Date
    
    var body: some View {
        VStack(spacing: 0) {
            if let showType = ShowType.dateToShow(date: showTime) {
                Text(showType.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.heavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(showType.showColor.opacity(0.15))
                    .foregroundColor(showType.showColor)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
            
            Text(showTime, format: .dateTime
                .weekday(.wide)
                .month(.abbreviated)
                .day()
            )
            .font(.callout)
            .fontWeight(.bold)
            
            Text(showTime.formatted(.dateTime.hour().minute()))
                .font(.system(.subheadline, design: .rounded))
                .bold()
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        
    }
}
