//
//  LoadingView.swift
//  Union
//
//  Created by Graham Nadel on 11/14/25.
//
import SwiftUI
import Foundation

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image("UC")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                ProgressView()
                    .scaleEffect(1.6)
                Spacer()
            }
        }
    }
}
