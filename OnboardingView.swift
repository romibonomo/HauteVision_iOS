//
//  OnboardingView.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-03-09.
//

import SwiftUI

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
}

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var currentPage = 0
    @State private var hasAcceptedPrivacyPolicy = false
    @State private var isConsentChecked = false
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to Haute Vision",
            subtitle: "Excellence in Specialized Eye Care",
            imageName: "eye.circle.fill",
            description: "Track your eye health journey with personalized care and professional monitoring."
        ),
        OnboardingPage(
            title: "Data Visualization",
            subtitle: "See Your Progress",
            imageName: "chart.line.uptrend.xyaxis.circle.fill",
            description: "Monitor your eye health conditions with interactive charts and trends over time."
        ),
        OnboardingPage(
            title: "Smart Reminders",
            subtitle: "Never Miss Your Medications",
            imageName: "bell.badge.circle.fill",
            description: "Set custom reminders for medications and appointments to stay on top of your treatment."
        ),
        OnboardingPage(
            title: "App Policy",
            subtitle: "Privacy Terms and Conditions",
            imageName: "lock.shield.fill",
            description: ""
        )
    ]
    
    var body: some View {
        ZStack {
            backgroundGradient
            welcomeBackground
            mainContent
        }
    }
        
    private var welcomeBackground: some View {
        Group {
            if currentPage == 0 {
                Image("welcome")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay(welcomeOverlay)
            }
        }
        .ignoresSafeArea()
    }
    
    private var welcomeOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.3),
                Color.black.opacity(0.1),
                Color.clear,
                Color.black.opacity(0.2)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white,
                Color(red: 0.98, green: 0.96, blue: 0.99).opacity(0.3),
                Color(red: 0.95, green: 0.93, blue: 0.98).opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            pageContent
            navigationControls
        }
        .ignoresSafeArea()
    }
    
    private var pageContent: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<onboardingPages.count, id: \.self) { index in
                if index == onboardingPages.count - 1 {
                    PrivacyPolicyPageView(
                        page: onboardingPages[index],
                        isConsentChecked: $isConsentChecked,
                        hasAcceptedPrivacyPolicy: $hasAcceptedPrivacyPolicy
                    )
                    .tag(index)
                } else {
                    OnboardingPageView(page: onboardingPages[index], isActive: currentPage == index, pageIndex: index)
                        .tag(index)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
    }
    
    private var navigationControls: some View {
        VStack(spacing: 24) {
            getStartedButton
            pageIndicators
            navigationButtons
        }
    }
    
    private var getStartedButton: some View {
        Group {
            if currentPage == onboardingPages.count - 1 {
                Button(LocalizedStringKey.getStarted.localized()) {
                    if hasAcceptedPrivacyPolicy {
                        viewModel.completeOnboarding()
                        showOnboarding = false
                    }
                }
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(buttonBackground)
                .shadow(color: hasAcceptedPrivacyPolicy ? Color(red: 0.27, green: 0.22, blue: 0.92).opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                .scaleEffect(hasAcceptedPrivacyPolicy ? 1.0 : 0.98)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasAcceptedPrivacyPolicy)
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .disabled(!hasAcceptedPrivacyPolicy)
            }
        }
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(
                hasAcceptedPrivacyPolicy
                ? LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.27, green: 0.22, blue: 0.92),
                        Color(red: 0.35, green: 0.30, blue: 0.95)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                : LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    private var pageIndicators: some View {
        HStack(spacing: 10) {
            ForEach(0..<onboardingPages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color(red: 0.27, green: 0.22, blue: 0.92) : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.top, 24)
    }
    
    private var navigationButtons: some View {
        HStack {
            backButton
            Spacer()
            nextButton
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
    
    private var backButton: some View {
        Group {
            if currentPage > 0 {
                Button(LocalizedStringKey.back.localized()) {
                    withAnimation {
                        currentPage -= 1
                    }
                }
                .foregroundColor(Color(red: 0.27, green: 0.22, blue: 0.92))
                .font(.system(size: 17, weight: .medium, design: .default))
            }
        }
    }
    
    private var nextButton: some View {
        Group {
            if currentPage < onboardingPages.count - 1 {
                Button(LocalizedStringKey.next.localized()) {
                    withAnimation {
                        currentPage += 1
                    }
                }
                .foregroundColor(Color(red: 0.27, green: 0.22, blue: 0.92))
                .font(.system(size: 17, weight: .medium, design: .default))
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    let pageIndex: Int
    @State private var iconScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        mainContent
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    // Reset and animate when page becomes active
                    iconScale = 0.8
                    textOpacity = 0.0
                    
                    // Trigger animations with slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        iconScale = 1.0
                        textOpacity = 1.0
                    }
                }
            }
            .onAppear {
                if isActive {
                    iconScale = 1.0
                    textOpacity = 1.0
                }
            }
    }
    
    // MARK: - Computed Properties
    
    var mainContent: some View {
        VStack(spacing: 0) {
            if pageIndex == 0 {
                // Custom layout for first page - text on the left side
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        headerSection
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                // Original centered layout for other pages
                VStack(spacing: 0) {
                    Spacer()
                    headerSection
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
    }
    
    var headerSection: some View {
        VStack(spacing: 40) {
            if pageIndex == 0 {
                // First page only shows text content (no large icon)
                textContent
            } else {
                // Other pages show icon and text
                animatedIcon
                textContent
            }
        }
    }
    
    var animatedIcon: some View {
        Image(systemName: page.imageName)
            .font(.system(size: 80, weight: .light))
            .foregroundColor(pageIndex == 0 ? .white : Color(red: 0.27, green: 0.22, blue: 0.92))
            .frame(height: 120)
            .scaleEffect(iconScale)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: iconScale)
    }
    
    var textContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if pageIndex == 0 {
                
                // Custom layout for first page to match the image
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey.welcomeTo.localized())
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.black)
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: textOpacity)
                        .padding(.top, 300)
                        .padding(.bottom, -48)
                    
                    Image("HauteVision")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 170)
                        .padding(.bottom, 8)
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: textOpacity)
                    
                    Text(LocalizedStringKey.specializedEyeCare.localized())
                        .font(.system(size: 26, weight: .medium, design: .default))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(0.6), value: textOpacity)
                        .padding(.bottom, -8)
                    
                    Text(LocalizedStringKey.atTheForefrontOfOphthalmology.localized())
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(-8)
                        .frame(maxWidth: 200, alignment: .leading)
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(0.7), value: textOpacity)
                }
            } else {
                // Original layout for other pages
                VStack(spacing: 24) {
                    titleText
                    subtitleText
                    descriptionText
                }
            }
        }
    }
    
    var titleText: some View {
        Text(page.title)
            .font(.system(size: 34, weight: .bold, design: .default))
            .foregroundColor(pageIndex == 0 ? .white : .black)
            .multilineTextAlignment(.center)
            .opacity(textOpacity)
            .animation(.easeInOut(duration: 0.8).delay(0.2), value: textOpacity)
    }
    
    var subtitleText: some View {
        Text(page.subtitle)
            .font(.system(size: 18, weight: .medium, design: .default))
            .foregroundColor(pageIndex == 0 ? .white.opacity(0.9) : Color(red: 0.27, green: 0.22, blue: 0.92))
            .multilineTextAlignment(.center)
            .opacity(textOpacity)
            .animation(.easeInOut(duration: 0.8).delay(0.4), value: textOpacity)
    }
    
    var descriptionText: some View {
        Text(page.description)
            .font(.system(size: 16, weight: .regular, design: .default))
            .foregroundColor(pageIndex == 0 ? .white.opacity(0.8) : .gray)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .lineSpacing(2)
            .padding(.horizontal, 48)
            .opacity(textOpacity)
            .animation(.easeInOut(duration: 0.8).delay(0.6), value: textOpacity)
    }
}

