//
//  AccountView.swift
//  Union
//
//  Created by Graham Nadel on 11/18/25.
//

import Foundation
import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingDeleteConfirmation: Bool
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                authViewModel.signOut()
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}
