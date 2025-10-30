//
//  OwnerView.swift
//  Union
//
//  Created by Graham Nadel on 10/22/25.
//

import Foundation
import SwiftUI
import Firebase

struct OwnerView: View {
    @EnvironmentObject var ownerViewModel: OwnerViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ownerViewModel.users) { user in
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
                                Task { await ownerViewModel.approveUser(user) }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .navigationTitle("User Management")
            .toolbar {
                Button("Refresh") { Task { await ownerViewModel.fetchUsers() } }
            }
            .task {
                await ownerViewModel.fetchUsers()
            }
        }
    }
}
