import SwiftUI
import Firebase


struct InitialLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel  // Use shared environment object
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole? = nil
    @State private var isSignUp = false

    var body: some View {
        VStack(spacing: 24) {
            Text(isSignUp ? "Create Account" : "Login")
                .font(.largeTitle).bold()
            
            VStack(spacing: 12) {
                if isSignUp {
//                    TODO: Remove spell check
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                }
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
//            TODO: make role initially nil, only allow sign up if they select a role
            if isSignUp {
                Picker("Role", selection: $selectedRole) {
                    Text("Audience").tag(UserRole.audience)
                    Text("Performer").tag(UserRole.performer)
                    Text("Coach").tag(UserRole.coach)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            
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
            
            
//            TODO: Only make clickable once all parameters have values
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Login" : "Create a new account")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    private func handleAuthAction() async {
        do {            
            if isSignUp {
                firstName = firstName.replacingOccurrences(of: " ", with: "")
                lastName = lastName.replacingOccurrences(of: " ", with: "")
                let name = "\(firstName) \(lastName)"
                if let selectedRole = selectedRole {
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
