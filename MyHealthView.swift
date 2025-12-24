import SwiftUI
import Foundation

struct MyHealthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    // Main content
                    VStack(spacing: 30) {
                        
                        // Enlarged Haute Vision logo
                        Image("HauteVision")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                            .padding(.top, 24)
        .accessibilityLabel("hautevision_logo".localized())
        .accessibilityHidden(true) // Decorative image
                        // Eye Conditions Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("my_health".localized())
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .foregroundColor(AppConstants.primaryBlue)
                                .id(currentLanguage) // Force re-render on language change
                                .accessibilityAddTraits(.isHeader)
                            Text("eye_conditions".localized())
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .id(currentLanguage) // Force re-render on language change
                            // Corneal Health
                            NavigationLink(destination: CornealHealthView()) {
                                ConditionRow(iconName: "Cornea_icon", iconColor: .blue, title: "corneal_health".localized())
                                    .id(currentLanguage) // Force re-render on language change
                            }
                            .id("corneal_health_\(currentLanguage)") // Force NavigationLink re-render on language change
                            .accessibilityLabel("Corneal Health")
                            .accessibilityHint("Tap to view corneal health information and measurements")
                            // Glaucoma
                            NavigationLink(destination: GlaucomaView()) {
                                ConditionRow(iconName: "Glaucoma_icon", iconColor: .green, title: "glaucoma".localized())
                                    .id(currentLanguage) // Force re-render on language change
                            }
                            .id("glaucoma_\(currentLanguage)") // Force NavigationLink re-render on language change
                            // Retinal Injections
                            NavigationLink(destination: RetinaInjectionView()) {
                                ConditionRow(iconName: "Retina_icon", iconColor: .purple, title: "retinal_injections".localized())
                                    .id(currentLanguage) // Force re-render on language change
                            }
                            .id("retinal_injections_\(currentLanguage)") // Force NavigationLink re-render on language change
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    Spacer()
                    // Bottom links
                    HStack(spacing: 24) {
                        NavigationLink(destination: AboutUsView()) {
                            Text("about".localized())
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .id(currentLanguage) // Force re-render on language change
                        }
                        .id("about_\(currentLanguage)") // Force NavigationLink re-render on language change
                        NavigationLink(destination: GeneralPrivacyPolicyView()) {
                            Text("privacy_policy".localized())
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .id(currentLanguage) // Force re-render on language change
                        }
                        .id("privacy_policy_\(currentLanguage)") // Force NavigationLink re-render on language change
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Condition Row View
struct ConditionRow: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let iconName: String
    let iconColor: Color
    let title: String
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Group {
                if UIImage(named: iconName) != nil {
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(iconColor)
                } else {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }
            }
            .frame(width: 40, height: 40)
            // Removed background and clipShape
            VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                    .foregroundColor(.primary)
                    .id(currentLanguage) // Force re-render on language change
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Placeholder Detail View
struct PlaceholderDetailView: View {
    let title: String
    let message: String = "coming_soon".localized()
    let description: String = "under_development".localized()
    
    var body: some View {
        VStack(spacing: 24) {
            // Use custom icon if available
            if let iconName = iconForTitle(title) {
                if UIImage(named: iconName) != nil {
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.top, 50)
                } else {
                    Image(systemName: "eye")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                        .padding(.top, 50)
                }
            } else {
                Image(systemName: "eye")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
                    .padding(.top, 50)
            }
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(.darkText))
            
            Text(message)
                .font(.title2)
                .foregroundColor(.gray)
            
            Text(description)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.darkGray))
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .navigationTitle(title)
        .background(Color.white)
    }
    
    // Helper function to determine icon based on title
    private func iconForTitle(_ title: String) -> String? {
        switch title.lowercased() {
        case "corneal health": return "Cornea_icon"
        case "glaucoma": return "Glaucoma_icon"
        case "retinal injections": return "Retina_icon"
        case "about us": return "info.circle"
        default: return nil
        }
    }
}

// Corneal Health View
struct CornealHealthView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedCondition = CornealCondition.dryEye
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Condition Selector
            ConditionPicker(selectedCondition: $selectedCondition)
                .padding(.horizontal)
                .padding(.top)
            
            // Content based on selected condition
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedCondition {
                    case .dryEye:
                        DryEyeView()
                    case .fuchs:
                        FuchsDystrophyView()
                    case .transplant:
                        CornealTransplantView()
                    case .keratoconus:
                        KeratoconusView()
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("corneal_health".localized())
            .id(currentLanguage) // Force re-render on language change
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white)
    }
}

