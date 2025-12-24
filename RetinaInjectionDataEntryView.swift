import SwiftUI
import FirebaseAuth

struct RetinaInjectionDataEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RetinaInjectionViewModel
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let selectedEye: EyeType
    let existingMeasurement: RetinaInjectionMeasurement? // For editing existing measurements
    
    @State private var date = Date()
    @State private var medication = ""
    @State private var isNewMedication = false
    @State private var vision = "20/40"
    @State private var crt = ""
    @State private var notes = ""
    @State private var reminderDate: Date? = nil
    @State private var showingReminderPicker = false
    @State private var showingDatePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showingEditWarning = false
    
    // Info tooltip state (single overlay)
    @State private var activeTooltip: TooltipType? = nil
    enum TooltipType { case medication, vision, crt, reminder }
    
    let visionOptions = ["20/20", "20/25", "20/30", "20/40", "20/50", "20/60", "20/80", "20/100", "20/200"]
    
    // Computed property to determine if we're editing
    private var isEditing: Bool {
        return existingMeasurement != nil
    }
    
    // Initializer for new measurements
    init(viewModel: RetinaInjectionViewModel, selectedEye: EyeType) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = nil
    }
    
    // Initializer for editing existing measurements
    init(viewModel: RetinaInjectionViewModel, selectedEye: EyeType, existingMeasurement: RetinaInjectionMeasurement) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = existingMeasurement
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Color.white
                    .frame(height: 120)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text(LocalizedStringKey.retinaInjection.localized())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        eyeSelector
                        dateTimeInlineRow
                        injectionCard
                        visionCard
                        reminderCard
                        notesCard
                        (
                            Text("*")
                                .bold()
                                .foregroundColor(.red)
                            + Text(" \(LocalizedStringKey.requiredField.localized())")
                                .font(.footnote)
                        .foregroundColor(.gray)
                        )
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                        .padding(.horizontal, localizationManager.currentLanguage == .french ? 8 : 0)
                        Spacer(minLength: 120)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 100)
                }
            }
            saveButton
            // Tooltip Overlay
            if let tooltip = activeTooltip {
                TooltipOverlay(type: tooltip) {
                    activeTooltip = nil
                }
            }
        }
        .navigationTitle(isEditing ? LocalizedStringKey.editInjection.localized() : LocalizedStringKey.addInjection.localized())
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizedStringKey.error.localized(), isPresented: $showingError) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(LocalizedStringKey.editInjectionWarning.localized(), isPresented: $showingEditWarning) {
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
            Button(LocalizedStringKey.continue.localized(), role: .destructive) {
                saveMeasurement()
            }
        } message: {
            Text(LocalizedStringKey.modifyExistingInjection.localized())
        }
        .onAppear {
            if let existingMeasurement = existingMeasurement {
                // Prefill the form with existing data
                date = existingMeasurement.date
                medication = existingMeasurement.medication
                isNewMedication = existingMeasurement.isNewMedication
                vision = existingMeasurement.vision
                crt = String(format: "%.0f", existingMeasurement.crt)
                notes = existingMeasurement.notes ?? ""
                reminderDate = existingMeasurement.reminderDate
            }
        }
        .sheet(isPresented: $showingReminderPicker) {
            VStack {
                DatePicker(LocalizedStringKey.reminderDate.localized(), selection: Binding(
                    get: { reminderDate ?? Date() },
                    set: { reminderDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.rawValue))
                Button(LocalizedStringKey.done.localized()) { showingReminderPicker = false }
                    .padding()
            }
            .presentationDetents([.medium])
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey.cancel.localized()) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey.save.localized()) { 
                    if isEditing {
                        showingEditWarning = true
                    } else {
                        saveMeasurement()
                    }
                }
            }
        }
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - Sectioned Subviews
    private var eyeSelector: some View {
        DataEntryEyeToggleView(selectedEye: .constant(selectedEye))
            .padding(.top, 8)
    }
    
    private var dateTimeInlineRow: some View {
        HStack(spacing: 10) {
            Spacer()
            Button(action: { showingDatePicker = true }) {
                HStack(spacing: 8) {
                    Text(dateFormatted)
                        .foregroundColor(.primary)
                        .font(.headline)
                    Text(timeFormatted)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
        .padding(.top, 8)
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker("Select Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.rawValue))
                    .padding()
                Button(LocalizedStringKey.done.localized()) { showingDatePicker = false }
                    .padding()
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private var injectionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.injectionDetailsTitle.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
            
            // New Medication Toggle
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(LocalizedStringKey.newMedicationQuestion.localized())
                        .foregroundColor(.accentColor)
                        .font(.headline)
                        .layoutPriority(1)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    HStack(spacing: 8) {
                        Button(action: { isNewMedication = false }) {
                            Text(LocalizedStringKey.no.localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(!isNewMedication ? .white : .accentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(!isNewMedication ? Color.accentColor : Color(.systemGray6))
                                .cornerRadius(14)
                        }
                        Button(action: { isNewMedication = true }) {
                            Text(LocalizedStringKey.yes.localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isNewMedication ? .white : .accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                                .background(isNewMedication ? Color.accentColor : Color(.systemGray6))
                                .cornerRadius(14)
                        }
                    }
                }
                HStack(spacing: 4) {
                    Text(LocalizedStringKey.firstTimeUsingMedication.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: { activeTooltip = .medication }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                            .padding(.vertical, 8)

                    }
                }
            }
            .padding(.vertical, 5)
            
            if isNewMedication {
                Divider()
                // Medication Name
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        (
                            Text(LocalizedStringKey.medicationName.localized())
                                .foregroundColor(.accentColor)
                            + Text(" *").foregroundColor(.red)
                        )
                        .font(.headline)
                        .layoutPriority(1)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        Spacer(minLength: 8)
                        TextField("e.g., Avastin", text: $medication)
                            .keyboardType(.default)
                            .multilineTextAlignment(.trailing)
                            .font(.subheadline)
                            .frame(minWidth: 70, maxWidth: 120)
                    }
                    HStack(spacing: 4) {
                        Text(LocalizedStringKey.injectionMedication.localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: { activeTooltip = .medication }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var visionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.visionMeasurementsTitle.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
            
            // Vision Section
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                        (
                            Text(LocalizedStringKey.bestCorrectedVision.localized())
                                .foregroundColor(.accentColor)
                            + Text(" *").foregroundColor(.red)
                        )
                    .font(.headline)
                    .layoutPriority(1)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    Spacer(minLength: 8)
                    Picker("", selection: $vision) {
                        ForEach(visionOptions, id: \.self) { v in
                            Text(v).tag(v)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                HStack(spacing: 4) {
                    Text(LocalizedStringKey.visualAcuityDescription.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: { activeTooltip = .vision }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 10)
            Divider()
            
            // CRT Section
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                        (
                            Text(LocalizedStringKey.centralRetinalThicknessTitle.localized())
                                .foregroundColor(.accentColor)
                            + Text(" *").foregroundColor(.red)
                        )
                    .font(.headline)
                    .layoutPriority(1)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    Spacer(minLength: 8)
                    TextField("e.g. 250", text: $crt)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.subheadline)
                        .frame(minWidth: 70, maxWidth: 120)
                    Text("μm")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                HStack(spacing: 4) {
                    Text(LocalizedStringKey.crtMeasurementDescription.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: { activeTooltip = .crt }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.followUpReminderTitle.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    (
                        Text(LocalizedStringKey.setReminder.localized())
                            .foregroundColor(.accentColor)
                    )
                    .font(.headline)
                    .layoutPriority(1)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    Spacer(minLength: 8)
                    if reminderDate != nil {
                        Button(LocalizedStringKey.clear.localized()) {
                            reminderDate = nil
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    } else {
                        Button(LocalizedStringKey.set.localized()) {
                            showingReminderPicker = true
                        }
                        .foregroundColor(.blue)
                        .font(.caption)
                    }
                }
                HStack(spacing: 4) {
                    if let appointmentDate = reminderDate {
                        Text("\(LocalizedStringKey.nextAppointmentColon.localized()) \(formattedDate(appointmentDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text(LocalizedStringKey.followUpAppointment.localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Button(action: { activeTooltip = .reminder }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.notesTitle.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                if notes.isEmpty {
                    Text(LocalizedStringKey.optionalNotesRetina.localized())
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var saveButton: some View {
        VStack {
            Button(action: {
                if isEditing {
                    showingEditWarning = true
                } else {
                    saveMeasurement()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text(isEditing ? LocalizedStringKey.updateMeasurement.localized() : LocalizedStringKey.saveMeasurement.localized())
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
                .background(isValid ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(22)
                .shadow(color: isValid ? Color.accentColor.opacity(0.18) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!isValid)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Tooltip Overlay
    @ViewBuilder
    private func TooltipOverlay(type: TooltipType, onDismiss: @escaping () -> Void) -> some View {
        ZStack {
            Color.white.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack {
                Spacer()
                VStack(alignment: .leading) {
                    HStack {
                        Text(tooltipTitle(for: type))
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.accentColor.opacity(0.8))
                        }
                        .padding()
                    }
                    TooltipTextView(for: type)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.1), radius: 8)
                .padding(.horizontal, 5)
                Spacer()
            }
        }
    }
    
    // MARK: - Tooltip Texts
    @ViewBuilder
    private func TooltipTextView(for type: TooltipType) -> some View {
        switch type {
        case .medication:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.medicationUsedForInjection.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.newMedicationsShouldBeTracked.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .vision:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.bestVisionAchievable.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.lowerNumbersIndicateBetter.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .crt:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.highCrtValuesMayIndicate.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.normalRangeCrt.localized())
                    .font(.caption)
                    .foregroundColor(Color.green)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .reminder:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.setReminderNextAppointment.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.regularMonitoringEssential.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    private func tooltipTitle(for type: TooltipType) -> String {
        switch type {
        case .medication: return LocalizedStringKey.medicationTooltip.localized()
        case .vision: return LocalizedStringKey.bestCorrectedVision.localized()
        case .crt: return LocalizedStringKey.thicknessCentralRetinaTooltip.localized()
        case .reminder: return LocalizedStringKey.followUpReminderTitle.localized()
        }
    }
    
    // MARK: - Helper Properties
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var isValid: Bool {
        guard let crtValue = Double(crt) else { return false }
        let medicationValid = !isNewMedication || (isNewMedication && !medication.isEmpty)
        return medicationValid && !vision.isEmpty && crtValue > 0
    }
    
    private func saveMeasurement() {
        guard let crtValue = Double(crt) else {
            errorMessage = LocalizedStringKey.pleaseEnterValidCrt.localized()
            showingError = true
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedStringKey.mustBeLoggedInAdd.localized()
            showingError = true
            return
        }
        
        if isEditing {
            // Update existing measurement
            guard let existingMeasurement = existingMeasurement else { return }
            
            let updatedMeasurement = RetinaInjectionMeasurement(
                id: existingMeasurement.id,
                userId: existingMeasurement.userId,
                date: date,
                eye: selectedEye,
                medication: medication,
                isNewMedication: isNewMedication,
                vision: vision,
                crt: crtValue,
                notes: notes.isEmpty ? nil : notes,
                reminderDate: reminderDate,
                edited: true
            )
            
            isSaving = true
            Task {
                do {
                    // First delete the old measurement
                    try await viewModel.deleteMeasurement(existingMeasurement)
                    // Then add the updated measurement
                    try await viewModel.addMeasurement(updatedMeasurement)
                    // Force immediate UI refresh by directly updating the measurements array
                    await MainActor.run {
                        // Trigger a UI refresh by temporarily clearing and re-adding the measurements
                        let currentMeasurements = viewModel.measurements
                        viewModel.measurements = []
                        DispatchQueue.main.async {
                            viewModel.measurements = currentMeasurements
                        }
                        isSaving = false
                    }
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        isSaving = false
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        } else {
            // Create new measurement
            let measurement = RetinaInjectionMeasurement(
                userId: userId,
                date: date,
                eye: selectedEye,
                medication: medication,
                isNewMedication: isNewMedication,
                vision: vision,
                crt: crtValue,
                notes: notes.isEmpty ? nil : notes,
                reminderDate: reminderDate,
                edited: nil
            )
            
            isSaving = true
            Task {
                do {
                    try await viewModel.addMeasurement(measurement)
                    // Force UI refresh by updating the published properties
                    await MainActor.run {
                        // Trigger a UI refresh by temporarily clearing and re-adding the measurements
                        let currentMeasurements = viewModel.measurements
                        viewModel.measurements = []
                        DispatchQueue.main.async {
                            viewModel.measurements = currentMeasurements
                        }
                        isSaving = false
                    }
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        isSaving = false
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: localizationManager.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        RetinaInjectionDataEntryView(
            viewModel: RetinaInjectionViewModel(),
            selectedEye: .OD
        )
    }
} 
