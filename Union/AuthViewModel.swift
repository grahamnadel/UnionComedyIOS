//
//  AuthViewModel.swift
//  Union
//
//  Created by Graham Nadel on 10/22/25.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var role: UserRole?
    @Published var approved = false
    @Published var isLoading = false
    @Published var error: String?
    
    private var db = Firestore.firestore()
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            if let user = user { self?.fetchUserData(uid: user.uid) }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(name: String, email: String, password: String, role: UserRole) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let approved = (role == .audience)
        try await db.collection("users").document(result.user.uid).setData([
            "name": name,
            "email": email,
            "role": role.rawValue,
            "approved": approved
        ])
    }

    
    func fetchUserData(uid: String) {
        db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            if let data = snapshot?.data() {
                self.role = UserRole(rawValue: data["role"] as? String ?? "audience")
                self.approved = data["approved"] as? Bool ?? false
            } else {
                // No user document yet — log out or show error
                self.user = nil
                self.role = nil
                self.approved = false
                self.error = "User account not found. Please sign up."
            }
        }
    }


    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
        self.role = nil
    }
}
