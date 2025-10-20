//
//  LoginView.swift
//  Union
//
//  Created by Graham Nadel on 8/14/25.
//

import Foundation
import SwiftUI


struct LoginView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var userName: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter your name", text: $userName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Enter password", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign In") {
                // Call the login function on the viewModel
                if festivalViewModel.attemptLogin(with: password) {
                    showAlert = true
                }
            }
            .padding()
            .background(password.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(password.isEmpty) // Disable the button if the password field is empty
        }
        .padding()
        .alert("Login", isPresented: $showAlert) {
                    Button("Close", role: .cancel) { }
                } message: {
                    if festivalViewModel.isAdminLoggedIn {
                        Text("Login successful")
                    } else {
                        Text("Login failed: incorrect password")
                    }
                }
    }
}
