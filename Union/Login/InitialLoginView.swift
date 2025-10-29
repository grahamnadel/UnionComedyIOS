import SwiftUI
import Firebase
import FirebaseAuth

struct InitialLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole? = nil
    @State private var isSignUp = false
    
    // New state for showing the confirmation message
    @State private var resetPasswordMessage: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            Text(isSignUp ? "Create Account" : "Login")
                .font(.largeTitle).bold()
            
            VStack(spacing: 12) {
                if isSignUp {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled(true)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled(true)
                }
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            if isSignUp {
                Text("Do you perform on a house team?")
                    .foregroundColor(selectedRole == nil ? .red : .blue)
                Picker("Role", selection: $selectedRole) {
                    Text("Yes").tag(UserRole.performer as UserRole?)
                    Text("No").tag(UserRole.audience as UserRole?)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            
            // --- FORGOT PASSWORD BUTTON ---
            HStack {
                Spacer()
                if !isSignUp {
                    Button("Forgot Password?") {
                        Task { await sendPasswordResetEmail() }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { Task { await handleAuthAction() } }) {
                Text(isSignUp ? "Sign Up" : "Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isSignUp && (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty || selectedRole == nil))
            .opacity(isSignUp && (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty || selectedRole == nil) ? 0.5 : 1)
            .padding(.horizontal)
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Login" : "Create a new account")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Display Password Reset Message or Auth Error
            if let message = resetPasswordMessage {
                Text(message)
                    .foregroundColor(.green)
                    .font(.caption)
            } else if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

//    TODO: Move to the authViewModel
    // --- NEW ACTION FUNCTION ---
    private func sendPasswordResetEmail() async {
        // Clear previous messages
        resetPasswordMessage = nil
        authViewModel.error = nil

        guard !email.isEmpty else {
            authViewModel.error = "Please enter your email to reset your password."
            return
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            resetPasswordMessage = "Password reset email sent to \(email)!"
            // Clear the error state if a message is successfully sent
            authViewModel.error = nil
        } catch {
            authViewModel.error = error.localizedDescription
            print("Password reset error: \(error)")
        }
    }
    
    // --- EXISTING AUTH ACTION ---
    private func handleAuthAction() async {
        // Clear the password reset message before attempting login/signup
        resetPasswordMessage = nil
        
        do {
            if isSignUp {
                // ... signup logic ...
                firstName = firstName.replacingOccurrences(of: " ", with: "")
                lastName = lastName.replacingOccurrences(of: " ", with: "")
                let name = "\(firstName) \(lastName)"
                if let selectedRole = selectedRole {
                    // Note: Your UserRole tag needs casting (UserRole.audience as UserRole?)
                    // since selectedRole is optional
                    try await authViewModel.signUp(name: name, email: email, password: password, role: selectedRole)
                }
            } else {
                try await authViewModel.signIn(email: email, password: password)
            }
        } catch {
            authViewModel.error = error.localizedDescription
            print("Error: handleAuthAction(): \(error)")
        }
    }
}
