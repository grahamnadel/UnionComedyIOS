//
//  AdminView.swift
//  Union
//
//  Created by Graham Nadel on 10/22/25.
//

import Foundation
import SwiftUI
import Firebase

struct AdminView: View {
    @EnvironmentObject var adminViewModel: AdminViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(adminViewModel.users) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.email)
                                .font(.headline)
                            Text(user.role.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        if user.approved {
                            Text("Approved")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Button("Approve") {
                                Task { await adminViewModel.approveUser(user) }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .navigationTitle("User Management")
            .toolbar {
                Button("Refresh") { Task { await adminViewModel.fetchUsers() } }
            }
            .task {
                await adminViewModel.fetchUsers()
            }
        }
    }
}
