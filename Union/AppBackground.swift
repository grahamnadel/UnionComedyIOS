//
//  AppBackground.swift
//  Union
//
//  Created by Graham Nadel on 12/30/25.
//

import Foundation
import SwiftUI

struct AppBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color("LightPurple")
                .ignoresSafeArea()

            content
        }
    }
}
