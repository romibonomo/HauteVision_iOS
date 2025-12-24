import SwiftUI
import FirebaseAuth
import UserNotifications

// Add enum for frequency options
enum SteroidFrequency: String, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case other = "Other"
    
    var numericValue: Double {
        switch self {
        case .none: return 0.0
        case .daily: return 1.0
        case .weekly: return 0.25
        case .other: return 0.0
        }
    }
    
    var displayName: String {
        switch self {
        case .none:
            return LocalizedStringKey.noRegimen.localized()
        case .daily:
            return LocalizedStringKey.daily.localized()
        case .weekly:
            return LocalizedStringKey.weekly.localized()
        case .other:
            return LocalizedStringKey.customFrequency.localized()
        }
    }
}

// Add DayOfWeek enum
enum DayOfWeek: String, CaseIterable, Identifiable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    
    var id: String { self.rawValue }
    var short: String {
        String(self.rawValue.prefix(3))
    }
}

enum MedicationType: CaseIterable {
    case pills, drops, injection
}

enum Frequency: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .daily:
            return LocalizedStringKey.daily.localized()
        case .weekly:
            return LocalizedStringKey.weekly.localized()
        case .monthly:
            return LocalizedStringKey.monthly.localized()
        case .other:
            return LocalizedStringKey.customFrequency.localized()
        }
    }
}

struct MedicationReminder {
    var startDate: Date
    var frequency: Frequency
    var customFrequency: String?
    var time: Date
    var isEnabled: Bool
}

enum TooltipType { case ecd, pachymetry, iop, regraft }

// Custom repeat unit for native-style picker
enum CustomRepeatUnit: String, CaseIterable, Identifiable {
    case day = "Day", week = "Week", month = "Month", hour = "Hour"
    var id: String { rawValue }
    var displayName: String { rawValue + (self == .hour ? "" : "s") }
    var timeInterval: TimeInterval {
        switch self {
        case .day: return 86400
        case .week: return 604800
        case .month: return 2629746 // average month in seconds
        case .hour: return 3600
        }
    }
}

