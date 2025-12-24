//
//  ContentView.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-03-09.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showOnboarding = false
    
    var body: some View {
        ErrorBoundary {
            NavigationView {
                Group {
                    if showOnboarding {
                        // Show onboarding on first launch
                        OnboardingView(showOnboarding: $showOnboarding)
                            .environmentObject(localizationManager)
                    } else if viewModel.userSession != nil {
                        // Patient view
                        MainTabView()
                            .environmentObject(localizationManager)
                    } else {
                        // Not logged in
                        LoginView()
                            .environmentObject(localizationManager)
                    }
                }
            }
        }
        .onAppear {
            // Check if onboarding has been completed
            if !viewModel.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
