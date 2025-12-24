import SwiftUI

struct DryEyeDataEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DryEyeViewModel
    @State var selectedEye: EyeType
    let existingMeasurement: DryEyeMeasurement? // For editing existing measurements
    
    @State private var date = Date()
    @State private var osmolarity = ""
    @State private var meibographyPercentLoss = ""
    @State private var hadIPLOrRF = false
    @State private var hadRadioFrequency = false
    @State private var nextIPLDate: Date?
    @State private var nextRadioFrequencyDate: Date?
    @State private var tmh = ""
    @State private var mmp9 = false
    @State private var mmp9Note = ""
    @State private var notes = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingQuestionnaire = false
    @State private var showingEditWarning = false
    
    // OSDI Questionnaire
    @State private var osdiQuestionnaire = OSDIQuestionnaireResponse()
    @State private var showingScoreCalculationInfo = false
    
    // Localization
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    // Computed property to determine if we're editing
    private var isEditing: Bool {
        return existingMeasurement != nil
    }
    
    // Initializer for new measurements
    init(viewModel: DryEyeViewModel, selectedEye: EyeType) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = nil
    }
    
    // Initializer for editing existing measurements
    init(viewModel: DryEyeViewModel, selectedEye: EyeType, existingMeasurement: DryEyeMeasurement) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = existingMeasurement
    }
    
    // Info tooltip state (single overlay)
    @State private var activeTooltip: TooltipType? = nil
    enum TooltipType { case questionnaire, osmolarity, meibography, tmh, mmp9, ipl, rf }
    
    @State private var showingDatePicker = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Color.white
                    .frame(height: 120)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text(LocalizedStringKey.dryEye.localized())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        eyeSelector
                        dateTimeInlineRow
                        measurementsCard
                        treatmentInfoCard
                        notesCard
                        mmp9Card
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
                    .padding(.horizontal, currentLanguage == .french ? 8 : 16)
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
        .sheet(isPresented: $showingQuestionnaire) {
            NavigationStack {
                OSDIQuestionnaireView(questionnaire: $osdiQuestionnaire, showingScoreCalculationInfo: $showingScoreCalculationInfo)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.regularMaterial)
            .presentationCornerRadius(16)
        }
        .alert(LocalizedStringKey.error.localized(), isPresented: $showingError) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(LocalizedStringKey.editMeasurement.localized(), isPresented: $showingEditWarning) {
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
            Button(LocalizedStringKey.continue.localized(), role: .destructive) {
                saveMeasurement()
            }
        } message: {
            Text(LocalizedStringKey.editMeasurementWarning.localized())
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey.cancel.localized()) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey.save.localized()) { dismiss() }
            }
        }
        .onAppear {
            if let existingMeasurement = existingMeasurement {
                // Prefill the form with existing data
                date = existingMeasurement.date
                osmolarity = existingMeasurement.osmolarity.map { String($0) } ?? ""
                meibographyPercentLoss = existingMeasurement.meibographyPercentLoss.map { String($0) } ?? ""
                hadIPLOrRF = existingMeasurement.hadIPLOrRF
                hadRadioFrequency = existingMeasurement.hasRadioFrequency
                nextIPLDate = existingMeasurement.nextIPLDate
                nextRadioFrequencyDate = existingMeasurement.nextRadioFrequencyDate
                tmh = existingMeasurement.tmh.map { String($0) } ?? ""
                mmp9 = existingMeasurement.mmp9
                mmp9Note = existingMeasurement.mmp9Note ?? ""
                notes = existingMeasurement.notes ?? ""
                
                // Prefill OSDI questionnaire if it exists
                if existingMeasurement.dryEyeQuestionnaire > 0 {
                    // Create a questionnaire response that matches the existing score
                    // This is a simplified approach - ideally you'd store and restore the actual questionnaire responses
                    var questionnaireResponse = OSDIQuestionnaireResponse()
                    // For now, we'll create a basic response that approximates the score
                    // In a full implementation, you'd want to store and restore the actual questionnaire responses
                    let targetScore = Int(existingMeasurement.dryEyeQuestionnaire)
                    // Set some default responses to approximate the score
                    // This is a simplified approach
                    questionnaireResponse.symptomResponses = [targetScore / 5, targetScore / 5, targetScore / 5, targetScore / 5, targetScore / 5]
                    questionnaireResponse.functionResponses = [targetScore / 4, targetScore / 4, targetScore / 4, targetScore / 4]
                    questionnaireResponse.environmentalResponses = [targetScore / 3, targetScore / 3, targetScore / 3]
                    osdiQuestionnaire = questionnaireResponse
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
            
            // OSDI Questionnaire Button
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    (
                        Text(LocalizedStringKey.osdiScore.localized())
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
                            Text("\(osdiQuestionnaire.totalScore)")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                            Text("/ \(osdiQuestionnaire.maxPossibleScore)")
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
                    Text(LocalizedStringKey.ocularSurfaceDiseaseIndex.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: { activeTooltip = .questionnaire }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 10)
            Divider()
            
            MeasurementRowModern(
                label: LocalizedStringKey.osmolarity.localized(),
                value: $osmolarity,
                placeholder: LocalizedStringKey.osmolarityExample.localized(),
                unit: LocalizedStringKey.mosmL.localized(),
                isNumber: true,
                description: LocalizedStringKey.tearFilmOsmolarity.localized(),
                infoAction: { activeTooltip = .osmolarity },
                isRequired: false
            )
            
            MeasurementRowModern(
                label: LocalizedStringKey.meibography.localized(),
                value: $meibographyPercentLoss,
                placeholder: LocalizedStringKey.meibographyExample.localized(),
                unit: LocalizedStringKey.percent.localized(),
                isNumber: true,
                description: LocalizedStringKey.glandLossPercentage.localized(),
                infoAction: { activeTooltip = .meibography },
                isRequired: false
            )
            
            MeasurementRowModern(
                label: LocalizedStringKey.tearMeniscusHeight.localized(),
                value: $tmh,
                placeholder: LocalizedStringKey.tmhExample.localized(),
                unit: LocalizedStringKey.mm.localized(),
                isNumber: true,
                description: LocalizedStringKey.tmhMeasurement.localized(),
                infoAction: { activeTooltip = .tmh },
                isRequired: false,
                showDivider: false
            )
        }
        .padding(.vertical, 18)
        .padding(.horizontal, currentLanguage == .french ? 8 : 16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    private var treatmentInfoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.followUpReminder.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 4)

            ToggleRowModern(
                label: LocalizedStringKey.iplTreatment.localized(),
                value: $hadIPLOrRF,
                description: LocalizedStringKey.iplDescription.localized(),
                infoType: .ipl,
                infoAction: { activeTooltip = .ipl },
                useAccentColor: true
            )
            
            if hadIPLOrRF {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizedStringKey.nextIplTreatment.localized())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: {
                            nextIPLDate = nextIPLDate == nil ? Date() : nil
                        }) {
                            Text(nextIPLDate == nil ? LocalizedStringKey.setDate.localized() : LocalizedStringKey.clearDate.localized())
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    if let nextIPLDate = nextIPLDate {
                        DatePicker(LocalizedStringKey.nextIplTreatment.localized(), selection: Binding(
                            get: { nextIPLDate },
                            set: { self.nextIPLDate = $0 }
                        ), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 8)
            }
            
            ToggleRowModern(
                label: LocalizedStringKey.radioFrequency.localized(),
                value: $hadRadioFrequency,
                description: LocalizedStringKey.rfDescription.localized(),
                infoType: .rf,
                infoAction: { activeTooltip = .rf },
                useAccentColor: true
            )
            
            if hadRadioFrequency {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizedStringKey.nextRfTreatment.localized())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: {
                            nextRadioFrequencyDate = nextRadioFrequencyDate == nil ? Date() : nil
                        }) {
                            Text(nextRadioFrequencyDate == nil ? LocalizedStringKey.setDate.localized() : LocalizedStringKey.clearDate.localized())
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    if let nextRadioFrequencyDate = nextRadioFrequencyDate {
                        DatePicker(LocalizedStringKey.nextRfTreatment.localized(), selection: Binding(
                            get: { nextRadioFrequencyDate },
                            set: { self.nextRadioFrequencyDate = $0 }
                        ), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, currentLanguage == .french ? 8 : 16)
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
        .padding(.horizontal, currentLanguage == .french ? 8 : 16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    private var mmp9Card: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey.mmp9Marker.localized())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            ToggleRowModern(
                label: LocalizedStringKey.mmp9Positive.localized(),
                value: $mmp9,
                description: LocalizedStringKey.inflammationMarker.localized(),
                infoType: .mmp9,
                infoAction: { activeTooltip = .mmp9 },
                useAccentColor: true
            )
            
            if mmp9 {
                MMP9NoteRow(value: $mmp9Note)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, currentLanguage == .french ? 8 : 16)
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
            .padding(.horizontal, currentLanguage == .french ? 8 : 16)
            .padding(.bottom, 16)
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
        isRequired: Bool,
        showDivider: Bool = true
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
        if showDivider {
            Divider()
        }
    }

    // toggle row with Yes/No pill buttons
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

    // MMP9 Note Row
    @ViewBuilder
    private func MMP9NoteRow(value: Binding<String>) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()
            Text(LocalizedStringKey.note.localized())
                .font(.subheadline)
                .foregroundColor(.primary)

            TextField(LocalizedStringKey.optionalNote.localized(), text: value)
                .textFieldStyle(PlainTextFieldStyle())
                .frame(width: 150)
                .multilineTextAlignment(.trailing)
                .font(.subheadline)
                .foregroundColor(.primary)
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

    // MARK: - Tooltip Texts
    @ViewBuilder
    private func TooltipTextView(for type: TooltipType) -> some View {
        switch type {
        case .questionnaire:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.osdiDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                (
                    VStack(spacing: 4) {
                        Text("0 ≤ \(LocalizedStringKey.normal.localized()) < 13")
                            .foregroundColor(.green)
                        Text("13 ≤ \(LocalizedStringKey.mild.localized()) < 23")
                            .foregroundColor(.yellow)
                        Text("23 ≤ \(LocalizedStringKey.moderate.localized()) < 33")
                            .foregroundColor(.orange)
                        Text("33 ≤ \(LocalizedStringKey.severe.localized()) ≤ 100")
                            .foregroundColor(.red)
                    }
                )
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(0.9)
                .padding(.top, 12)
            }
        case .osmolarity:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.osmolarityDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text("\(LocalizedStringKey.normalRange.localized()): \(LocalizedStringKey.normalRangeOsmolarity.localized())")
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(0.9)
                    .padding(.top, 12)
            }

        case .meibography:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.meibographyDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                (
                    Text("\(LocalizedStringKey.normal.localized()): \(LocalizedStringKey.normalRangeMeibography.localized())")
                        .foregroundColor(.green)
                    + Text(" | ")
                        .foregroundColor(.gray)
                    + Text("\(LocalizedStringKey.moderate.localized()): \(LocalizedStringKey.moderateRange.localized())")
                        .foregroundColor(.orange)
                    + Text(" | ")
                        .foregroundColor(.gray)
                    + Text("\(LocalizedStringKey.severe.localized()): \(LocalizedStringKey.severeRange.localized())")
                        .foregroundColor(.red)
                )
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(0.9)
                .padding(.top, 12)
            }
        case .tmh:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.tmhDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text("\(LocalizedStringKey.normalRange.localized()): \(LocalizedStringKey.normalRangeTmh.localized())")
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(0.9)
                    .padding(.top, 12)
            }

        case .mmp9:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.mmp9Description.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
            }
        case .ipl:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.iplDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.iplDescription2.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
            }
        case .rf:
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey.rfDescription.localized())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(-2)
                Text(LocalizedStringKey.rfDescription2.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func tooltipTitle(for type: TooltipType) -> String {
        switch type {
        case .questionnaire: return LocalizedStringKey.osdiQuestionnaire.localized()
        case .osmolarity: return LocalizedStringKey.osmolarity.localized()
        case .meibography: return LocalizedStringKey.meibography.localized()
        case .tmh: return LocalizedStringKey.tearMeniscusHeight.localized()
        case .mmp9: return LocalizedStringKey.mmp9Positive.localized()
        case .ipl: return LocalizedStringKey.ipl.localized()
        case .rf: return LocalizedStringKey.radioFrequency.localized()
        }
    }
    
    private var isValid: Bool {
        return osdiQuestionnaire.isComplete
    }
    
    private func saveMeasurement() {
        let osmolarityValue = Double(osmolarity)
        let meibographyValue = Double(meibographyPercentLoss)
        let tmhValue = Double(tmh)
        let mmp9NoteValue = mmp9Note.isEmpty ? nil : mmp9Note
        
        if isEditing {
            // Update existing measurement
            guard let existingMeasurement = existingMeasurement else { return }
            
            let updatedMeasurement = DryEyeMeasurement(
                id: existingMeasurement.id,
                date: date,
                eye: selectedEye,
                dryEyeQuestionnaire: osdiQuestionnaire.osdiScore,
                notes: notes.isEmpty ? nil : notes,
                osmolarity: osmolarityValue,
                meibographyPercentLoss: meibographyValue,
                hadIPLOrRF: hadIPLOrRF,
                hadRadioFrequency: hadRadioFrequency,
                nextIPLDate: nextIPLDate,
                nextRadioFrequencyDate: nextRadioFrequencyDate,
                tmh: tmhValue,
                mmp9: mmp9,
                mmp9Note: mmp9NoteValue,
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
            let measurement = DryEyeMeasurement(
                date: date,
                eye: selectedEye,
                dryEyeQuestionnaire: osdiQuestionnaire.osdiScore,
                notes: notes.isEmpty ? nil : notes,
                osmolarity: osmolarityValue,
                meibographyPercentLoss: meibographyValue,
                hadIPLOrRF: hadIPLOrRF,
                hadRadioFrequency: hadRadioFrequency,
                nextIPLDate: nextIPLDate,
                nextRadioFrequencyDate: nextRadioFrequencyDate,
                tmh: tmhValue,
                mmp9: mmp9,
                mmp9Note: mmp9NoteValue,
                edited: nil
            )
            
            Task {
                do {
                    try await viewModel.addMeasurement(measurement)
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
        }
    }

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        // Set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    private var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // Set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
}

// Helper for full eye name
extension EyeType {
    var fullName: String {
        switch self {
        case .OD: return LocalizedStringKey.rightEye.localized()
        case .OS: return LocalizedStringKey.leftEye.localized()
        }
    }
}

struct DryEyeDataEntryView_Previews: PreviewProvider {
    static var previews: some View {
    NavigationStack {
        DryEyeDataEntryView(
            viewModel: DryEyeViewModel(),
            selectedEye: .OD
        )
        }
    }
}

// MARK: - OSDI Questionnaire Response
struct OSDIQuestionnaireResponse {
    var symptomResponses: [Int] = Array(repeating: -1, count: 5) // 5 symptom questions, -1 for unselected, 0-4 for selected
    var functionResponses: [Int] = Array(repeating: -1, count: 4) // 4 function questions, -1 for unselected, 0-4 for selected
    var environmentalResponses: [Int] = Array(repeating: -1, count: 3) // 3 environmental questions, -1 for unselected, 0-4 for selected
    
    var totalScore: Int {
        let symptomScore = symptomResponses.filter { $0 >= 0 }.reduce(0, +)
        let functionScore = functionResponses.filter { $0 >= 0 }.reduce(0, +)
        let environmentalScore = environmentalResponses.filter { $0 >= 0 }.reduce(0, +)
        return symptomScore + functionScore + environmentalScore
    }
    
    var maxPossibleScore: Int {
        return 100
    }
    
    var isComplete: Bool {
        return symptomResponses.allSatisfy { $0 >= 0 } && functionResponses.allSatisfy { $0 >= 0 } && environmentalResponses.allSatisfy { $0 >= 0 }
    }
    
    var symptomScore: Int {
        return symptomResponses.filter { $0 >= 0 }.reduce(0, +)
    }
    
    var functionScore: Int {
        return functionResponses.filter { $0 >= 0 }.reduce(0, +)
    }
    
    var environmentalScore: Int {
        return environmentalResponses.filter { $0 >= 0 }.reduce(0, +)
    }
    
    // OSDI Score calculation: (sum of scores) × 25 / (number of questions answered)
    var osdiScore: Double {
        let answeredQuestions = symptomResponses.filter { $0 >= 0 }.count +
                              functionResponses.filter { $0 >= 0 }.count +
                              environmentalResponses.filter { $0 >= 0 }.count
        guard answeredQuestions > 0 else { return 0 }
        return Double(totalScore) * 25.0 / Double(answeredQuestions)
    }
    
    // Severity classification based on OSDI score
    var severityLevel: String {
        switch osdiScore {
        case 0..<13:
            return LocalizedStringKey.normal.localized()
        case 13..<23:
            return LocalizedStringKey.mild.localized()
        case 23..<33:
            return LocalizedStringKey.moderate.localized()
        default:
            return LocalizedStringKey.severe.localized()
        }
    }
    
    var severityColor: Color {
        switch severityLevel {
        case LocalizedStringKey.normal.localized():
            return .green
        case LocalizedStringKey.mild.localized():
            return .yellow
        case LocalizedStringKey.moderate.localized():
            return .orange
        case LocalizedStringKey.severe.localized():
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - OSDI Questionnaire View
struct OSDIQuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var questionnaire: OSDIQuestionnaireResponse
    @Binding var showingScoreCalculationInfo: Bool
    @State private var showingIncompleteAlert = false
    
    private var options: [String] {
        [LocalizedStringKey.noneOfTime.localized(), LocalizedStringKey.someOfTime.localized(), LocalizedStringKey.halfOfTime.localized(), LocalizedStringKey.mostOfTime.localized(), LocalizedStringKey.allOfTime.localized()]
    }
    
    private var symptomQuestions: [String] {
        [
            LocalizedStringKey.eyesSensitiveLight.localized(),
            LocalizedStringKey.eyesFeelGritty.localized(),
            LocalizedStringKey.painfulSoreEyes.localized(),
            LocalizedStringKey.blurredVision.localized(),
            LocalizedStringKey.poorVision.localized()
        ]
    }
    
    private var functionQuestions: [String] {
        [
            LocalizedStringKey.reading.localized(),
            LocalizedStringKey.drivingNight.localized(),
            LocalizedStringKey.computerAtm.localized(),
            LocalizedStringKey.watchingTv.localized()
        ]
    }
    
    private var environmentalQuestions: [String] {
        [
            LocalizedStringKey.windyConditions.localized(),
            LocalizedStringKey.lowHumidity.localized(),
            LocalizedStringKey.airConditioned.localized()
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey.dryEyeAssessment.localized())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        
                        Text(LocalizedStringKey.osdiQuestionnaire.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.osdiInstructions1.localized())
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                        
                        Text(LocalizedStringKey.osdiInstructions2.localized())
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Section 1: Symptom Questions
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.eyeSymptoms.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text(LocalizedStringKey.symptomQuestionPrompt.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Questions
                    VStack(spacing: 12) {
                        ForEach(0..<symptomQuestions.count, id: \.self) { index in
                            ModernQuestionCard(
                                question: symptomQuestions[index],
                                options: options,
                                selectedIndex: $questionnaire.symptomResponses[index],
                                questionNumber: index + 1,
                                accentColor: .blue
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Section 2: Function Questions
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.dailyActivities.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        Text(LocalizedStringKey.functionQuestionPrompt.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Questions
                    VStack(spacing: 12) {
                        ForEach(0..<functionQuestions.count, id: \.self) { index in
                            ModernQuestionCard(
                                question: functionQuestions[index],
                                options: options,
                                selectedIndex: $questionnaire.functionResponses[index],
                                questionNumber: symptomQuestions.count + index + 1,
                                accentColor: .purple
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Section 3: Environmental Questions
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.environmentalFactors.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                        Text(LocalizedStringKey.environmentalQuestionPrompt.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Questions
                    VStack(spacing: 12) {
                        ForEach(0..<environmentalQuestions.count, id: \.self) { index in
                            ModernQuestionCard(
                                question: environmentalQuestions[index],
                                options: options,
                                selectedIndex: $questionnaire.environmentalResponses[index],
                                questionNumber: symptomQuestions.count + functionQuestions.count + index + 1,
                                accentColor: .mint
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
                    Text(LocalizedStringKey.sourceSchiffman.localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(1)
                    
                    Text("© 2000 American Medical Association")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(LocalizedStringKey.osdi12.localized())
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
        .navigationTitle(LocalizedStringKey.osdiQuestionnaire.localized())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizedStringKey.cancel.localized()) {
                    // Reset all entries and dismiss
                    questionnaire = OSDIQuestionnaireResponse()
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
            FloatingOSDIScoreSummary(questionnaire: questionnaire, showingScoreCalculationInfo: $showingScoreCalculationInfo)
        }
        .alert(LocalizedStringKey.incompleteQuestionnaire.localized(), isPresented: $showingIncompleteAlert) {
            Button(LocalizedStringKey.continue.localized(), role: .cancel) { }
        } message: {
            Text(LocalizedStringKey.answerAllQuestions.localized())
        }
        .overlay {
            if showingScoreCalculationInfo {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingScoreCalculationInfo = false
                    }
                
                OSDIScoreCalculationPopupView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingScoreCalculationInfo)
    }
}

// MARK: - Floating OSDI Score Summary
struct FloatingOSDIScoreSummary: View {
    let questionnaire: OSDIQuestionnaireResponse
    @Binding var showingScoreCalculationInfo: Bool
    
    private let symptomQuestions = 5
    private let functionQuestions = 4
    private let environmentalQuestions = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Floating card with shadow
            VStack(spacing: 16) {
                // Main Score with Info Button
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(LocalizedStringKey.osdiScore.localized()): ")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "4437EB"))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(String(format: "%.1f", questionnaire.osdiScore))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "4437EB"))
                        Text("/")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "4437EB"))
                        Text("100")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "4437EB"))
                        
                        // Info Button
                        Button(action: {
                            showingScoreCalculationInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Severity Level
                    HStack(spacing: 4) {
                        Text(questionnaire.severityLevel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(severityTextColor)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(severityBackgroundColor)
                            )
                    }
                }
                
                // Sub-scores
                HStack(spacing: 8) {
                    // Symptom Score
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey.eyeSymptoms.localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(questionnaire.symptomScore)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("/")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(symptomQuestions * 4)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Vertical divider
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 32)
                    
                    // Function Score
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey.dailyActivities.localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(questionnaire.functionScore)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                            Text("/")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(functionQuestions * 4)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Vertical divider
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 32)
                    
                    // Environmental Score
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey.environmentalFactors.localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(questionnaire.environmentalScore)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.mint)
                            Text("/")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(environmentalQuestions * 4)")
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
    
    private var severityTextColor: Color {
        switch questionnaire.severityLevel {
        case LocalizedStringKey.normal.localized(): return .green
        case LocalizedStringKey.mild.localized(): return .yellow
        case LocalizedStringKey.moderate.localized(): return .orange
        case LocalizedStringKey.severe.localized(): return .red
        default: return .gray
        }
    }
    
    private var severityBackgroundColor: Color {
        switch questionnaire.severityLevel {
        case LocalizedStringKey.normal.localized(): return .green.opacity(0.15)
        case LocalizedStringKey.mild.localized(): return .yellow.opacity(0.15)
        case LocalizedStringKey.moderate.localized(): return .orange.opacity(0.15)
        case LocalizedStringKey.severe.localized(): return .red.opacity(0.15)
        default: return .gray.opacity(0.15)
        }
    }
}

// MARK: - OSDI Score Calculation Popup View
struct OSDIScoreCalculationPopupView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Popup content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                        Text(LocalizedStringKey.osdiScoreCalculation.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                            
                            Spacer()
                            
                            Button(action: {
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(LocalizedStringKey.howCalculated.localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Formula Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.formula.localized())
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(spacing: 2) {
                                Text(LocalizedStringKey.sumOfScores.localized())
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1)
                                    .padding(.horizontal, 20)
                                
                                Text(LocalizedStringKey.questionsAnswered.localized())
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                           
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.responsePointScale.localized())
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 6) {
                                Text("0 = \(LocalizedStringKey.noneOfTime.localized())")
                                    .font(.subheadline)
                                    .foregroundColor(.green)

                                Text("1 = \(LocalizedStringKey.someOfTime.localized())")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)

                                Text("2 = \(LocalizedStringKey.halfOfTime.localized())")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)

                                Text("3 = \(LocalizedStringKey.mostOfTime.localized())")
                                    .font(.subheadline)
                                    .foregroundColor(.red)

                                Text("4 = \(LocalizedStringKey.allOfTime.localized())")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.severityClassification.localized())
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 6) {
                                Text("0 ≤ \(LocalizedStringKey.normal.localized()) < 13")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
       
                                Text("13 ≤ \(LocalizedStringKey.mild.localized()) < 23")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.yellow)
       
                                Text("23 ≤ \(LocalizedStringKey.moderate.localized()) < 33")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                    
                                Text("33 ≤ \(LocalizedStringKey.severe.localized()) ≤ 100")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .frame(maxWidth: 400)
            .frame(maxHeight: 600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
