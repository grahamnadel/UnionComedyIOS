//
//  PerformancesLogisticsView.swift
//  Union
//
//  Created by Graham Nadel on 12/23/25.
//

import Foundation
import SwiftUI

struct PerformancesLogisticsView: View {
    let showType: ShowType
    let showTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(showTime, style: .date)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            HStack(alignment: .center) {
                Text(showType.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.heavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(showType.showColor.opacity(0.15))
                    .foregroundColor(showType.showColor)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(showTime.formatted(.dateTime.hour().minute()))
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
        }
        .padding(.vertical, 4)
    }
}
