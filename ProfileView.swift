//
//  ProfileView.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-02-10.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showDeleteConfirmation = false
    @State private var navigateToLogin = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isDeleting = false
    @State private var showChangePassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChangingPassword = false
    @State private var showPasswordSuccess = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.white)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        // Profile Header Card
                        if viewModel.currentUser != nil {
                            VStack(spacing: 20) {
                                // Profile Picture with Initials
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [Color(red: 68/255, green: 55/255, blue: 235/255), Color.blue.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 120, height: 120)
                                        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                                    Text(viewModel.currentUser!.initials)
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                // User Info
                                VStack(spacing: 8) {
                                    Text(viewModel.currentUser!.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text(viewModel.currentUser!.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
                            )
                            .padding(.horizontal)
                        } else {
                            VStack {
                                Text(LocalizedStringKey.noUserDataAvailable.localized())
                                    .foregroundColor(.red)
                                if let userSession = viewModel.userSession {
                                    Text("\(LocalizedStringKey.userSessionExists.localized()) \(userSession.uid)")
                                } else {
                                    Text(LocalizedStringKey.noUserSession.localized())
                                }
                            }
                            .padding()
                        }
                        // Account Section Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("account_settings".localized())
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            // Change Password Card
                            ProfileActionRow(
                                iconName: "lock.fill",
                                iconColor: Color(red: 68/255, green: 55/255, blue: 235/255),
                                title: "change_password".localized(),
                                titleColor: .primary,
                                action: { showChangePassword = true }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                            )
                            .padding(.horizontal)


                            // Sign Out Card
                            ProfileActionRow(
                                iconName: "arrow.left.circle.fill",
                                iconColor: Color(red: 68/255, green: 55/255, blue: 235/255),
                                title: "sign_out".localized(),
                                titleColor: .primary,
                                action: {
                                    try? viewModel.signOut()
                                    navigateToLogin = true
                                }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                            )
                            .padding(.horizontal)

                            // Delete Account Card
                            ProfileActionRow(
                                iconName: "xmark.circle.fill",
                                iconColor: .red,
                                title: "delete_account".localized(),
                                titleColor: .red,
                                action: { showDeleteConfirmation = true }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                            )
                            .padding(.horizontal)

                            // Reset Onboarding Card (for testing)
                            ProfileActionRow(
                                iconName: "arrow.clockwise.circle.fill",
                                iconColor: .orange,
                                title: "reset_onboarding".localized(),
                                titleColor: .orange,
                                action: { 
                                    viewModel.resetOnboarding()
                                    // Force app restart to show onboarding
                                    exit(0)
                                }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    Spacer()
                    // Bottom links
                    HStack(spacing: 24) {
                        NavigationLink(destination: AboutUsView()
                            .environmentObject(localizationManager)) {
                            Text("about".localized())
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        NavigationLink(destination: GeneralPrivacyPolicyView()
                            .environmentObject(localizationManager)) {
                            Text("privacy_policy".localized())
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentUser != nil {
                        Button {
                            showEditProfile = true
                        } label: {
                            Text("edit".localized())
                        }
                    }
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView(
                    isPresented: $showChangePassword,
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isChangingPassword: $isChangingPassword,
                    showSuccess: $showPasswordSuccess
                )
            }
            .alert("delete_account_confirmation".localized(), isPresented: $showDeleteConfirmation) {
                Button("cancel".localized(), role: .cancel) { }
                Button("delete".localized(), role: .destructive) {
                    isDeleting = true
                    Task {
                        do {
                            try await viewModel.deleteAccount()
                            navigateToLogin = true
                        } catch {
                            showError = true
                            errorMessage = error.localizedDescription
                        }
                        isDeleting = false
                    }
                }
            } message: {
                Text("delete_account_message".localized())
            }
            .alert("error".localized(), isPresented: $showError) {
                Button("ok".localized(), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("password_changed".localized(), isPresented: $showPasswordSuccess) {
                Button("ok".localized(), role: .cancel) { }
            } message: {
                Text("password_changed_message".localized())
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
                    .navigationBarBackButtonHidden()
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = viewModel.currentUser {
                    EditProfileView(user: user)
                }
            }
        }
        .task {
            if viewModel.userSession != nil && viewModel.currentUser == nil {
                await viewModel.fetchUser()
            }
        }
    }
}

// Card-style action row for profile actions
struct ProfileActionRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let titleColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(titleColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

struct PatientHistoryItem: Identifiable {
    let id = UUID()
    let date: Date
    let type: MeasurementType
    let title: String
    let subtitle: String
    
    enum MeasurementType {
        case transplant
        case fuchs
        case keratoconus
        
        var icon: String {
            switch self {
            case .transplant: return "eye.fill"
            case .fuchs: return "eye.circle.fill"
            case .keratoconus: return "eye.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .transplant: return .blue
            case .fuchs: return .green
            case .keratoconus: return .orange
            }
        }
    }
}

struct ChangePasswordView: View {
    @Binding var isPresented: Bool
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isChangingPassword: Bool
    @Binding var showSuccess: Bool
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("current_password".localized(), text: $currentPassword)
                    SecureField("new_password".localized(), text: $newPassword)
                    SecureField("confirm_new_password".localized(), text: $confirmPassword)
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("change_password".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized()) {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save".localized()) {
                        Task {
                            await changePassword()
                        }
                    }
                    .disabled(!isValid || isChangingPassword)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6
    }
    
    private func changePassword() async {
        guard isValid else { return }
        
        isChangingPassword = true
        showError = false
        
        do {
            try await viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            isPresented = false
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isChangingPassword = false
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocalizationManager.shared)
    }
}

struct GeneralPrivacyPolicyView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("privacy_policy_title".localized())
                        .font(.title2)
                        .fontWeight(.bold)
                        .id(currentLanguage)
                    
                    Text("last_updated".localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                        .id(currentLanguage)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("welcome_to_haute_vision_app".localized())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .id(currentLanguage)
                    Text("privacy_policy_intro".localized())
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(currentLanguage)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("information_we_collect".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("information_we_collect_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                        
                        Text("personal_information_we_collect".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("automatically_collected_information".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("automatically_collected_information_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("how_we_use_your_information".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("how_we_use_your_information_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("sharing_your_information".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("sharing_your_information_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("data_security".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("data_security_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("your_rights".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("your_rights_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("cookies_and_tracking".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("cookies_and_tracking_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("third_party_links".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("third_party_links_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("contact_us_privacy".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("contact_us_privacy_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey.hauteVisionOphthalmologyClinic.localized())
                            Text("5139 de Courtrai Avenue, Suite 311")
                            Text(LocalizedStringKey.montrealH3W0A9.localized())
                            Text("514-782-8282")
                            Text("admin@hautevision.com")
                        }
                        .font(.caption)
                        .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("changes_to_privacy_policy".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .id(currentLanguage)
                        
                        Text("changes_to_privacy_policy_desc".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("consent_to_privacy_policy".localized())
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                        
                        Text("thank_you_for_trusting".localized())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentLanguage)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("privacy_policy_title".localized())
        .navigationBarTitleDisplayMode(.inline)
        .id(currentLanguage)
    }
}
