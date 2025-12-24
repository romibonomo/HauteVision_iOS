import SwiftUI
import FirebaseAuth

// MARK: - Questionnaire Models
struct FuchsQuestionnaireResponse {
    var frequencyResponses: [Int] = Array(repeating: -1, count: 7) // 7 questions, -1 for unselected, 0-4 for selected
    var difficultyResponses: [Int] = Array(repeating: -1, count: 8) // 8 questions, -1 for unselected, 0-4 for selected
    
    var totalScore: Int {
        let frequencyScore = frequencyResponses.filter { $0 >= 0 }.reduce(0, +)
        let difficultyScore = difficultyResponses.filter { $0 >= 0 }.reduce(0, +)
        return frequencyScore + difficultyScore
    }
    
    var maxPossibleScore: Int {
        return 7 * 4 + 8 * 4 // 60 total
    }
    
    var isComplete: Bool {
        return frequencyResponses.allSatisfy { $0 >= 0 } && difficultyResponses.allSatisfy { $0 >= 0 }
    }
    
    var frequencyScore: Int {
        return frequencyResponses.filter { $0 >= 0 }.reduce(0, +)
    }
    
    var difficultyScore: Int {
        return difficultyResponses.filter { $0 >= 0 }.reduce(0, +)
    }
}

struct FuchsDystrophyDataEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FuchsViewModel
    @State var selectedEye: EyeType
    let existingMeasurement: FuchsMeasurement? // For editing existing measurements
    
    @State private var date = Date()
    @State private var ecd = ""
    @State private var pachymetry = ""
    @State private var score = 0
    @State private var questionnaire = FuchsQuestionnaireResponse()
    @State private var notes = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingQuestionnaire = false
    @State private var showingEditWarning = false
    
    // Info tooltip state (single overlay)
    @State private var activeTooltip: TooltipType? = nil
    enum TooltipType { case ecd, pachymetry, score, vfuchs }
    
    @State private var showingDatePicker = false
    
    // Computed property to determine if we're editing
    private var isEditing: Bool {
        return existingMeasurement != nil
    }
    
    // Initializer for new measurements
    init(viewModel: FuchsViewModel, selectedEye: EyeType) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = nil
    }
    
    // Initializer for editing existing measurements
    init(viewModel: FuchsViewModel, selectedEye: EyeType, existingMeasurement: FuchsMeasurement) {
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
                        Text(LocalizedStringKey.fuchsDystrophy.localized())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        eyeSelector
                        dateTimeInlineRow
                        measurementsCard
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
        }
        .navigationTitle(isEditing ? LocalizedStringKey.editMeasurement.localized() : LocalizedStringKey.addMeasurement.localized())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(LocalizedStringKey.editMeasurementWarning.localized(), isPresented: $showingEditWarning) {
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
            Button(LocalizedStringKey.continue.localized(), role: .destructive) {
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
                score = existingMeasurement.score
                notes = existingMeasurement.notes ?? ""
                
                // Prefill questionnaire if it exists
                if existingMeasurement.vfuchsQuestionnaire > 0 {
                    // Create a questionnaire response that matches the existing score
                    // This is a simplified approach - ideally you'd store the actual questionnaire responses
                    var questionnaireResponse = FuchsQuestionnaireResponse()
                    // For now, we'll create a basic response that approximates the score
                    // In a full implementation, you'd want to store and restore the actual questionnaire responses
                    let targetScore = Int(existingMeasurement.vfuchsQuestionnaire)
                    // Set some default responses to approximate the score
                    // This is a simplified approach
                    questionnaireResponse.frequencyResponses = [targetScore / 7, targetScore / 7, targetScore / 7, targetScore / 7, targetScore / 7, targetScore / 7, targetScore / 7]
                    questionnaireResponse.difficultyResponses = [targetScore / 8, targetScore / 8, targetScore / 8, targetScore / 8, targetScore / 8, targetScore / 8, targetScore / 8, targetScore / 8]
                    questionnaire = questionnaireResponse
                }
            }
        }
        .sheet(isPresented: $showingQuestionnaire) {
            NavigationStack {
                FuchsQuestionnaireView(questionnaire: $questionnaire)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.regularMaterial)
            .presentationCornerRadius(16)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey.cancel.localized()) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey.save.localized()) { saveMeasurement() }
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
        DataEntryEyeToggleView(selectedEye: $selectedEye)
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
                    .padding()
                Button(LocalizedStringKey.done.localized()) { showingDatePicker = false }
                    .padding()
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.visionMeasurements.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
            
            // V-Fuchs Questionnaire Button
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    (
                        Text(LocalizedStringKey.vFuchsQuestionnaire.localized())
                            .foregroundColor(.accentColor)
                        + Text(" *").foregroundColor(.red)
                    )
                    .font(.headline)
                    .layoutPriority(1)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    Spacer(minLength: 8)
                    Button(action: { showingQuestionnaire = true }) {
                        HStack(spacing: 4) {
                            Text("\(questionnaire.totalScore)")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                            Text("/ \(questionnaire.maxPossibleScore)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                HStack(spacing: 4) {
                    Text(LocalizedStringKey.visualFunctionCornealHealth.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: { activeTooltip = .vfuchs }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 10)
            Divider()
            
            MeasurementRowModern(
                label: "ECD",
                value: $ecd,
                placeholder: LocalizedStringKey.ecdPlaceholder.localized(),
                unit: LocalizedStringKey.cellsPerMm2.localized(),
                isNumber: true,
                description: LocalizedStringKey.endothelialCellDensity.localized(),
                infoAction: { activeTooltip = .ecd },
                isRequired: true
            )
            MeasurementRowModern(
                label: LocalizedStringKey.cornealThickness.localized(),
                value: $pachymetry,
                placeholder: LocalizedStringKey.pachymetryPlaceholder.localized(),
                unit: LocalizedStringKey.micrometers.localized(),
                isNumber: true,
                description: LocalizedStringKey.normalRangePachymetry.localized(),
                infoAction: { activeTooltip = .pachymetry },
                isRequired: true
            )
            Divider()
            
            // Severity Score Section
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(LocalizedStringKey.severityScore.localized())
                        .foregroundColor(.accentColor)
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 12) {
                            Button {
                                if score > 0 {
                                withAnimation { score -= 1 }
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(score > 0 ? Color(hex: "4437EB").opacity(0.1) : Color(.systemGray6))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "minus")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(score > 0 ? .accentColor : .secondary)
                                }
                            }
                            .disabled(score == 0)
                            
                        Text("\(score)")
                            .font(.subheadline)
                                .foregroundColor(scoreColor)
                            .frame(width: 40)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                if score < 6 {
                                withAnimation { score += 1 }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(score < 6 ? Color(hex: "4437EB").opacity(0.1) : Color(.systemGray6))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(score < 6 ? .accentColor : .secondary)
                            }
                        }
                        .disabled(score == 6)
                    }
                }
                HStack(spacing: 4) {
                    Text(LocalizedStringKey.normalRangeScore.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: { activeTooltip = .score }) {
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
            .padding([.horizontal, .bottom], 16)
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
        Divider()
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

    // MARK: - Tooltip Texts
    @ViewBuilder
    private func TooltipTextView(for type: TooltipType) -> some View {
        switch type {
        case .ecd:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.ecdTooltipDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.ecdTooltipNormalRange.localized())
                    .font(.caption)
                    .foregroundColor(Color.green)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .pachymetry:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.pachymetryTooltipDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.pachymetryTooltipNormalRange.localized())
                    .font(.caption)
                    .foregroundColor(Color.green)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        case .score:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.scoreTooltipDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.scoreTooltipRanges.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(0.9)
                    .padding(.top, 12)
            }
            
        case .vfuchs:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.vfuchsTooltipDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.vfuchsTooltipNote.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func tooltipTitle(for type: TooltipType) -> String {
        switch type {
        case .ecd: return "Endothelial Cell Density"
        case .pachymetry: return "Corneal Thickness"
        case .score: return "Severity Score"
        case .vfuchs: return "V-Fuchs Questionnaire"
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0: return .green
        case 1...2: return .yellow
        case 3...4: return .orange
        case 5...6: return .red
        default: return .gray
        }
    }
    
    private var isValid: Bool {
        guard let ecdValue = Double(ecd),
              let pachymetryValue = Int(pachymetry) else {
            return false
        }
        
        return ecdValue > 0 && pachymetryValue > 0
    }
    
    private func saveMeasurement() {
        guard let ecdValue = Double(ecd),
              let pachymetryValue = Int(pachymetry) else {
            errorMessage = "Please enter valid numbers for all measurements"
            showingError = true
            return
        }
        
        if isEditing {
            // Update existing measurement
            guard let existingMeasurement = existingMeasurement else { return }
            
            let updatedMeasurement = FuchsMeasurement(
                id: existingMeasurement.id,
                userId: existingMeasurement.userId,
                date: date,
                eye: selectedEye,
                ecd: ecdValue,
                pachymetry: pachymetryValue,
                score: score,
                vfuchsQuestionnaire: Double(questionnaire.totalScore),
                notes: notes.isEmpty ? nil : notes,
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
                        // Force UI refresh by notifying the ObservableObject
                        viewModel.objectWillChange.send()
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
            let measurement = FuchsMeasurement(
                userId: Auth.auth().currentUser?.uid ?? "",
                date: date,
                eye: selectedEye,
                ecd: ecdValue,
                pachymetry: pachymetryValue,
                score: score,
                vfuchsQuestionnaire: Double(questionnaire.totalScore),
                notes: notes.isEmpty ? nil : notes,
                edited: nil
            )
            
            Task {
                do {
                    try await viewModel.addMeasurement(measurement)
                    // Force UI refresh by updating the published properties
                    await viewModel.fetchMeasurements()
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

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
    private var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
}

// MARK: - Questionnaire View
struct FuchsQuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var questionnaire: FuchsQuestionnaireResponse
    @State private var showingIncompleteAlert = false
    @State private var showingFrenchCitation = false
    
    private var frequencyOptions: [String] {
        [
            LocalizedStringKey.never.localized(),
            LocalizedStringKey.rarely.localized(),
            LocalizedStringKey.sometimes.localized(),
            LocalizedStringKey.mostOfTheTime.localized(),
            LocalizedStringKey.allOfTheTime.localized()
        ]
    }
    
    private var difficultyOptions: [String] {
        [
            LocalizedStringKey.noDifficulty.localized(),
            LocalizedStringKey.aLittle.localized(),
            LocalizedStringKey.moderateDifficulty.localized(),
            LocalizedStringKey.aLot.localized(),
            LocalizedStringKey.extremeDifficulty.localized()
        ]
    }
    
    private var frequencyQuestions: [String] {
        [
            LocalizedStringKey.fuchsQ1.localized(),
            LocalizedStringKey.fuchsQ2.localized(),
            LocalizedStringKey.fuchsQ3.localized(),
            LocalizedStringKey.fuchsQ4.localized(),
            LocalizedStringKey.fuchsQ5.localized(),
            LocalizedStringKey.fuchsQ6.localized(),
            LocalizedStringKey.fuchsQ7.localized()
        ]
    }
    
    private var difficultyQuestions: [String] {
        [
            LocalizedStringKey.fuchsQ8.localized(),
            LocalizedStringKey.fuchsQ9.localized(),
            LocalizedStringKey.fuchsQ10.localized(),
            LocalizedStringKey.fuchsQ11.localized(),
            LocalizedStringKey.fuchsQ12.localized(),
            LocalizedStringKey.fuchsQ13.localized(),
            LocalizedStringKey.fuchsQ14.localized(),
            LocalizedStringKey.fuchsQ15.localized()
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey.visionAssessment.localized())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        
                        Text(LocalizedStringKey.visualFunctionCornealHealthStatus.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.pleaseCompleteEvaluation.localized())
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                        
                        Text(LocalizedStringKey.ifYouWearGlasses.localized())
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                    }
                }
                .padding(.horizontal, 20)

                
                // Section 1: Frequency Questions
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.frequencyAssessment.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.teal)
                        Text(LocalizedStringKey.howOftenExperience.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Questions
                    VStack(spacing: 12) {
                        ForEach(0..<frequencyQuestions.count, id: \.self) { index in
                            ModernQuestionCard(
                                question: frequencyQuestions[index],
                                options: frequencyOptions,
                                selectedIndex: $questionnaire.frequencyResponses[index],
                                questionNumber: index + 1,
                                accentColor: .teal
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Section 2: Difficulty Questions
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.difficultyAssessment.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        Text(LocalizedStringKey.howMuchDifficulty.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Questions
                    VStack(spacing: 12) {
                        ForEach(0..<difficultyQuestions.count, id: \.self) { index in
                            ModernQuestionCard(
                                question: difficultyQuestions[index],
                                options: difficultyOptions,
                                selectedIndex: $questionnaire.difficultyResponses[index],
                                questionNumber: frequencyQuestions.count + index + 1,
                                accentColor: .purple
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Save Answers Button
                Button(action: {
                    if questionnaire.isComplete {
                        dismiss()
                    } else {
                        showingIncompleteAlert = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text(LocalizedStringKey.saveAnswers.localized())
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(questionnaire.isComplete ? Color.accentColor : Color(.systemGray5))
                    .cornerRadius(22)
                    .shadow(color: questionnaire.isComplete ? Color.accentColor.opacity(0.18) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!questionnaire.isComplete)
                .padding(.horizontal, 20)
                .padding(.top, 32)
                
                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    if LocalizationManager.shared.currentLanguage == .french {
                        // French version with clickable asterisk
                        HStack(alignment: .top, spacing: 4) {
                            Text(LocalizedStringKey.sourceFrench.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(1)
                            
                            Button(action: {
                                // Show French citation in an alert or sheet
                                showingFrenchCitation = true
                            }) {
                                Text("*")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                    } else {
                        // English version
                        Text(LocalizedStringKey.source.localized())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(1)
                    }
                    
                    Text(LocalizedStringKey.copyright.localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(LocalizedStringKey.mc8801.localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 120)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(LocalizedStringKey.vFuchsQuestionnaire.localized())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizedStringKey.cancel.localized()) {
                    // Reset all entries and dismiss
                    questionnaire = FuchsQuestionnaireResponse()
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedStringKey.done.localized()) {
                    if questionnaire.isComplete {
                        dismiss()
                    } else {
                        showingIncompleteAlert = true
                    }
                }
                .foregroundColor(.blue)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                FloatingScoreSummary(questionnaire: questionnaire)
            }
        }
        .alert(LocalizedStringKey.incompleteQuestionnaire.localized(), isPresented: $showingIncompleteAlert) {
            Button(LocalizedStringKey.continue.localized(), role: .cancel) { }
        } message: {
            Text(LocalizedStringKey.answerAllQuestions.localized())
        }
        .alert("Citation Française", isPresented: $showingFrenchCitation) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(LocalizedStringKey.frenchCitation.localized())
        }
    }
}

// MARK: - Modern Question Card
struct ModernQuestionCard: View {
    let question: String
    let options: [String]
    @Binding var selectedIndex: Int
    let questionNumber: Int
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question
            HStack(alignment: .top, spacing: 12) {
                Text("\(questionNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(accentColor)
                    )
                
                Text(question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
            
            // Options
            HStack(spacing: 0) {
                ForEach(0..<options.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedIndex = index
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(selectedIndex == index ? accentColor : Color(.systemGray4), lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                
                                if selectedIndex == index {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text(options[index])
                            .font(.caption2)
                            .fontWeight(selectedIndex == index ? .medium : .regular)
                            .foregroundColor(selectedIndex == index ? accentColor : .secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(height: 32, alignment: .center) // Fixed height for all option texts
                            .fixedSize(horizontal: false, vertical: true) // Allow text to wrap naturally
                    }
                    .frame(maxWidth: .infinity)
                    
                    if index < options.count - 1 {
                        Divider()
                            .frame(height: 40)
                            .padding(.horizontal, 4) // Add some padding to the dividers
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Floating Score Summary
struct FloatingScoreSummary: View {
    let questionnaire: FuchsQuestionnaireResponse
    
    private let frequencyQuestions = 7
    private let difficultyQuestions = 8
    
    var body: some View {
        VStack(spacing: 0) {
            // Floating card with shadow
            VStack(spacing: 16) {
                // Main Score
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(LocalizedStringKey.totalScore.localized())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "4437EB"))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text("\(questionnaire.totalScore)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4437EB"))
                        Text("/")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "4437EB"))
                        Text("\(questionnaire.maxPossibleScore)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "4437EB"))
                    }
                }
                
                // Sub-scores
                HStack(spacing: 12) {
                    // Frequency Score
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey.frequency.localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(questionnaire.frequencyScore)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.teal)
                            Text("/")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(frequencyQuestions * 4)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Vertical divider
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 32)
                    
                    // Difficulty Score
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey.difficulty.localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(questionnaire.difficultyScore)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                            Text("/")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(difficultyQuestions * 4)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color.clear)
    }
}


struct FuchsDystrophyDataEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FuchsDystrophyDataEntryView(
                viewModel: FuchsViewModel(),
                selectedEye: .OD
            )
        }
    }
}
