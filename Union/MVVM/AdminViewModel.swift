//
//  AdminViewModel.swift
//  Union
//
//  Created by Graham Nadel on 10/22/25.
//

import Foundation
import FirebaseFirestore

class AdminViewModel: ObservableObject {
    @Published var users: [AppUser] = []
    private let db = Firestore.firestore()
    
    func fetchUsers() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            self.users = snapshot.documents.compactMap { doc in
                try? doc.data(as: AppUser.self)
            }
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
        }
    }
    
    func approveUser(_ user: AppUser) async {
        guard let id = user.id else { return }
        do {
            try await db.collection("users").document(id).updateData(["approved": true])
            await fetchUsers()
        } catch {
            print("Error approving user: \(error.localizedDescription)")
        }
    }
}
