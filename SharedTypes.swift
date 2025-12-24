import Foundation
import SwiftUI

// Shared enum for tracking OD and OS eyes
enum EyeType: String, Codable, CaseIterable, Identifiable {
    case OD = "OD (Right Eye)"
    case OS = "OS (Left Eye)"
    
    var id: String { self.rawValue }
    
    var shortName: String {
        switch self {
        case .OD: return "OD"
        case .OS: return "OS"
        }
    }
}

// Helper for displaying measurement values
struct SharedMeasurementValueView: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// Custom toggle view for eye selection
struct EyeToggleView: View {
    @Binding var selectedEye: EyeType
    
    var body: some View {
        VStack(spacing: 3) {
            Button {
                withAnimation {
                    selectedEye = (selectedEye == .OD ? .OS : .OD)
                }
            } label: {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.systemGray6))
                        // Active pill
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white)
                            .frame(width: (geometry.size.width / 2) - 2, height: geometry.size.height - 4)
                            .offset(x: selectedEye == .OD ? 2 : (geometry.size.width / 2))
                            .animation(.easeInOut(duration: 0.2), value: selectedEye)
                        // Icons
                        HStack(spacing: 0) {
                            Spacer()
                            Image(selectedEye == .OD ? "eye_OD" : "eye_closed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedEye == .OD ? .accentColor : .gray)
                            Image(selectedEye == .OS ? "eye_OS" : "eye_closed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedEye == .OS ? .accentColor : .gray)
                            Spacer()
                        }
                    }
                }
                .frame(height: 44)
                .frame(minWidth: 140, maxWidth: 200)
            }
        .accessibilityLabel("eye_selection".localized())
        .accessibilityValue(selectedEye == .OD ? "right_eye_selected".localized() : "left_eye_selected".localized())
        .accessibilityHint("double_tap_switch_eye".localized())
            .accessibilityAddTraits(.isButton)
            
            // Smaller, centered label below
            Text(selectedEye == .OD ? "right_eye".localized() : "left_eye".localized())
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// Custom eye toggle for data entry views with headline labels
struct DataEntryEyeToggleView: View {
    @Binding var selectedEye: EyeType
    
    var body: some View {
        VStack(spacing: 3) {
            Button {
                withAnimation {
                    selectedEye = (selectedEye == .OD ? .OS : .OD)
                }
            } label: {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.systemGray6))
                        // Active pill
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white)
                            .frame(width: (geometry.size.width / 2) - 2, height: geometry.size.height - 4)
                            .offset(x: selectedEye == .OD ? 2 : (geometry.size.width / 2))
                            .animation(.easeInOut(duration: 0.2), value: selectedEye)
                        // Icons
                        HStack(spacing: 0) {
                            Spacer()
                            Image(selectedEye == .OD ? "eye_OD" : "eye_closed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedEye == .OD ? .accentColor : .gray)
                            Image(selectedEye == .OS ? "eye_OS" : "eye_closed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedEye == .OS ? .accentColor : .gray)
                            Spacer()
                        }
                    }
                }
                .frame(height: 44)
                .frame(minWidth: 140, maxWidth: 200)
            }
        .accessibilityLabel("eye_selection".localized())
        .accessibilityValue(selectedEye == .OD ? "right_eye_selected".localized() : "left_eye_selected".localized())
        .accessibilityHint("double_tap_switch_eye".localized())
            .accessibilityAddTraits(.isButton)
            
            // Headline label below
            Text(selectedEye == .OD ? "right_eye".localized() : "left_eye".localized())
                .font(.headline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
} 
