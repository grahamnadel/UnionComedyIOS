//
//  FollowButton.swift
//  Union
//
//  Created by Graham Nadel on 12/30/25.
//

import Foundation
import SwiftUI

struct FollowButton: View {
    let isFollowing: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isFollowing ? .blue : .white)
            .frame(width: 105, height: 35)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.blue, lineWidth: 2)
            )
            .overlay(
                Text(isFollowing ? "Unfollow" : "Follow")
                    .foregroundColor(isFollowing ? .white : .blue)
            )
    }
}

//#Preview {
//    FollowButton(isFollowing: true)
//}
