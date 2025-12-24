//
//  SwiftUIView.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-02-09.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showCreateAccountAlert = false
    @State private var showResetPasswordAlert = false
    @State private var showResetConfirmation = false
    @State private var navigateToMain = false
    @State private var isLoggingIn = false
    @EnvironmentObject var viewModel: AuthViewModel
    
    // Validation states
    @State private var emailValidationMessage: String?
    
    // Constants to simplify complex expressions
    private let mainColor = Color(red: 68/255, green: 55/255, blue: 235/255)
    
    init(email: String = "") {
        _email = State(initialValue: email)
    }
    
    // Computed properties to break down complex expressions
    private var isFormValid: Bool {
        return !email.isEmpty && email.contains("@") && !password.isEmpty && password.count > 5
    }
    
    private var shouldShowButton: Bool {
        return isFormValid && !isLoggingIn && !viewModel.isLoading
    }
    
    private var buttonOpacity: Double {
        return shouldShowButton ? 1.0 : 0.5
    }
    
    private var isButtonDisabled: Bool {
        return !isFormValid || isLoggingIn || viewModel.isLoading
    }
    
    private var isInputDisabled: Bool {
        return isLoggingIn || viewModel.isLoading
    }
    
    var body: some View {
        NavigationStack {
            VStack {                
                logoSection
                inputFieldsSection
                errorMessageSection
                forgotPasswordSection
                signInButtonSection
                Spacer()
                signUpSection
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden()
            }
            .alert("Account Not Found", isPresented: $showCreateAccountAlert) {
                Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
                NavigationLink("Create Account") {
                    RegistrationView()
                        .navigationBarBackButtonHidden(true)
                }
            } message: {
                Text("\(LocalizedStringKey.wouldYouLikeToCreate.localized()) \(email)?")
            }
            .alert("Reset Password", isPresented: $showResetPasswordAlert) {
                Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
                Button(LocalizedStringKey.reset.localized()) {
                    handlePasswordReset()
                }
            } message: {
                Text("\(LocalizedStringKey.sendPasswordResetEmail.localized()) \(email)?")
            }
            .alert("Password Reset Email Sent", isPresented: $showResetConfirmation) {
                Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
            } message: {
                Text(LocalizedStringKey.checkYourEmail.localized())
            }
        }
        .onChange(of: viewModel.networkAvailable) {
            if !viewModel.networkAvailable {
                errorMessage = "No internet connection. Please check your network settings and try again."
            } else {
                // If network becomes available again, clear the error message
                if errorMessage == "No internet connection. Please check your network settings and try again." {
                    errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var logoSection: some View {
        Image("HauteVision")
            .resizable()
            .scaledToFit()
            .frame(width: 140, height: 140)
            .padding(.vertical, 24)
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                InputView(text: $email, 
                        title: "Email Address", 
                        placeholder: "name@example.com")
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .disabled(isInputDisabled)
                    .onChange(of: email) { _, newValue in
                        validateEmail(newValue)
                        // Clear error when user starts typing
                        if errorMessage != nil {
                            errorMessage = nil
                        }
                    }
                
                if let message = emailValidationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("valid") ? mainColor : .red)
                }
            }
            
            InputView(text: $password, 
                    title: "Password", 
                    placeholder: "Enter your password", 
                    isSecureField: true)
                .disabled(isInputDisabled)
                .onChange(of: password) { _, _ in
                    // Clear error when user starts typing
                    if errorMessage != nil {
                        errorMessage = nil
                    }
                }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    private var errorMessageSection: some View {
        Group {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var forgotPasswordSection: some View {
        Button {
            if email.isEmpty || !email.contains("@") {
                errorMessage = "Please enter a valid email address to reset your password"
            } else {
                showResetPasswordAlert = true
            }
        } label: {
            Text(LocalizedStringKey.forgotPassword.localized())
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(mainColor)
                .padding(.top, 8)
                .padding(.trailing, 28)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .disabled(isInputDisabled)
    }
    
    private var signInButtonSection: some View {
        Button(action: {
            handleSignIn()
        }) {
            HStack {
                if isLoggingIn || viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(LocalizedStringKey.signIn.localized())
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(mainColor)
            .cornerRadius(10)
        }
        .disabled(isButtonDisabled)
        .opacity(buttonOpacity)
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    private var signUpSection: some View {
        NavigationLink {
            RegistrationView()
                .navigationBarBackButtonHidden()
        } label: {
            HStack(spacing: 3) {
                Text(LocalizedStringKey.dontHaveAccount.localized())
                    .foregroundColor(.secondary)
                Text(LocalizedStringKey.signUp.localized())
                    .fontWeight(.bold)
                    .foregroundColor(mainColor)
            }
            .font(.system(size: 14))
        }
        .disabled(isInputDisabled)
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
    
    private func handleSignIn() {
        guard !isLoggingIn else { 
            return 
        }
        
        if !viewModel.networkAvailable {
            errorMessage = "No internet connection. Please check your network settings and try again."
            return
        }
        
        isLoggingIn = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.signIn(withEmail: email, password: password)
                await MainActor.run {
                    navigateToMain = true
                }
            } catch {
                handleSignInError(error)
            }
            await MainActor.run {
                isLoggingIn = false
            }
        }
    }
    
    private func handleSignInError(_ error: Error) {
        let nsError = error as NSError
        
        // Handle Firebase Auth errors
        if nsError.domain == AuthErrorDomain {
            switch nsError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Incorrect password. Please check and try again."
            case AuthErrorCode.userNotFound.rawValue:
                showCreateAccountAlert = true
                return
            case AuthErrorCode.userDisabled.rawValue:
                errorMessage = "This account has been disabled. Please contact support."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Invalid email format. Please enter a valid email address."
            case AuthErrorCode.tooManyRequests.rawValue:
                errorMessage = "Too many failed login attempts. Please try again later."
            default:
                errorMessage = "Sign in failed. Please check your email and password."
            }
        }
        // Handle network error
        else if nsError.domain == "AuthError" && nsError.code == -1 {
            errorMessage = "Network error. Please check your connection and try again."
        }
        // Handle other errors
        else {
            errorMessage = "Unable to sign in. Please try again later."
        }
    }
    
    private func handlePasswordReset() {
        Task {
            do {
                try await viewModel.resetPassword(email: email)
                showResetConfirmation = true
            } catch {
                let nsError = error as NSError
                
                if nsError.domain == AuthErrorDomain && nsError.code == AuthErrorCode.userNotFound.rawValue {
                    errorMessage = "No account found with this email address."
                } else if nsError.domain == "AuthError" && nsError.code == -1 {
                    errorMessage = "Network error. Please check your connection and try again."
                } else {
                    errorMessage = "Failed to send reset email. Please verify your email address."
                }
            }
        }
    }
}

extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return isFormValid
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View{
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
