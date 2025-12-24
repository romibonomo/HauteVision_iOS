import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    @State private var name: String
    @State private var email: String
    @State private var showEmailVerification = false
    @State private var showPasswordChange = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isUpdating = false
    @State private var showPasswordSection = false
    @State private var pendingEmail = ""
    
    init(user: User) {
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Initials/Profile Picture Section
                Section {
                    HStack {
                        Spacer()
                        Text(name.initials)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 120)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(red: 68/255, green: 55/255, blue: 235/255), Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                // Full Name Section
                Section(header: Text("full_name".localized()).foregroundColor(Color(red: 68/255, green: 55/255, blue: 235/255))
                    .id(currentLanguage)) {
                    TextField("enter_your_name".localized(), text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .font(.body)
                        .id(currentLanguage)
                }
                
                // Email Address Section
                Section(header: Text("email_address".localized()).foregroundColor(Color(red: 68/255, green: 55/255, blue: 235/255))
                    .id(currentLanguage)) {
                    HStack {
                        Text(email)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            pendingEmail = email
                            showEmailVerification = true
                        }) {
                            Text("change".localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 68/255, green: 55/255, blue: 235/255))
                                .id(currentLanguage)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                // Change Password Section
                Section {
                    Button(action: {
                        showPasswordChange = true
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Color(red: 68/255, green: 55/255, blue: 235/255))
                                .frame(width: 24)
                            Text("change_password".localized())
                                .foregroundColor(.primary)
                                .id(currentLanguage)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            Spacer()
            HStack {
                Spacer()
                NavigationLink(destination: GeneralPrivacyPolicyView()) {
                    Text("privacy_policy".localized())
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .id(currentLanguage)
                }
                Spacer()
            }
            .padding(.bottom, 24)
            .navigationTitle("edit_profile".localized())
            .navigationBarTitleDisplayMode(.inline)
            .id(currentLanguage)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized()) {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 68/255, green: 55/255, blue: 235/255))
                    .id(currentLanguage)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        updateProfile()
                    } label: {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("save".localized())
                                .id(currentLanguage)
                        }
                    }
                    .disabled(!profileFieldsValid || isUpdating)
                    .foregroundColor(Color(red: 68/255, green: 55/255, blue: 235/255))
                }
            }
            .alert("error".localized(), isPresented: $showError) {
                Button("ok".localized(), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("success".localized(), isPresented: $showSuccess) {
                Button("ok".localized(), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("profile_updated_successfully".localized())
            }
            .sheet(isPresented: $showEmailVerification) {
                EmailChangeView(
                    currentEmail: email,
                    newEmail: $pendingEmail,
                    isPresented: $showEmailVerification
                )
            }
            .sheet(isPresented: $showPasswordChange) {
                PasswordChangeView(isPresented: $showPasswordChange)
            }
        }
    }
    
    private var profileFieldsValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func updateProfile() {
        isUpdating = true
        
        Task {
            do {
                try await viewModel.updateProfile(name: name, email: email)
                await MainActor.run {
                    isUpdating = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct EmailChangeView: View {
    let currentEmail: String
    @Binding var newEmail: String
    @Binding var isPresented: Bool
    @State private var currentPassword = ""
    @State private var isVerifying = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @EnvironmentObject var viewModel: AuthViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("change_email".localized())
                    .id(currentLanguage)) {
                    TextField("current_email".localized(), text: .constant(currentEmail))
                        .disabled(true)
                        .id(currentLanguage)
                    
                    TextField("new_email".localized(), text: $newEmail)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .id(currentLanguage)
                    
                    SecureField("current_password".localized(), text: $currentPassword)
                        .id(currentLanguage)
                }
                
                Section {
                    Button(action: verifyAndChangeEmail) {
                        if isVerifying {
                            ProgressView()
                        } else {
                            Text("send_verification_email".localized())
                                .id(currentLanguage)
                        }
                    }
                    .disabled(!isValid || isVerifying)
                }
            }
            .navigationTitle("change_email".localized())
            .navigationBarTitleDisplayMode(.inline)
            .id(currentLanguage)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized()) {
                        isPresented = false
                    }
                    .id(currentLanguage)
                }
            }
            .alert("error".localized(), isPresented: $showError) {
                Button("ok".localized(), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("verification_email_sent".localized(), isPresented: $showSuccess) {
                Button("ok".localized(), role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text("verification_email_sent_message".localized().replacingOccurrences(of: "{email}", with: newEmail))
            }
        }
    }
    
    private var isValid: Bool {
        !newEmail.isEmpty && newEmail.contains("@") && !currentPassword.isEmpty && newEmail != currentEmail
    }
    
    private func verifyAndChangeEmail() {
        guard let user = Auth.auth().currentUser else { return }
        
        isVerifying = true
        
        Task {
            do {
                // First reauthenticate
                let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)
                try await user.reauthenticate(with: credential)
                
                // Then send verification email
                try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
                
                await MainActor.run {
                    isVerifying = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct PasswordChangeView: View {
    @Binding var isPresented: Bool
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @EnvironmentObject var viewModel: AuthViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("change_password".localized())
                    .id(currentLanguage)) {
                    SecureField("current_password".localized(), text: $currentPassword)
                        .id(currentLanguage)
                    SecureField("new_password".localized(), text: $newPassword)
                        .id(currentLanguage)
                    SecureField("confirm_new_password".localized(), text: $confirmNewPassword)
                        .id(currentLanguage)
                }
                
                Section {
                    Button(action: updatePassword) {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("update_password".localized())
                                .id(currentLanguage)
                        }
                    }
                    .disabled(!passwordFieldsValid || isUpdating)
                }
            }
            .navigationTitle("change_password".localized())
            .navigationBarTitleDisplayMode(.inline)
            .id(currentLanguage)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized()) {
                        isPresented = false
                    }
                    .id(currentLanguage)
                }
            }
            .alert("error".localized(), isPresented: $showError) {
                Button("ok".localized(), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("success".localized(), isPresented: $showSuccess) {
                Button("ok".localized(), role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text("password_updated_successfully".localized())
            }
        }
    }
    
    private var passwordFieldsValid: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && !confirmNewPassword.isEmpty &&
        newPassword == confirmNewPassword && newPassword.count >= 6
    }
    
    private func updatePassword() {
        guard passwordFieldsValid else { return }
        isUpdating = true
        
        Task {
            do {
                try await viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                await MainActor.run {
                    isUpdating = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

extension String {
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: self) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
} 