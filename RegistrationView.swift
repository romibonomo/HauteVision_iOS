//
//  RegistrationView.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-02-10.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegistrationView: View {
    @StateObject var viewModel = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isRegistering = false
    @State private var navigateToMain = false
    
    // Validation states
    @State private var emailValidationMessage: String?
    @State private var passwordValidationMessage: String?
    @State private var nameValidationMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Image
                Image("HauteVision")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .padding(.vertical, 24)
                
                // Form fields
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        InputView(text: $email,
                                 title: "Email Address",
                                 placeholder: "name@example.com",
                                 isSecureField: false)
                            .textInputAutocapitalization(.never)
                            .disabled(isRegistering)
                            .onChange(of: email) { _, newValue in
                                validateEmail(newValue)
                            }
                        
                        if let message = emailValidationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(message.contains("valid") ? Color(red: 68/255, green: 55/255, blue: 235/255) : .red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        InputView(text: $fullName,
                                 title: "Full Name",
                                 placeholder: "Enter your full name",
                                 isSecureField: false)
                            .disabled(isRegistering)
                            .onChange(of: fullName) { _, newValue in
                                validateName(newValue)
                            }
                        
                        if let message = nameValidationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(message.contains("valid") ? Color(red: 68/255, green: 55/255, blue: 235/255) : .red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        InputView(text: $password,
                                 title: "Password",
                                 placeholder: "Enter your password",
                                 isSecureField: true)
                            .disabled(isRegistering)
                            .onChange(of: password) { _, newValue in
                                validatePassword(newValue)
                            }
                        
                        if let message = passwordValidationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(message.contains("valid") ? Color(red: 68/255, green: 55/255, blue: 235/255) : .red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        InputView(text: $confirmPassword,
                                 title: "Confirm Password",
                                 placeholder: "Confirm your password",
                                 isSecureField: true)
                            .disabled(isRegistering)
                        
                        if !confirmPassword.isEmpty {
                            Text(password == confirmPassword ? "Passwords match" : "Passwords do not match")
                                .font(.caption)
                                .foregroundColor(password == confirmPassword ? Color(red: 68/255, green: 55/255, blue: 235/255) : .red)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Sign up button
                Button {
                    handleRegistration()
                } label: {
                    HStack {
                        if isRegistering {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(LocalizedStringKey.signUp.localized())
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                    .background(Color(red: 68/255, green: 55/255, blue: 235/255))
                    .cornerRadius(10)
                    .padding(.top, 24)
                }
                .disabled(!formIsValid || isRegistering)
                .opacity((formIsValid && !isRegistering) ? 1.0 : 0.5)
                
                Spacer()
                
                // Sign in button
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Text(LocalizedStringKey.alreadyHaveAccount.localized())
                            .foregroundColor(.secondary)
                        Text(LocalizedStringKey.signIn.localized())
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 68/255, green: 55/255, blue: 235/255))
                    }
                    .font(.system(size: 14))
                }
                .disabled(isRegistering)
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden()
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailValidationMessage = nil
        } else if !email.contains("@") || !email.contains(".") {
            emailValidationMessage = "Please enter a valid email address"
        } else {
            emailValidationMessage = nil
        }
    }
    
    private func validateName(_ name: String) {
        if name.isEmpty {
            nameValidationMessage = nil
        } else if name.count < 2 {
            nameValidationMessage = "Name is too short"
        } else {
            nameValidationMessage = nil
        }
    }
    
    private func validatePassword(_ password: String) {
        if password.isEmpty {
            passwordValidationMessage = nil
        } else if password.count < 6 {
            passwordValidationMessage = "Password must be at least 6 characters"
        } else {
            passwordValidationMessage = nil
        }
    }
    
    private func handleRegistration() {
        guard !isRegistering else { return }
        
        isRegistering = true
        
        Task {
            do {
                try await viewModel.createUser(
                    withEmail: email,
                    password: password,
                    name: fullName
                )
                await MainActor.run {
                    isRegistering = false
                    navigateToMain = true
                }
            } catch {
                await MainActor.run {
                    isRegistering = false
                    handleRegistrationError(error)
                }
            }
        }
    }
    
    private func handleRegistrationError(_ error: Error) {
        let nsError = error as NSError
        
        if nsError.domain == AuthErrorDomain {
            switch nsError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                alertMessage = "This email is already registered. Please sign in instead."
            case AuthErrorCode.invalidEmail.rawValue:
                alertMessage = "Please enter a valid email address."
            case AuthErrorCode.weakPassword.rawValue:
                alertMessage = "Password is too weak. Please use a stronger password."
            default:
                alertMessage = "Failed to create account. Please try again."
            }
        } else {
            alertMessage = "An error occurred. Please try again."
        }
        
        showingAlert = true
    }
}

extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count > 5
        && !fullName.isEmpty
        && password == confirmPassword
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
