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
    @Published var name: String?
    @Published var approved = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUserEmail: String?
    
    private var db = Firestore.firestore()
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            if let user = user { self?.fetchUserData(uid: user.uid) }
            self?.currentUserEmail = user?.email
        }
    }


    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
        KeychainHelper.save(email: email, password: password)
        print("SignIn called. email:\(email), password: \(password)")
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
        KeychainHelper.save(email: email, password: password)
    }

    
    func fetchUserData(uid: String) {
        db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            if let data = snapshot?.data() {
                self.role = UserRole(rawValue: data["role"] as? String ?? "audience")
                self.approved = data["approved"] as? Bool ?? false
                self.name = data["name"] as? String ?? "Unknown"
            } else {
                // Check if the user was just created (e.g., in the last 5 seconds)
                // This avoids logging out a new user while their Firestore doc is being created.
                if let creationDate = self.user?.metadata.creationDate,
                   creationDate.timeIntervalSinceNow > -5.0 {
                    
                    print("New user detected, waiting for Firestore document...")
                    // Do nothing and wait for the listener to fire again when the doc is created
                    
                } else {
                    // This is a real error (e.g., user deleted from DB but not Auth)
                    print("Error: User exists in Auth but has no Firestore data.")
                    self.user = nil
                    self.role = nil
                    self.approved = false
                    self.error = "User account not found. Please sign up."
                }
            }
        }
    }


    func signOut() {
        try? Auth.auth().signOut()
        KeychainHelper.clear() // <-- Add this line
        self.user = nil
        self.role = nil
        self.approved = false // <-- Also good to reset this
    }
}
