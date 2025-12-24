import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showingLanguageMenu = false
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            MyHealthView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(LocalizedStringKey.home.localized())
                }
                .tag(0)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text(LocalizedStringKey.profile.localized())
                }
                .tag(1)
            
            // Language Dropdown Tab - Empty view that shows language menu
            Color.clear
                .tabItem {
                    Image(systemName: "globe")
                    Text(localizationManager.currentLanguage == .english ? "EN" : "FR")
                }
                .tag(2)
        }
        .tint(AppConstants.primaryBlue)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 2 {
                // Show language menu when language tab is selected
                showingLanguageMenu = true
                // Immediately reset to previous tab to keep current view active
                selectedTab = previousTab
            } else if newValue != 2 {
                // Track the previous tab (only for non-language tabs)
                previousTab = newValue
            }
        }
        .confirmationDialog("Select Language", isPresented: $showingLanguageMenu) {
            Button(LocalizedStringKey.en.localized()) {
                localizationManager.setLanguage(.english)
            }
            Button(LocalizedStringKey.fr.localized()) {
                localizationManager.setLanguage(.french)
            }
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
        }
    }
}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocalizationManager.shared)
    }
}

