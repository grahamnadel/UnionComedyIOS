import SwiftUI
import Firebase


struct InitialLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel  // Use shared environment object
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .audience
    @State private var isSignUp = false

    var body: some View {
        VStack(spacing: 24) {
            Text(isSignUp ? "Create Account" : "Login")
                .font(.largeTitle).bold()
            
            VStack(spacing: 12) {
                if isSignUp {
                    TextField("Name", text: $name)
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
            
            if isSignUp {
                Picker("Role", selection: $selectedRole) {
                    Text("Audience").tag(UserRole.audience)
                    Text("Performer").tag(UserRole.performer)
                    Text("Coach").tag(UserRole.coach)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            
            Button(action: { Task { await handleAuthAction() } }) {
                Text(isSignUp ? "Sign Up" : "Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Login" : "Create a new account")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if let role = authViewModel.role {
                if !authViewModel.approved && role != .audience {
                    Text("Your \(role.rawValue.capitalized) account is pending approval.")
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .onAppear {
            print("Going to initialLoginView")
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
    }

    private func handleAuthAction() async {
        do {            
            if isSignUp {
                try await authViewModel.signUp(name: name, email: email, password: password, role: selectedRole)
            } else {
                try await authViewModel.signIn(email: email, password: password)
            }
        } catch {
            authViewModel.error = error.localizedDescription
            print("Error: handleAuthAction(): \(error)")
        }
    }
}
