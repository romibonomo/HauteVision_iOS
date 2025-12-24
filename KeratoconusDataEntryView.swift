import SwiftUI
import FirebaseAuth

struct KeratoconusDataEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: KeratoconusViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let selectedEye: EyeType
    let existingMeasurement: KeratoconusMeasurement? // For editing existing measurements
    @State private var eyeSelection: EyeType
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    @State private var date = Date()
    @State private var k2 = ""
    @State private var kMax = ""
    @State private var thinnestPachymetry = ""
    @State private var thickestEpithelialSpot = ""
    @State private var thinnestEpithelialSpot = ""
    @State private var keratoconusRiskScore = 0
    @State private var documentedCylindricalIncrease = false
    @State private var subjectiveVisionLoss = false
    @State private var hasCrossLinking = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    @State private var showingEditWarning = false
    
    @State private var notes = ""
    @State private var showingDatePicker = false
    
    // Info tooltip state (single overlay)
    @State private var activeTooltip: TooltipType? = nil
    enum TooltipType { case k2, kMax, pachymetry, epithelial, riskScore }
    
    // Computed property to determine if we're editing
    private var isEditing: Bool {
        return existingMeasurement != nil
    }
    
    // Initializer for new measurements
    init(viewModel: KeratoconusViewModel, selectedEye: EyeType) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = nil
        _eyeSelection = State(initialValue: selectedEye)
    }
    
    // Initializer for editing existing measurements
    init(viewModel: KeratoconusViewModel, selectedEye: EyeType, existingMeasurement: KeratoconusMeasurement) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = existingMeasurement
        _eyeSelection = State(initialValue: existingMeasurement.eye)
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
                        Text(LocalizedStringKey.keratoconus.localized())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        DataEntryEyeToggleView(selectedEye: $eyeSelection)
                            .padding(.top, 8)
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
                            DatePicker(LocalizedStringKey.selectDateTime.localized(), selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .padding()
                            Button(LocalizedStringKey.done.localized()) { showingDatePicker = false }
                                .padding()
                            }
                            .presentationDetents([.medium, .large])
                        }
                        measurementsCard
                        riskIndicatorsCard
                        proceduresCard
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
            SaveButton
            if let tooltip = activeTooltip {
                TooltipOverlay(type: tooltip) {
                    activeTooltip = nil
                }
            }
        }
        .navigationTitle(isEditing ? LocalizedStringKey.editMeasurement.localized() : LocalizedStringKey.addMeasurement.localized())
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizedStringKey.error.localized(), isPresented: $showingAlert) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert(LocalizedStringKey.editMeasurementWarning.localized(), isPresented: $showingEditWarning) {
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
            Button(LocalizedStringKey.continueAction.localized(), role: .destructive) {
                saveData()
            }
        } message: {
            Text(LocalizedStringKey.editMeasurementMessage.localized())
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
                        saveData()
                    }
                }
            }
        }
        .id(currentLanguage) // Force re-render on language change
        .onAppear {
            if let existingMeasurement = existingMeasurement {
                // Prefill the form with existing data
                date = existingMeasurement.date
                k2 = String(format: "%.1f", existingMeasurement.k2)
                kMax = String(format: "%.1f", existingMeasurement.kMax)
                thinnestPachymetry = String(existingMeasurement.thinnestPachymetry)
                thickestEpithelialSpot = String(format: "%.0f", existingMeasurement.thickestEpithelialSpot)
                thinnestEpithelialSpot = String(existingMeasurement.thinnestEpithelialSpot)
                keratoconusRiskScore = existingMeasurement.keratoconusRiskScore
                documentedCylindricalIncrease = existingMeasurement.documentedCylindricalIncrease
                subjectiveVisionLoss = existingMeasurement.subjectiveVisionLoss
                hasCrossLinking = existingMeasurement.hasCrossLinking
                notes = existingMeasurement.notes ?? ""
            }
            
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.measurements.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
        
            MeasurementRowModern(
                label: LocalizedStringKey.k2Values.localized(),
                value: $k2,
                placeholder: LocalizedStringKey.k2Placeholder.localized(),
                unit: LocalizedStringKey.diopters.localized(),
                isNumber: true,
                description: LocalizedStringKey.steepestCornealCurvature.localized(),
                infoAction: { activeTooltip = .k2 },
                isRequired: true
            )
            Divider().padding(.vertical, 2)
            MeasurementRowModern(
                label: LocalizedStringKey.kMaxValues.localized(),
                value: $kMax,
                placeholder: LocalizedStringKey.kMaxPlaceholder.localized(),
                unit: LocalizedStringKey.diopters.localized(),
                isNumber: true,
                description: LocalizedStringKey.maximumCornealCurvature.localized(),
                infoAction: { activeTooltip = .kMax },
                isRequired: true
            )
            Divider().padding(.vertical, 2)
            MeasurementRowModern(
                label: LocalizedStringKey.thinnestPachymetry.localized(),
                value: $thinnestPachymetry,
                placeholder: LocalizedStringKey.pachymetryPlaceholder.localized(),
                unit: LocalizedStringKey.micrometers.localized(),
                isNumber: true,
                description: LocalizedStringKey.thinnestPointCornea.localized(),
                infoAction: { activeTooltip = .pachymetry },
                isRequired: true
            )
            Divider().padding(.vertical, 2)
            MeasurementRowModern(
                label: LocalizedStringKey.thickestEpithelialSpot.localized(),
                value: $thickestEpithelialSpot,
                placeholder: LocalizedStringKey.thickestEpithelialPlaceholder.localized(),
                unit: LocalizedStringKey.micrometers.localized(),
                isNumber: true,
                description: LocalizedStringKey.cornealEpitheliumThickestPoint.localized(),
                infoAction: { activeTooltip = .epithelial },
                isRequired: false
            )
            Divider().padding(.vertical, 2)
            MeasurementRowModern(
                label: LocalizedStringKey.thinnestEpithelialSpot.localized(),
                value: $thinnestEpithelialSpot,
                placeholder: LocalizedStringKey.thinnestEpithelialPlaceholder.localized(),
                unit: LocalizedStringKey.micrometers.localized(),
                isNumber: true,
                description: LocalizedStringKey.cornealEpitheliumThinnestPoint.localized(),
                infoAction: { activeTooltip = .epithelial },
                isRequired: false
            )
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var riskIndicatorsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.riskIndicators.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 12)
                .padding(.bottom, 12)
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(LocalizedStringKey.keratoconusRiskScore.localized())
                            .foregroundColor(.accentColor)
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 12) {
                            Button {
                                if keratoconusRiskScore > 0 {
                                    withAnimation { keratoconusRiskScore -= 1 }
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(keratoconusRiskScore > 0 ? Color(hex: "4437EB").opacity(0.1) : Color(.systemGray6))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "minus")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(keratoconusRiskScore > 0 ? .accentColor : .secondary)
                                }
                            }
                            .disabled(keratoconusRiskScore == 0)
                            Text("\(keratoconusRiskScore)")
                                .font(.subheadline)
                                .foregroundColor(riskColor(score: keratoconusRiskScore))
                                .frame(width: 40)
                                .multilineTextAlignment(.center)
                            Button {
                                if keratoconusRiskScore < 10 {
                                    withAnimation { keratoconusRiskScore += 1 }
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(keratoconusRiskScore < 10 ? Color(hex: "4437EB").opacity(0.1) : Color(.systemGray6))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(keratoconusRiskScore < 10 ? .accentColor : .secondary)
                                }
                            }
                            .disabled(keratoconusRiskScore == 10)
                        }
                    }
                    HStack(spacing: 4) {
                        Text(LocalizedStringKey.riskScoreRange.localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: { activeTooltip = .riskScore }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 44)
                .contentShape(Rectangle())
                Divider().padding(.vertical, 2)
                ToggleRowModern(
                    label: LocalizedStringKey.cylindricalIncrease.localized(),
                    value: $documentedCylindricalIncrease,
                    description: LocalizedStringKey.increaseInAstigmatism.localized(),
                    infoType: nil,
                    infoAction: nil,
                    useAccentColor: true
                )
                Divider().padding(.vertical, 2)
                ToggleRowModern(
                    label: LocalizedStringKey.subjectiveVisionLoss.localized(),
                    value: $subjectiveVisionLoss,
                    description: LocalizedStringKey.patientReportedDecreaseInVision.localized(),
                    infoType: nil,
                    infoAction: nil,
                    useAccentColor: true
                )
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var proceduresCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.procedures.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
            Toggle(LocalizedStringKey.crossLinkingPerformed.localized(), isOn: $hasCrossLinking)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .padding(.top, 8)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.notes.localized())
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 12)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                if notes.isEmpty {
                    Text(LocalizedStringKey.notesPlaceholder.localized())
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
    
    private var SaveButton: some View {
        VStack {
            Button(action: saveData) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text(isEditing ? LocalizedStringKey.updateMeasurement.localized() : LocalizedStringKey.saveMeasurement.localized())
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(isFormValid ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(16)
                .shadow(color: isFormValid ? Color.accentColor.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!isFormValid || isSaving)
            .padding([.horizontal, .bottom], 16)
        }
    }
    
    private var TooltipOverlay: some View {
        Group {
            if let tooltip = activeTooltip {
                TooltipOverlay(type: tooltip) {
                    activeTooltip = nil
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let k2Value = Double(k2),
              let kMaxValue = Double(kMax),
              let thinnestPachymetryValue = Int(thinnestPachymetry) else {
            return false
        }
        
        return k2Value > 0 && kMaxValue > 0 && thinnestPachymetryValue > 0
    }
    
    private func saveData() {
        guard isFormValid else {
            alertMessage = LocalizedStringKey.fillRequiredFields.localized()
            showingAlert = true
            return
        }
        
        isSaving = true
        
        if isEditing {
            // Update existing measurement
            guard let existingMeasurement = existingMeasurement else { return }
            
            let updatedMeasurement = KeratoconusMeasurement(
                id: existingMeasurement.id,
                userId: existingMeasurement.userId,
                date: date,
                eye: selectedEye,
                k2: Double(k2) ?? 0,
                kMax: Double(kMax) ?? 0,
                thinnestPachymetry: Int(thinnestPachymetry) ?? 0,
                thickestEpithelialSpot: Double(thickestEpithelialSpot) ?? 0,
                thinnestEpithelialSpot: Int(thinnestEpithelialSpot) ?? 0,
                keratoconusRiskScore: keratoconusRiskScore,
                documentedCylindricalIncrease: documentedCylindricalIncrease,
                subjectiveVisionLoss: subjectiveVisionLoss,
                hasCrossLinking: hasCrossLinking,
                notes: notes.isEmpty ? nil : notes,
                edited: true
            )
            
            // Save the updated measurement
            Task {
                do {
                    // First delete the old measurement
                    try await viewModel.deleteMeasurement(existingMeasurement)
                    // Then add the updated measurement
                    try await viewModel.addMeasurement(updatedMeasurement)
                    // Force immediate UI refresh by directly updating the measurements arrays
                    await MainActor.run {
                        // Trigger a UI refresh by temporarily clearing and re-adding the measurements
                        let currentOD = viewModel.measurementsOD
                        let currentOS = viewModel.measurementsOS
                        viewModel.measurementsOD = []
                        viewModel.measurementsOS = []
                        DispatchQueue.main.async {
                            viewModel.measurementsOD = currentOD
                            viewModel.measurementsOS = currentOS
                        }
                    }
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        alertMessage = "\(LocalizedStringKey.error.localized()): \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        } else {
            // Create new measurement
            let measurement = KeratoconusMeasurement(
                userId: Auth.auth().currentUser?.uid ?? "",
                date: date,
                eye: selectedEye,
                k2: Double(k2) ?? 0,
                kMax: Double(kMax) ?? 0,
                thinnestPachymetry: Int(thinnestPachymetry) ?? 0,
                thickestEpithelialSpot: Double(thickestEpithelialSpot) ?? 0,
                thinnestEpithelialSpot: Int(thinnestEpithelialSpot) ?? 0,
                keratoconusRiskScore: keratoconusRiskScore,
                documentedCylindricalIncrease: documentedCylindricalIncrease,
                subjectiveVisionLoss: subjectiveVisionLoss,
                hasCrossLinking: hasCrossLinking,
                notes: notes.isEmpty ? nil : notes,
                edited: nil
            )
            
            // Save the measurement
            Task {
                do {
                    try await viewModel.addMeasurement(measurement)
                    // Force UI refresh by updating the published properties
                    await MainActor.run {
                        // Trigger a UI refresh by temporarily clearing and re-adding the measurements
                        let currentOD = viewModel.measurementsOD
                        let currentOS = viewModel.measurementsOS
                        viewModel.measurementsOD = []
                        viewModel.measurementsOS = []
                        DispatchQueue.main.async {
                            viewModel.measurementsOD = currentOD
                            viewModel.measurementsOS = currentOS
                        }
                    }
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        alertMessage = "\(LocalizedStringKey.error.localized()): \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    // Tooltip overlay
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
        case .k2:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.k2Tooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.normalRangeK2.localized())
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .kMax:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.kMaxTooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.normalRangeKMax.localized())
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .pachymetry:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.pachymetryTooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.normalRangePachymetryKeratoconus.localized())
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .epithelial:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.epithelialTooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
            }
        case .riskScore:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.riskScoreTooltip.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                (
                    Text(LocalizedStringKey.lowRisk.localized())
                        .foregroundColor(.green)
                    + Text(", ")
                        .foregroundColor(.gray)
                    + Text(LocalizedStringKey.highRisk.localized())
                        .foregroundColor(.red)
                )
                    .font(.caption)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    private func tooltipTitle(for type: TooltipType) -> String {
        switch type {
        case .k2: return LocalizedStringKey.k2Values.localized()
        case .kMax: return LocalizedStringKey.kMaxValues.localized()
        case .pachymetry: return LocalizedStringKey.thinnestPachymetry.localized()
        case .epithelial: return LocalizedStringKey.epithelialThickness.localized()
        case .riskScore: return LocalizedStringKey.keratoconusRiskScore.localized()
        }
    }
    
    @ViewBuilder
    private func MeasurementRowModern(
        label: String,
        value: Binding<String>,
        placeholder: String,
        unit: String,
        isNumber: Bool,
        description: String,
        infoAction: @escaping () -> Void,
        isRequired: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                (
                    Text(label)
                        .foregroundColor(.accentColor)
                    + (isRequired ? Text(" *").foregroundColor(.red) : Text(""))
                )
                .font(.headline)
                .layoutPriority(1)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                Spacer(minLength: 8)
                TextField(placeholder, text: value)
                    .keyboardType(isNumber ? .decimalPad : .default)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline)
                    .frame(minWidth: 70, maxWidth: 120)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            HStack(spacing: 4) {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                Button(action: infoAction) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func ToggleRowModern(label: String, value: Binding<Bool>, description: String? = nil, infoType: TooltipType? = nil, infoAction: (() -> Void)? = nil, useAccentColor: Bool = false) -> some View {
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
    
    private func riskColor(score: Int) -> Color {
        switch score {
        case 0: return .green
        case 1...2: return .yellow
        case 3...4: return .orange
        case 5...10: return .red
        default: return .gray
        }
    }
}

struct KeratoconusDataEntryView_Previews: PreviewProvider {
    static var previews: some View {
        KeratoconusDataEntryView(viewModel: KeratoconusViewModel(), selectedEye: .OD)
    }
}