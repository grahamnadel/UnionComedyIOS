//
//  ReAuthView.swift
//  Union
//
//  Created by Graham Nadel on 11/10/25.
//

import Foundation
import SwiftUI

struct ReAuthView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel // To get the email
    
    @State private var password = ""
    @State private var isLoading = false
    @State private var localError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Security Check Required")
                .font(.title2)
                .bold()
            
            Text("To complete the account deletion, please enter your password to confirm your identity.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Password Input Field
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
            
            if let error = localError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Re-authenticate and Delete Button
            Button {
                reauthenticateAndDelete()
            } label: {
                Text(isLoading ? "Processing..." : "Confirm & Delete Account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(password.isEmpty || isLoading)
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding(30)
    }
    
    // MARK: - Re-authentication Logic
    func reauthenticateAndDelete() {
        guard let email = authViewModel.currentUserEmail else {
            localError = "Could not find current user email."
            return
        }
        
        isLoading = true
        localError = nil
        
        // Step 1: Re-authenticate the user with the provided credentials
        FirebaseManager.shared.reauthenticateUser(email: email, password: password) { error in
            if let error = error {
                self.isLoading = false
                // Handle credential errors (e.g., wrong password)
                self.localError = error.localizedDescription
            } else {
                // Step 2: If successful, immediately call deleteAccount() again
                FirebaseManager.shared.deleteAccount { deleteError in
                    self.isLoading = false
                    if let deleteError = deleteError {
                        self.localError = deleteError.localizedDescription
                    } else {
                        // Successful deletion
                        dismiss()
                        // The authViewModel should handle the state change back to the login screen
                    }
                }
            }
        }
    }
}
