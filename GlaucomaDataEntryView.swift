import SwiftUI
import FirebaseAuth

struct GlaucomaDataEntryView: View {
    @ObservedObject var viewModel: GlaucomaViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let selectedEye: EyeType
    let existingMeasurement: GlaucomaMeasurement?
    
    @State private var eyeSelection: EyeType
    @State private var date = Date()
    @State private var iop = ""
    @State private var iopTime = Date()
    @State private var meanDefect = ""
    @State private var patternStandardDeviation = ""
    @State private var rnflOverall = ""
    @State private var rnflSuperior = ""
    @State private var rnflInferior = ""
    @State private var macularGCC = ""
    @State private var hasVisualFieldChange = false
    @State private var hasRNFLChange = false
    @State private var hasGlaucomaFamilyHistory = false
    @State private var hasLasikSurgery = false
    @State private var newEyeDrops = false
    @State private var eyeDropsDetails = ""
    @State private var notes = ""
    @State private var showingDatePicker = false
    @State private var showingIOPTimePicker = false
    @State private var activeTooltip: SharedTooltipType? = nil
    
    // Computed property to determine if we're editing
    private var isEditing: Bool {
        return existingMeasurement != nil
    }
    
    // Initializer for new measurements
    init(viewModel: GlaucomaViewModel, selectedEye: EyeType) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = nil
        self.eyeSelection = selectedEye
    }
    
    // Initializer for editing existing measurements
    init(viewModel: GlaucomaViewModel, selectedEye: EyeType, existingMeasurement: GlaucomaMeasurement) {
        self.viewModel = viewModel
        self.selectedEye = selectedEye
        self.existingMeasurement = existingMeasurement
        self.eyeSelection = existingMeasurement.eye
    }
    
    var body: some View {
        BaseDataEntryView(
            title: LocalizedStringKey.glaucoma.localized(),
            isEditing: isEditing,
            onSave: saveMeasurement
        ) {
            VStack(spacing: AppConstants.cardSpacing) {
                // Eye Selection
                DataEntryEyeToggleView(selectedEye: $eyeSelection)
                    .accessibilityElement(children: .combine)
                
                // Date Selection
                CardContainer {
                    VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                        SectionHeader(title: "date_and_time".localized())
                        
                        Button(action: { showingDatePicker = true }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(dateFormatted)
                                        .font(AppConstants.headlineFont)
                                        .foregroundColor(.primary)
                                    Text(timeFormatted)
                                        .font(AppConstants.captionFont)
                                        .foregroundColor(AppConstants.textGray)
                                }
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(AppConstants.primaryBlue)
                            }
                        }
                        .accessibilityLabel("date_time_selection".localized())
                        .accessibilityValue("\(dateFormatted) at \(timeFormatted)")
                    }
                }
                .sheet(isPresented: $showingDatePicker) {
                    NavigationView {
                        DatePicker(
                            "Select Date & Time",
                            selection: $date,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding()
                        .navigationTitle("select_date_time".localized())
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("done".localized()) {
                                    showingDatePicker = false
                                }
                            }
                        }
                    }
                }
                
                // IOP Measurement
                CardContainer {
                    VStack(spacing: AppConstants.smallPadding) {
                        SharedInputField(
                            title: "intraocular_pressure_iop".localized(),
                            placeholder: "enter_iop_value".localized(),
                            text: $iop,
                            tooltip: .iop,
                            onTooltipTap: { activeTooltip = .iop },
                            keyboardType: .decimalPad,
                            isRequired: true
                        )
                        
                        Button(action: { showingIOPTimePicker = true }) {
                            HStack {
                                Text("iop_time".localized() + ": \(iopTimeFormatted)")
                                    .font(AppConstants.bodyFont)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "clock")
                                    .foregroundColor(AppConstants.primaryBlue)
                            }
                        }
                        .accessibilityLabel("iop_time_selection".localized())
                        .accessibilityValue(iopTimeFormatted)
                        .accessibilityHint("double_tap_change_iop_time".localized())
                    }
                }
                .sheet(isPresented: $showingIOPTimePicker) {
                    NavigationView {
                        DatePicker(
                            "IOP Measurement Time",
                            selection: $iopTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                        .navigationTitle("iop_time".localized())
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("done".localized()) {
                                    showingIOPTimePicker = false
                                }
                            }
                        }
                    }
                }
                
                // Visual Field Parameters
                CardContainer {
                    VStack(spacing: AppConstants.smallPadding) {
                        SectionHeader(title: "visual_field_parameters".localized())
                        
                        SharedInputField(
                            title: "mean_defect_md".localized(),
                            placeholder: "enter_md_value".localized(),
                            text: $meanDefect,
                            tooltip: .md,
                            onTooltipTap: { activeTooltip = .md },
                            keyboardType: .decimalPad
                        )
                        
                        SharedInputField(
                            title: "pattern_standard_deviation_psd".localized(),
                            placeholder: "enter_psd_value".localized(),
                            text: $patternStandardDeviation,
                            tooltip: .psd,
                            onTooltipTap: { activeTooltip = .psd },
                            keyboardType: .decimalPad
                        )
                    }
                }
                
                // OCT Measurements
                CardContainer {
                    VStack(spacing: AppConstants.smallPadding) {
                        SectionHeader(title: "oct_measurements".localized())
                        
                        SharedInputField(
                            title: "rnfl_overall".localized(),
                            placeholder: "enter_overall_rnfl".localized(),
                            text: $rnflOverall,
                            tooltip: .rnfl,
                            onTooltipTap: { activeTooltip = .rnfl },
                            keyboardType: .numberPad
                        )
                        
                        HStack(spacing: AppConstants.smallPadding) {
                            SharedInputField(
                                title: "rnfl_superior".localized(),
                                placeholder: "superior".localized(),
                                text: $rnflSuperior,
                                tooltip: .rnfl,
                                onTooltipTap: { activeTooltip = .rnfl },
                                keyboardType: .numberPad
                            )
                            
                            SharedInputField(
                                title: "rnfl_inferior".localized(),
                                placeholder: "inferior".localized(),
                                text: $rnflInferior,
                                tooltip: .rnfl,
                                onTooltipTap: { activeTooltip = .rnfl },
                                keyboardType: .numberPad
                            )
                        }
                        
                        SharedInputField(
                            title: "macular_gcc".localized(),
                            placeholder: "enter_gcc_value".localized(),
                            text: $macularGCC,
                            tooltip: .gcc,
                            onTooltipTap: { activeTooltip = .gcc },
                            keyboardType: .numberPad
                        )
                    }
                }
                
                // Clinical Changes
                CardContainer {
                    VStack(spacing: AppConstants.smallPadding) {
                        SectionHeader(title: "Clinical Changes")
                        
                        SharedToggleField(
                            title: "Visual Field Change",
                            isOn: $hasVisualFieldChange
                        )
                        
                        SharedToggleField(
                            title: "RNFL Change",
                            isOn: $hasRNFLChange
                        )
                    }
                }
                
                // Patient History
                CardContainer {
                    VStack(spacing: AppConstants.smallPadding) {
                        SectionHeader(title: "Patient History")
                        
                        SharedToggleField(
                            title: "Glaucoma Family History",
                            isOn: $hasGlaucomaFamilyHistory
                        )
                        
                        SharedToggleField(
                            title: "LASIK Surgery History",
                            isOn: $hasLasikSurgery
                        )
                    }
                }
                
                // Medication Changes
                CardContainer {
                    VStack(spacing: AppConstants.smallPadding) {
                        SectionHeader(title: "Medication Changes")
                        
                        SharedToggleField(
                            title: "New Eye Drops",
                            isOn: $newEyeDrops
                        )
                        
                        if newEyeDrops {
                            SharedInputField(
                                title: "Eye Drops Details",
                                placeholder: "Describe the new eye drops",
                                text: $eyeDropsDetails,
                                keyboardType: .default
                            )
                        }
                    }
                }
                
                // Notes
                CardContainer {
                    VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                        Text(LocalizedStringKey.notes.localized())
                            .font(AppConstants.bodyFont)
                            .fontWeight(.medium)
                        
                        TextField("Add any additional notes...", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .accessibilityLabel("Notes field")
                            .accessibilityValue(notes.isEmpty ? "Empty" : notes)
                    }
                }
            }
        }
        .overlay(
            TooltipOverlay(tooltip: activeTooltip) {
                activeTooltip = nil
            }
        )
        .onAppear {
            loadExistingData()
        }
    }
    
    // MARK: - Helper Methods
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
    
    private var iopTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: iopTime)
    }
    
    private func loadExistingData() {
        guard let measurement = existingMeasurement else { return }
        
        date = measurement.date
        iop = String(measurement.iop)
        iopTime = measurement.iopTime
        meanDefect = String(measurement.meanDefect)
        patternStandardDeviation = String(measurement.patternStandardDeviation)
        rnflOverall = String(measurement.rnflOverall)
        rnflSuperior = String(measurement.rnflSuperior)
        rnflInferior = String(measurement.rnflInferior)
        macularGCC = String(measurement.macularGCC)
        hasVisualFieldChange = measurement.hasVisualFieldChange
        hasRNFLChange = measurement.hasRNFLChange
        hasGlaucomaFamilyHistory = measurement.hasGlaucomaFamilyHistory
        hasLasikSurgery = measurement.hasLasikSurgery
        newEyeDrops = measurement.newEyeDrops
        eyeDropsDetails = measurement.eyeDropsDetails ?? ""
        notes = measurement.notes ?? ""
    }
    
    private func saveMeasurement() {
        // Validate required fields
        guard !iop.isEmpty else {
            // Handle validation error
            return
        }
        
        guard let iopValue = Double(iop) else {
            // Handle conversion error
            return
        }
        
        let meanDefectValue = Double(meanDefect) ?? 0.0
        let patternStandardDeviationValue = Double(patternStandardDeviation) ?? 0.0
        let rnflOverallValue = Int(rnflOverall) ?? 0
        let rnflSuperiorValue = Int(rnflSuperior) ?? 0
        let rnflInferiorValue = Int(rnflInferior) ?? 0
        let macularGCCValue = Int(macularGCC) ?? 0
        
        let measurement = GlaucomaMeasurement(
            id: existingMeasurement?.id,
            userId: Auth.auth().currentUser?.uid ?? "",
            date: date,
            eye: eyeSelection,
            hasGlaucomaFamilyHistory: hasGlaucomaFamilyHistory,
            hasLasikSurgery: hasLasikSurgery,
            iop: iopValue,
            iopTime: iopTime,
            meanDefect: meanDefectValue,
            patternStandardDeviation: patternStandardDeviationValue,
            rnflOverall: rnflOverallValue,
            rnflSuperior: rnflSuperiorValue,
            rnflInferior: rnflInferiorValue,
            macularGCC: macularGCCValue,
            hasVisualFieldChange: hasVisualFieldChange,
            hasRNFLChange: hasRNFLChange,
            newEyeDrops: newEyeDrops,
            eyeDropsDetails: eyeDropsDetails.isEmpty ? nil : eyeDropsDetails,
            notes: notes.isEmpty ? nil : notes,
            edited: isEditing
        )
        
        Task {
            do {
                try await viewModel.addMeasurement(measurement)
            } catch {
                // Handle error
                print("Error saving measurement: \(error)")
            }
        }
    }
}

#Preview {
    GlaucomaDataEntryView(
        viewModel: GlaucomaViewModel(),
        selectedEye: .OD
    )
    .environmentObject(LocalizationManager.shared)
}