// Corneal Condition Enum
enum CornealCondition: String, CaseIterable, Identifiable {
    case dryEye = "dry_eye"
    case fuchs = "fuchs_dystrophy"
    case transplant = "corneal_transplant"
    case keratoconus = "keratoconus"
    
    var id: String { self.rawValue }
    
    var localizedTitle: String {
        switch self {
        case .dryEye:
            return "dry_eye".localized()
        case .fuchs:
            return "fuchs_dystrophy".localized()
        case .transplant:
            return "corneal_transplant".localized()
        case .keratoconus:
            return "keratoconus".localized()
        }
    }
}

// Condition Picker View
struct ConditionPicker: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var selectedCondition: CornealCondition
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }

    var body: some View {
        ScrollViewReader { proxy in
            let arrowWidth: CGFloat = 28 // font size + padding
            let arrowSpacing: CGFloat = 16 // .padding(.trailing/leading, 16)
            let edgeSpacer = arrowWidth + arrowSpacing
            HStack(spacing: 0) {
                // Left arrow
                Button(action: {
                    if let currentIndex = CornealCondition.allCases.firstIndex(of: selectedCondition),
                       currentIndex > 0 {
                        let newIndex = currentIndex - 1
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedCondition = CornealCondition.allCases[newIndex]
                            proxy.scrollTo(selectedCondition, anchor: .center)
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .opacity(CornealCondition.allCases.first == selectedCondition ? 0.2 : 0.7)
                }
                .disabled(CornealCondition.allCases.first == selectedCondition)
                .padding(.trailing, 16)

                // Scrollable pills with fade
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Color.clear.frame(width: edgeSpacer)
                            ForEach(CornealCondition.allCases, id: \.self) { condition in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedCondition = condition
                                        proxy.scrollTo(condition, anchor: .center)
                                    }
                                }) {
                                    Text(condition.localizedTitle)
                                        .font(.subheadline)
                                        .fontWeight(selectedCondition == condition ? .semibold : .regular)
                                        .foregroundColor(selectedCondition == condition ? .white : Color(red: 68/255, green: 55/255, blue: 235/255))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedCondition == condition ? Color(red: 68/255, green: 55/255, blue: 235/255) : Color(red: 68/255, green: 55/255, blue: 235/255).opacity(0.08))
                                        )
                                        .animation(.easeInOut(duration: 0.25), value: selectedCondition)
                                        .scaleEffect(selectedCondition == condition ? 1.08 : 1.0)
                                        .opacity(selectedCondition == condition ? 1.0 : 0.85)
                                        .id(currentLanguage) // Force re-render on language change
                                }
                                .id(condition)
                            }
                            Color.clear.frame(width: edgeSpacer)
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(height: 48)
                    .onChange(of: selectedCondition) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(selectedCondition, anchor: .center)
                        }
                    }
                    // Left and right fade overlays
                    HStack {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white, location: 0),
                                .init(color: Color.white.opacity(0), location: 1)
                            ]),
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: 32)
                        Spacer()
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0), location: 0),
                                .init(color: Color.white, location: 1)
                            ]),
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: 32)
                    }
                    .allowsHitTesting(false)
                }
                .frame(height: 48)
                // Right arrow
                Button(action: {
                    if let currentIndex = CornealCondition.allCases.firstIndex(of: selectedCondition),
                       currentIndex < CornealCondition.allCases.count - 1 {
                        let newIndex = currentIndex + 1
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedCondition = CornealCondition.allCases[newIndex]
                            proxy.scrollTo(selectedCondition, anchor: .center)
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .opacity(CornealCondition.allCases.last == selectedCondition ? 0.2 : 0.7)
                }
                .disabled(CornealCondition.allCases.last == selectedCondition)
                .padding(.leading, 16)
            }
            .padding(.vertical, 4)
        }
        .frame(height: 56)
        .padding(.horizontal)
    }
}

// Condition Button
struct ConditionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct MyHealthView_Previews: PreviewProvider {
    static var previews: some View {
        MyHealthView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocalizationManager.shared)
    }
}