struct CornealTransplantDataEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @ObservedObject var viewModel: CornealTransplantViewModel
    let selectedEye: EyeType
    let existingMeasurement: TransplantMeasurement? // For editing existing measurements
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    @State private var date = Date()
    @State private var ecd = ""
    @State private var pachymetry = ""
    @State private var medicationName: String = ""
    @State private var selectedFrequency: Frequency = .daily
    @State private var customRepeatValue: Int = 1
    @State private var customRepeatUnit: CustomRepeatUnit = .day
    @State private var isRegraft = false
    @State private var notes = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showGuidelines = false
    @State private var iop = ""
    @State private var showingInfo: TooltipType?
    @State private var showingDatePicker = false
    @State private var activeTooltip: TooltipType?
    @State private var showingEditWarning = false
    
    // Computed property to determine if we're editing
    private var isEditing: Bool {
        return existingMeasurement != nil
    }
    
    // Initializer for new measurements
    init(viewModel: CornealTransplantViewModel, selectedEye: EyeType) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = nil
    }
    
    // Initializer for editing existing measurements
    init(viewModel: CornealTransplantViewModel, selectedEye: EyeType, existingMeasurement: TransplantMeasurement) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = existingMeasurement
    }
    
    // Medication section state
    @State private var isTakingNewMedication: Bool = false
    @State private var selectedMedicationType: MedicationType?
    @State private var medicationTime: Date = Date()
    @State private var medicationReminderEnabled: Bool = false
    @State private var medicationReminderDate: Date = Date()
    @State private var medicationReminder = MedicationReminder(
        startDate: Date(),
        frequency: .daily,
        customFrequency: nil,
        time: Date(),
        isEnabled: false
    )
    @State private var showingReminderPicker = false
    
    // Helper for day-of-week selection
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    @State private var showRepeatPicker = false
    @State private var selectedRepeatDays: Set<Int> = [] // 0=Sunday, 6=Saturday
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Color.white
                    .frame(height: 120)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text(LocalizedStringKey.cornealTransplant.localized())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        DataEntryEyeToggleView(selectedEye: .constant(selectedEye))
                            .padding(.top, 8)
                        dateTimeInlineRow
                        measurementsCard
                        medicationAndProceduresCard
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
                        Spacer(minLength: 120)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    .padding(.horizontal, 16)
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
            if let infoType = showingInfo {
                TooltipOverlay(type: infoType) { showingInfo = nil }
            }
        }
        .navigationTitle(isEditing ? LocalizedStringKey.editMeasurement.localized() : LocalizedStringKey.addMeasurement.localized())
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizedStringKey.error.localized(), isPresented: $showingError) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(LocalizedStringKey.editMeasurementWarning.localized(), isPresented: $showingEditWarning) {
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
            Button(LocalizedStringKey.continueAction.localized(), role: .destructive) {
                saveMeasurement()
            }
        } message: {
            Text(LocalizedStringKey.editMeasurementMessage.localized())
        }
        .onAppear {
            if let existingMeasurement = existingMeasurement {
                // Prefill the form with existing data
                date = existingMeasurement.date
                ecd = String(format: "%.0f", existingMeasurement.ecd)
                pachymetry = String(existingMeasurement.pachymetry)
                iop = String(format: "%.1f", existingMeasurement.iop)
                isRegraft = existingMeasurement.isRegraft
                medicationName = existingMeasurement.medicationName ?? ""
                notes = existingMeasurement.notes ?? ""
            }
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
        .sheet(isPresented: $showGuidelines) {
            MonitoringGuidelinesPopover()
        }
        .sheet(isPresented: $showingReminderPicker) {
            ReminderPickerView(reminder: $medicationReminder)
        }
        // Add .onChange handlers for reminder changes
        .onChange(of: medicationReminder.isEnabled) { enabled, _ in
            if !enabled {
                cancelMedicationReminder()
            } else {
                scheduleMedicationReminder()
            }
        }
        .onChange(of: medicationReminder.startDate) { _, _ in
            if medicationReminder.isEnabled {
                updateMedicationReminder()
            }
        }
        .onChange(of: medicationReminder.frequency) { _, _ in
            if medicationReminder.isEnabled {
                updateMedicationReminder()
            }
        }
        .onChange(of: customRepeatValue) { _, _ in
            if medicationReminder.isEnabled && medicationReminder.frequency == .other {
                updateMedicationReminder()
            }
        }
        .onChange(of: customRepeatUnit) { _, _ in
            if medicationReminder.isEnabled && medicationReminder.frequency == .other {
                updateMedicationReminder()
            }
        }
        .id(currentLanguage) // Force re-render on language change
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
                    .padding()
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    private var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Title
            Text(LocalizedStringKey.measurements.localized())
                .font(.title2).fontWeight(.bold)
                .padding(.bottom, 4)
            MeasurementRowModern(
                label: LocalizedStringKey.specularMicroscopy.localized(),
                value: $ecd,
                placeholder: LocalizedStringKey.ecdPlaceholder.localized(),
                unit: LocalizedStrings.localizedString(for: LocalizedStringKey.cellsPerMm2),
                isNumber: true,
                description: LocalizedStringKey.ecdDescriptionShort.localized(),
                infoAction: { showingInfo = .ecd },
                isRequired: true
            )
            Divider()
            MeasurementRowModern(
                label: LocalizedStringKey.cornealThickness.localized(),
                value: $pachymetry,
                placeholder: LocalizedStringKey.pachymetryPlaceholder.localized(),
                unit: LocalizedStrings.localizedString(for: LocalizedStringKey.micrometers),
                isNumber: true,
                description: LocalizedStringKey.pachymetryDescriptionShort.localized(),
                infoAction: { showingInfo = .pachymetry },
                isRequired: true
            )
            Divider()
            MeasurementRowModern(
                label: LocalizedStringKey.intraocularPressure.localized(),
                value: $iop,
                placeholder: LocalizedStringKey.iopPlaceholder.localized(),
                unit: LocalizedStrings.localizedString(for: LocalizedStringKey.mmHg),
                isNumber: true,
                description: LocalizedStringKey.iopDescriptionShort.localized(),
                infoAction: { showingInfo = .iop },
                isRequired: true
            )
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var medicationAndProceduresCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Unified Section Title
            Text(LocalizedStringKey.medicationsProcedures.localized())
                .font(.title2).bold()
                .padding(.bottom, 4)
            // Regraft Toggle (Procedure)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(LocalizedStringKey.regraft.localized())
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: { isRegraft = true }) {
                            Text(LocalizedStringKey.yes.localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isRegraft ? .white : .accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                                .background(isRegraft ? Color.accentColor : Color(.systemGray6))
                                .cornerRadius(14)
                        }
                        Button(action: { isRegraft = false }) {
                            Text(LocalizedStringKey.no.localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(!isRegraft ? .white : .accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                                .background(!isRegraft ? Color.accentColor : Color(.systemGray6))
                                .cornerRadius(14)
                        }
                    }
                }
                HStack(spacing: 4) {
                    Text(LocalizedStringKey.secondTransplant.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: { activeTooltip = .regraft }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            Divider().padding(.vertical, 2)

            HStack {
                Text(LocalizedStringKey.addMedication.localized())
                    .font(.headline)
                    .foregroundColor(.accentColor)
                Spacer()
                Toggle("", isOn: $isTakingNewMedication)
            }
            if isTakingNewMedication {
                // Medication Type
                Text(LocalizedStringKey.medicationType.localized())
                    .font(.subheadline).fontWeight(.medium)
                HStack {
                    Spacer()
                    HStack(spacing: 20) {
                        ForEach(MedicationType.allCases, id: \.self) { type in
                            Button(action: { selectedMedicationType = type }) {
                                VStack(spacing: 4) {
                                    iconForMedicationType(type)
                                        .font(.title2)
                                        .foregroundColor(selectedMedicationType == type ? .white : .accentColor)
                                        .padding(18)
                                        .background(selectedMedicationType == type ? Color.accentColor : Color(.systemGray6))
                                        .clipShape(Circle())
                                    Text(typeLabel(type))
                                        .font(.caption)
                                        .fontWeight(selectedMedicationType == type ? .bold : .regular)
                                        .foregroundColor(selectedMedicationType == type ? .accentColor : .primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.bottom, 4)
                    Spacer()
                }
                // Medication Name
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(LocalizedStringKey.medicationName.localized())
                            .font(.subheadline).fontWeight(.medium)
                        Text("*").foregroundColor(.red)
                    }
                    TextField("e.g., Prednisolone", text: $medicationName)
                }
                // Frequency
                Button(action: { showRepeatPicker = true }) {
                    HStack {
                        Text(LocalizedStringKey.frequency.localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("*").foregroundColor(.red)
                        Spacer()
                        Text(repeatSummary(selectedRepeatDays))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                .sheet(isPresented: $showRepeatPicker) {
                    NavigationView {
                        List {
                            ForEach(0..<7) { i in
                                Button(action: {
                                    if selectedRepeatDays.contains(i) {
                                        selectedRepeatDays.remove(i)
                                    } else {
                                        selectedRepeatDays.insert(i)
                                    }
                                }) {
                                    HStack {
                                        Text("\(LocalizedStringKey.every.localized()) \(weekDays[i])")
                                        Spacer()
                                        if selectedRepeatDays.contains(i) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .navigationTitle(LocalizedStringKey.frequency.localized())
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(LocalizedStringKey.done.localized()) { showRepeatPicker = false }
                            }
                        }
                    }
                }
                // Reminder
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                    Text(LocalizedStringKey.setReminder.localized())
                    Spacer()
                    Toggle("", isOn: $medicationReminder.isEnabled)
                }
                if medicationReminder.isEnabled {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey.startDate.localized()).font(.caption).foregroundColor(.gray)
                            DatePicker("", selection: $medicationReminder.startDate, displayedComponents: .date)
                        }
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey.time.localized()).font(.caption).foregroundColor(.gray)
                            DatePicker("", selection: $medicationReminder.time, displayedComponents: .hourAndMinute)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // Helper for medication icons
    @ViewBuilder
    private func iconForMedicationType(_ type: MedicationType) -> some View {
        switch type {
        case .pills:
            Image(systemName: "pills.fill")
        case .drops:
            Image(systemName: "drop.fill")
        case .injection:
            Image(systemName: "syringe.fill")
        }
    }
    private func typeLabel(_ type: MedicationType) -> String {
        switch type {
        case .pills: return LocalizedStringKey.pills.localized()
        case .drops: return LocalizedStringKey.drops.localized()
        case .injection: return LocalizedStringKey.injection.localized()
        }
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.notes.localized())
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
                    Text(LocalizedStringKey.optionalNotes.localized())
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
        .padding(.horizontal, 4)
    }
    
    private var saveButton: some View {
        VStack {
            Button(action: saveMeasurement) {
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
            .padding([.horizontal, .bottom], 16)
        }
    }
    
    private var isValid: Bool {
        guard let ecdValue = Double(ecd),
              let pachyValue = Double(pachymetry),
              let iopValue = Double(iop) else {
            return false
        }
        
        return ecdValue >= 100 && ecdValue <= 4000 &&
               pachyValue >= 300 && pachyValue <= 700 &&
               iopValue >= 5 && iopValue <= 50
    }
    
    private func validateInputs() -> Bool {
        // Validate ECD
        guard let ecdValue = Double(ecd), ecdValue >= 100, ecdValue <= 4000 else {
            errorMessage = LocalizedStringKey.validEcdError.localized()
            showingError = true
            return false
        }
        
        // Validate Pachymetry
        guard let pachyValue = Double(pachymetry), pachyValue >= 300, pachyValue <= 700 else {
            errorMessage = LocalizedStringKey.validPachymetryError.localized()
            showingError = true
            return false
        }
        
        // Validate IOP
        guard let iopValue = Double(iop), iopValue >= 5, iopValue <= 50 else {
            errorMessage = LocalizedStringKey.validIopError.localized()
            showingError = true
            return false
        }
        
        return true
    }
    
    private func saveMeasurement() {
        // Validate required fields
        guard !ecd.isEmpty, !pachymetry.isEmpty, !iop.isEmpty else {
            errorMessage = LocalizedStringKey.fillRequiredFields.localized()
            showingError = true
            return
        }
        
        guard let ecdValue = Double(ecd),
              let pachymetryValue = Int(pachymetry),
              let iopValue = Double(iop) else {
            errorMessage = LocalizedStringKey.enterValidNumbers.localized()
            showingError = true
            return
        }
        
        // Validate medication fields if taking medication
        if isTakingNewMedication {
            guard !medicationName.isEmpty else {
                errorMessage = LocalizedStringKey.enterMedicationName.localized()
                showingError = true
                return
            }
            
            if selectedFrequency == .other && customRepeatValue == 0 {
                errorMessage = LocalizedStringKey.enterCustomFrequency.localized()
                showingError = true
                return
            }
            
            if medicationReminder.isEnabled && selectedFrequency == .other && (customRepeatValue == 0) {
                errorMessage = LocalizedStringKey.enterCustomReminderFrequency.localized()
                showingError = true
                return
            }
        }
        
        // Create frequency string for record tracking
        let frequencyString: String
        if selectedFrequency == .other {
            frequencyString = "\(customRepeatValue) \(customRepeatUnit.displayName)"
        } else {
            frequencyString = selectedFrequency.displayName
        }
        
        if isEditing {
            // Update existing measurement
            guard let existingMeasurement = existingMeasurement else { return }
            
            let updatedMeasurement = TransplantMeasurement(
                id: existingMeasurement.id,
                userId: existingMeasurement.userId,
                date: date,
                eye: selectedEye,
                ecd: ecdValue,
                pachymetry: pachymetryValue,
                iop: iopValue,
                steroidRegimen: isTakingNewMedication ? frequencyString : nil,
                medicationName: isTakingNewMedication ? medicationName : nil,
                notes: notes.isEmpty ? nil : notes,
                reminderTimes: nil,
                isRegraft: isRegraft,
                edited: true
            )
            
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
                    }
                    
                    // Schedule reminder if enabled
                    if medicationReminder.isEnabled && isTakingNewMedication {
                        scheduleMedicationReminder()
                    }
                    
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        } else {
            // Create new measurement
            let measurement = TransplantMeasurement(
                userId: Auth.auth().currentUser?.uid ?? "",
                date: date,
                eye: selectedEye,
                ecd: ecdValue,
                pachymetry: pachymetryValue,
                iop: iopValue,
                steroidRegimen: isTakingNewMedication ? frequencyString : nil,
                medicationName: isTakingNewMedication ? medicationName : nil,
                notes: notes.isEmpty ? nil : notes,
                reminderTimes: nil,
                isRegraft: isRegraft,
                edited: nil
            )
            
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
                    }
                    
                    // Schedule reminder if enabled
                    if medicationReminder.isEnabled && isTakingNewMedication {
                        scheduleMedicationReminder()
                    }
                    
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        }
    }
    
    // MARK: - Medication Reminder Notification Management
    
    private let medicationReminderIDKey = "currentMedicationReminderID"
    
    private func scheduleMedicationReminder() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        self.scheduleNotificationWithRepeat()
                    } else {
                        // Notification permission denied
                    }
                }
            } else {
                self.scheduleNotificationWithRepeat()
            }
        }
    }
    
    private func scheduleNotificationWithRepeat() {
        let content = UNMutableNotificationContent()
        content.title = LocalizedStringKey.medicationReminder.localized()
        content.body = LocalizedStringKey.timeToTakeMedication.localized().replacingOccurrences(of: "{medication}", with: medicationName)
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: medicationReminder.startDate)
        var repeats = false

        switch medicationReminder.frequency {
        case .daily:
            repeats = true
            // Only hour and minute for daily
        case .weekly:
            repeats = true
            dateComponents.weekday = Calendar.current.component(.weekday, from: medicationReminder.startDate)
        case .monthly:
            repeats = true
            dateComponents.day = Calendar.current.component(.day, from: medicationReminder.startDate)
        case .other:
            repeats = false
            // For custom, see below
        }

        let identifier = "medication_reminder_\(UUID().uuidString)"
        let trigger: UNNotificationTrigger
        if medicationReminder.isEnabled && !selectedRepeatDays.isEmpty {
            // Schedule a notification for each selected weekday
            for weekday in selectedRepeatDays {
                var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: medicationReminder.startDate)
                dateComponents.weekday = weekday + 1 // Sunday=1 in Calendar
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "medication_reminder_\(weekday)_\(UUID().uuidString)"
                UserDefaults.standard.set(identifier, forKey: "currentMedicationReminderID_\(weekday)")
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { _ in
                    // Notification scheduled successfully
                }
            }
            return // Don't schedule a single one-time or custom interval notification
        } else {
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        }

        // Save the identifier for later cancellation/updating
        UserDefaults.standard.set(identifier, forKey: medicationReminderIDKey)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in
            // Notification scheduled successfully
        }
    }
    
    private func cancelMedicationReminder() {
        // Remove all weekday-based reminders
        for i in 0..<7 {
            let key = "currentMedicationReminderID_\(i)"
            if let identifier = UserDefaults.standard.string(forKey: key) {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        // Remove any single reminder as well
        if let identifier = UserDefaults.standard.string(forKey: medicationReminderIDKey) {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            UserDefaults.standard.removeObject(forKey: medicationReminderIDKey)
        }
    }
    
    private func updateMedicationReminder() {
        cancelMedicationReminder()
        scheduleMedicationReminder()
    }
    
    // MARK: - Modern Measurement Row
    @ViewBuilder
    private func MeasurementRowModern(
        label: String,
        value: Binding<String>,
        placeholder: String,
        unit: String,
        isNumber: Bool,
        description: String,
        infoAction: (() -> Void)? = nil,
        isRequired: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                (
                    Text(label)
                    + (isRequired ? Text(" *").foregroundColor(.red) : Text(""))
                )
                .font(.headline)
                .layoutPriority(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(Color.accentColor)
                .lineLimit(1)
                Spacer(minLength: 4)
                TextField(placeholder, text: value)
                    .keyboardType(isNumber ? .decimalPad : .default)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline)
                    .frame(minWidth: 70, maxWidth: 100)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            HStack(spacing: 4) {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                if let infoAction = infoAction {
                    Button(action: infoAction) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 10)
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
                .padding(.horizontal, 16)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func TooltipTextView(for type: TooltipType) -> some View {
        switch type {
        case .ecd:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.endothelialCellDensityTooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.ecdNormalRange.localized())
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(0.9)
                    .padding(.top, 12)
            }
        case .pachymetry:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.cornealThicknessTooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.pachymetryNormalRange.localized())
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(0.9)
                    .padding(.top, 12)
            }
        case .iop:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.intraocularPressureTooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.iopNormalRange.localized())
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(0.9)
                    .padding(.top, 12)
            }
        case .regraft:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.regraftTooltipDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
            }
        }
    }

    private func tooltipTitle(for type: TooltipType) -> String {
        switch type {
        case .ecd: return LocalizedStringKey.ecdTooltip.localized()
        case .pachymetry: return LocalizedStringKey.pachymetryTooltip.localized()
        case .iop: return LocalizedStringKey.iopTooltip.localized()
        case .regraft: return LocalizedStringKey.regraftTooltip.localized()
        }
    }

    // toggle row with Yes/No pill buttons (copied from DryEyeDataEntryView)
    @ViewBuilder
    private func ToggleRowModern(label: String, value: Binding<Bool>, description: String? = nil, infoType: Any? = nil, infoAction: (() -> Void)? = nil, useAccentColor: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                Text(label)
                    .font(.headline)
                    .foregroundColor(useAccentColor ? .accentColor : .primary)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { value.wrappedValue = true }) {
                        Text(LocalizedStringKey.yes.localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(value.wrappedValue ? .white : .accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                            .background(value.wrappedValue ? Color.accentColor : Color(.systemGray6))
                            .cornerRadius(14)
                    }
                    Button(action: { value.wrappedValue = false }) {
                        Text(LocalizedStringKey.no.localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(!value.wrappedValue ? .white : .accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                            .background(!value.wrappedValue ? Color.accentColor : Color(.systemGray6))
                            .cornerRadius(14)
                    }
                }
            }
            if let description = description {
                HStack(spacing: 4) {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let infoAction = infoAction {
                        Button(action: infoAction) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }

    // Helper to summarize repeat days
    private func repeatSummary(_ days: Set<Int>) -> String {
        if days.isEmpty { return LocalizedStringKey.never.localized() }
        if days.count == 7 { return LocalizedStringKey.everyDay.localized() }
        let short = days.sorted().map { String(weekDays[$0].prefix(3)) }
        return short.joined(separator: ", ")
    }
}

struct MonitoringGuidelinesPopover: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text(LocalizedStringKey.monitoringGuidelines.localized())
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
            }
            .padding(.bottom, 4)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(LocalizedStringKey.specularMicroscopy.localized()) (ECD)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    Text(LocalizedStringKey.firstThreeMonths.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(LocalizedStringKey.cornealThickness.localized())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    Text(LocalizedStringKey.firstThreeMonths.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(LocalizedStringKey.iop.localized())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    Text(LocalizedStringKey.everyFourSixMonths.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(LocalizedStringKey.steroidRegimen.localized())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    Text(LocalizedStringKey.mayChangeFrequency.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
        .id(currentLanguage) // Force re-render on language change
    }
}

// MARK: - Reminder Picker View
struct ReminderPickerView: View {
    @Binding var reminder: MedicationReminder
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var tempStartDate: Date
    @State private var tempTime: Date
    @State private var tempFrequency: Frequency
    @State private var tempCustomFrequency: String
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    init(reminder: Binding<MedicationReminder>) {
        self._reminder = reminder
        self._tempStartDate = State(initialValue: reminder.wrappedValue.startDate)
        self._tempTime = State(initialValue: reminder.wrappedValue.time)
        self._tempFrequency = State(initialValue: reminder.wrappedValue.frequency)
        self._tempCustomFrequency = State(initialValue: reminder.wrappedValue.customFrequency ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Start Date
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey.startDate.localized())
                        .font(.headline)
                        .fontWeight(.medium)
                    DatePicker("Start Date", selection: $tempStartDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }
                // Time
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey.time.localized())
                        .font(.headline)
                        .fontWeight(.medium)
                    DatePicker("Time", selection: $tempTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
                // Frequency
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey.repeatAction.localized())
                        .font(.headline)
                        .fontWeight(.medium)
                    HStack(spacing: 12) {
                        ForEach(Frequency.allCases, id: \.self) { frequency in
                            Button(action: { tempFrequency = frequency }) {
                                Text(frequency.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(tempFrequency == frequency ? .white : .accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(tempFrequency == frequency ? Color.accentColor : Color.clear)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.accentColor, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    if tempFrequency == .other {
                        TextField(LocalizedStringKey.customFrequency.localized(), text: $tempCustomFrequency)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle(LocalizedStringKey.setReminderTitle.localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey.cancel.localized()) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey.save.localized()) {
                        reminder.startDate = tempStartDate
                        reminder.time = tempTime
                        reminder.frequency = tempFrequency
                        reminder.customFrequency = tempFrequency == .other ? tempCustomFrequency : nil
                        dismiss()
                    }
                }
            }
            .id(currentLanguage) // Force re-render on language change
        }
    }
}

// MARK: - Helper Functions
extension CornealTransplantDataEntryView {
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private func calculateNextReminderDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the time components from reminder time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: medicationReminder.time)
        
        // Create today's date with the selected time
        var nextDate = calendar.date(bySettingHour: timeComponents.hour ?? 0, 
                                   minute: timeComponents.minute ?? 0, 
                                   second: 0, 
                                   of: now) ?? now
        
        // If the time has already passed today, move to the next occurrence
        if nextDate <= now {
            switch medicationReminder.frequency {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            case .other:
                // For custom frequency, just add a day as default
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }
        }
        
        return nextDate
    }
}

#Preview {
    NavigationStack {
        CornealTransplantDataEntryView(
            viewModel: CornealTransplantViewModel(),
            selectedEye: .OD
        )
    }
} 
