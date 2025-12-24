import SwiftUI

// MARK: - Base Data Entry View
struct BaseDataEntryView<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let title: String
    let isEditing: Bool
    let onSave: () -> Void
    let onCancel: (() -> Void)?
    let content: Content
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showingEditWarning = false
    @State private var showingDatePicker = false
    @State private var activeTooltip: SharedTooltipType? = nil
    
    init(
        title: String,
        isEditing: Bool,
        onSave: @escaping () -> Void,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isEditing = isEditing
        self.onSave = onSave
        self.onCancel = onCancel
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: AppConstants.cardSpacing) {
                    // Header
                    VStack(spacing: AppConstants.smallPadding) {
                        Text(title)
                            .font(AppConstants.titleFont)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        if isEditing {
                            Text(LocalizedStringKey.editingExistingMeasurement.localized())
                                .font(AppConstants.subheadlineFont)
                                .foregroundColor(AppConstants.textGray)
                        }
                    }
                    .padding(.top, AppConstants.smallPadding)
                    .padding(.horizontal, AppConstants.standardPadding)
                    
                    // Content
                    content
                        .padding(.horizontal, AppConstants.standardPadding)
                        .padding(.bottom, 100) // Space for bottom buttons
                }
            }
            
            // Bottom Action Buttons
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: AppConstants.standardPadding) {
                    // Cancel Button
                    Button(action: handleCancel) {
                        Text(LocalizedStringKey.cancel.localized())
                            .font(AppConstants.bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(AppConstants.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppConstants.standardPadding)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius)
                                    .stroke(AppConstants.primaryBlue, lineWidth: 1)
                            )
                    }
                    .disabled(isSaving)
                    
                    // Save Button
                    Button(action: handleSave) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSaving ? LocalizedStrings.localizedString(for: "saving") : (isEditing ? LocalizedStrings.localizedString(for: "update") : LocalizedStrings.localizedString(for: "save")))
                                .font(AppConstants.bodyFont)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.standardPadding)
                        .background(isSaving ? AppConstants.primaryBlue.opacity(0.6) : AppConstants.primaryBlue)
                        .cornerRadius(AppConstants.buttonCornerRadius)
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, AppConstants.standardPadding)
                .padding(.vertical, AppConstants.standardPadding)
                .background(Color(.systemBackground))
            }
        }
        .navigationBarHidden(true)
        .overlay(
            TooltipOverlay(tooltip: activeTooltip) {
                activeTooltip = nil
            }
        )
        .alert("Error", isPresented: $showingError) {
            Button(LocalizedStringKey.ok.localized()) {
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Edit Warning", isPresented: $showingEditWarning) {
            Button(LocalizedStrings.localizedString(for: "continue"), role: .destructive) {
                showingEditWarning = false
                performSave()
            }
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) {
                showingEditWarning = false
            }
        } message: {
            Text(LocalizedStringKey.editingThisMeasurementWillMark.localized())
        }
    }
    
    // MARK: - Helper Methods
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func showTooltip(_ tooltip: SharedTooltipType) {
        activeTooltip = tooltip
    }
    
    func hideTooltip() {
        activeTooltip = nil
    }
    
    private func handleSave() {
        if isEditing {
            showingEditWarning = true
        } else {
            performSave()
        }
    }
    
    private func performSave() {
        isSaving = true
        onSave()
        // Note: The calling view should handle setting isSaving back to false
    }
    
    private func handleCancel() {
        if let onCancel = onCancel {
            onCancel()
        } else {
            dismiss()
        }
    }
}

// MARK: - Shared Input Field Component
struct SharedInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let tooltip: SharedTooltipType?
    let onTooltipTap: (() -> Void)?
    let keyboardType: UIKeyboardType
    let isRequired: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        tooltip: SharedTooltipType? = nil,
        onTooltipTap: (() -> Void)? = nil,
        keyboardType: UIKeyboardType = .default,
        isRequired: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.tooltip = tooltip
        self.onTooltipTap = onTooltipTap
        self.keyboardType = keyboardType
        self.isRequired = isRequired
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
            HStack {
                Text(title)
                    .font(AppConstants.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if let _ = tooltip, let onTooltipTap = onTooltipTap {
                    Button(action: onTooltipTap) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppConstants.primaryBlue)
                            .font(.caption)
                    }
                    .accessibilityLabel("Show \(title) information")
                }
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .accessibilityLabel(title)
                .accessibilityValue(text.isEmpty ? "Empty" : text)
        }
    }
}

// MARK: - Shared Toggle Field Component
struct SharedToggleField: View {
    let title: String
    @Binding var isOn: Bool
    let tooltip: SharedTooltipType?
    let onTooltipTap: (() -> Void)?
    
    init(
        title: String,
        isOn: Binding<Bool>,
        tooltip: SharedTooltipType? = nil,
        onTooltipTap: (() -> Void)? = nil
    ) {
        self.title = title
        self._isOn = isOn
        self.tooltip = tooltip
        self.onTooltipTap = onTooltipTap
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(AppConstants.bodyFont)
                        .fontWeight(.medium)
                    
                    if let _ = tooltip, let onTooltipTap = onTooltipTap {
                        Button(action: onTooltipTap) {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppConstants.primaryBlue)
                                .font(.caption)
                        }
                        .accessibilityLabel("Show \(title) information")
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .accessibilityLabel(title)
                .accessibilityValue(isOn ? "On" : "Off")
        }
        .padding(.vertical, AppConstants.smallPadding)
    }
}

// MARK: - Shared Picker Field Component
struct SharedPickerField<T: CaseIterable & Hashable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    let tooltip: SharedTooltipType?
    let onTooltipTap: (() -> Void)?
    
    init(
        title: String,
        selection: Binding<T>,
        tooltip: SharedTooltipType? = nil,
        onTooltipTap: (() -> Void)? = nil
    ) {
        self.title = title
        self._selection = selection
        self.tooltip = tooltip
        self.onTooltipTap = onTooltipTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
            HStack {
                Text(title)
                    .font(AppConstants.bodyFont)
                    .fontWeight(.medium)
                
                if let _ = tooltip, let onTooltipTap = onTooltipTap {
                    Button(action: onTooltipTap) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppConstants.primaryBlue)
                            .font(.caption)
                    }
                    .accessibilityLabel("Show \(title) information")
                }
            }
            
            Picker(title, selection: $selection) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accessibilityLabel(title)
            .accessibilityValue(selection.rawValue)
        }
    }
}