struct PrivacyPolicyPageView: View {
    let page: OnboardingPage
    @Binding var isConsentChecked: Bool
    @Binding var hasAcceptedPrivacyPolicy: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                privacyContent
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var headerSection: some View {
        VStack(spacing: 32) {
            Image(systemName: page.imageName)
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.27, green: 0.22, blue: 0.92))
                .frame(height: 60)
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .foregroundColor(Color(red: 0.27, green: 0.22, blue: 0.92))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 40)
    }
    
    var privacyContent: some View {
        VStack(alignment: .leading, spacing: 36) {
            introductionSection
            policySections
            consentSection
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 40)
    }
    
    var introductionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey.thankYouForInstalling.localized())
                .font(.system(size: 20, weight: .semibold, design: .default))
                .foregroundColor(.black)
            
            Text(LocalizedStringKey.pleaseReviewAndAccept.localized())
                .font(.system(size: 17, weight: .medium, design: .default))
                .foregroundColor(.gray)
        }
    }
    
    var policySections: some View {
        VStack(alignment: .leading, spacing: 28) {
            ProfessionalPrivacySection(
                title: "Disclaimer",
                content: "Haute Vision is designed for informational, educational, and self-monitoring purposes only. It is not intended to diagnose, treat, cure, or prevent any medical condition. The app does not establish a doctor-patient relationship and is not a substitute for consultation with a licensed medical professional.\n\nThe app allows you to log test results, monitor trends over time, and note injection dates. It is designed for use by a single individual only. Any scores, results, or data presented in the app are based entirely on user-provided input. The app does not validate or correct input errors, and you are solely responsible for the accuracy of the information entered.\n\nThe app is not a medical device and should not be relied on for clinical decision-making. Always seek advice from your physician or a licensed eye care provider for any medical concerns, including changes to your vision or health status."
            )
            
            ProfessionalPrivacySection(
                title: "Data Storage & Privacy",
                content: "Haute Vision stores your login credentials and profile name securely using Firebase, a trusted third-party Googlecloud service. This allows us to provide account-based access and support basic personalization features.\n\nAll health-related information you enter—such as test results, injection dates, and personal notes—is stored locally on your device. The app does not transmit this personal health data to any external network or server.\n\nThis means:\n• Only you, or someone with access to your smartphone, can view your health entries.\n• You are solely responsible for maintaining the privacy and security of your device and the information stored on it."
            )
            
            ProfessionalPrivacySection(
                title: "Liability & Warranty",
                content: "Haute Vision is provided to help you track your personal health information more efficiently. However, its use is entirely at your own discretion. The app may contain errors, bugs, or malfunctions, and uninterrupted service is not guaranteed.\n\nShould you encounter a problem, you may contact us in writing within the first 30 days of use, including a detailed explanation. If we are able to reproduce the issue and determine it to be a technical fault, we will attempt to address it within a reasonable timeframe.\n\nYou may always choose to log your health information using other methods, such as pen and paper."
            )
            
            ProfessionalPrivacySection(
                title: "Consent",
                content: "By continuing, you agree to Haute Vision's Terms & Conditions and Privacy Policy."
            )
        }
    }
    
    var consentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider()
                .padding(.vertical, 12)
            
            HStack(alignment: .top, spacing: 16) {
                Button(action: {
                    isConsentChecked.toggle()
                    if isConsentChecked {
                        hasAcceptedPrivacyPolicy = true
                    } else {
                        hasAcceptedPrivacyPolicy = false
                    }
                }) {
                    Image(systemName: isConsentChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22))
                        .foregroundColor(isConsentChecked ? Color(red: 0.27, green: 0.22, blue: 0.92) : .gray)
                }
                .padding(.top, 2)
                
                Text(LocalizedStringKey.iConsentToHauteVision.localized())
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1)
            }
        }
    }
}

struct ProfessionalPrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundColor(.black)
            
            Text(content)
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.gray)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(AuthViewModel())
}
