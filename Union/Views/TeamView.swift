//
//  TeamView.swift
//  Union
//
//  Created by Graham Nadel on 6/18/25.
//

import Foundation
import SwiftUI

struct TeamView: View {
    let teamColor: Color
    let teamName: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerSize: CGSize(width: 1.0, height: 1.0))
                .scaledToFit()
                .foregroundColor(teamColor)
            Text(teamName)
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .foregroundColor(.black)
        }
    }
}
