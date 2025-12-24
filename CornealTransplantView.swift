import SwiftUI
import FirebaseFirestore

// Add UIRectCorner extension for custom corner radius
extension UIRectCorner {
    static var topLeft: UIRectCorner { return UIRectCorner(rawValue: 1 << 0) }
    static var bottomLeft: UIRectCorner { return UIRectCorner(rawValue: 1 << 1) }
}

// Helper to format a date as a short string for x-axis labels
private func formatDateShort(_ date: Date, language: Language = .english) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    formatter.locale = Locale(identifier: language == .french ? "fr_FR" : "en_US")
    return formatter.string(from: date)
}


// Custom corner shape for custom corner radius
struct CustomCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                               byRoundingCorners: corners,
                               cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct CornealTransplantView: View {
    @StateObject private var viewModel = CornealTransplantViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingDataEntry = false
    @State private var selectedEye: EyeType = .OD
    @State private var selectedDataPointIndex: Int? = nil
    @State private var activeChartId: String? = nil
    @State private var showingInfo = false
    @State private var showingInfoAlert = false
    @State private var currentInfoText = ""
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }

    private var measurements: [TransplantMeasurement] {
        viewModel.getMeasurements(for: selectedEye).sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Disease Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(LocalizedStringKey.aboutCornealTransplant.localized())
                            .font(.headline)
                        Spacer()
                        Button {
                            showingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    
                    Text(LocalizedStringKey.cornealTransplantDescription.localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                                EyeToggleView(selectedEye: $selectedEye)
                    .padding(.horizontal)
                
                HStack {
                    Spacer()
                    Button(action: {
                        if let url = URL(string: "https://www.instagram.com/hautevision_/") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image("instagram")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                            Text(LocalizedStringKey.followUs.localized())
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.top, -12)
                .id(currentLanguage)
                
                // Add Measurement button when there's data
                if !measurements.isEmpty {
                    Button(action: { showingDataEntry = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text(LocalizedStringKey.addMeasurement.localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                // Measurements Over Time title - only show when there's data
                if !measurements.isEmpty {
                    Text(LocalizedStringKey.measurementsOverTime.localized())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                // Graphs Section - only show when there's data
                if !measurements.isEmpty {
                    createGraphCard(
                        title: LocalizedStringKey.specularMicroscopy.localized(),
                        subtitle: LocalizedStringKey.endothelialCellDensity.localized(),
                        data: viewModel.getECDChartData(for: selectedEye),
                        color: .blue,
                        unit: LocalizedStrings.localizedString(for: LocalizedStringKey.cellsPerMm2),
                        chartId: "ecd"
                    )

                    createGraphCard(
                        title: LocalizedStringKey.cornealThickness.localized(),
                        subtitle: LocalizedStringKey.cornealThickness.localized(),
                        data: viewModel.getPachymetryChartData(for: selectedEye),
                        color: .green,
                        unit: LocalizedStrings.localizedString(for: LocalizedStringKey.micrometers),
                        chartId: "pachymetry"
                    )

                    createGraphCard(
                        title: LocalizedStringKey.iop.localized(),
                        subtitle: LocalizedStringKey.intraocularPressure.localized(),
                        data: viewModel.getIOPChartData(for: selectedEye),
                        color: .orange,
                        unit: LocalizedStrings.localizedString(for: LocalizedStringKey.mmHg),
                        chartId: "iop"
                    )
                }

                if let currentMedication = viewModel.getCurrentMedication(for: selectedEye) {
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 6)
                            .clipShape(CustomCorner(radius: 3, corners: [.topLeft, .bottomLeft]))
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentMedication.medicationName ?? LocalizedStringKey.noMedicationRecorded.localized())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    Text(localizedRegimen(currentMedication.steroidRegimen))
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(LocalizedStringKey.lastUpdated.localized()): \(CornealTransplantViewModel.formatDateFull(currentMedication.date, language: currentLanguage))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal)
                }

                // Measurement History Section
                VStack(alignment: .leading, spacing: 12) {
                    // Only show Measurement History title when there's data
                    if !measurements.isEmpty {
                        Text(LocalizedStringKey.measurementHistory.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    if measurements.isEmpty {
                        VStack {
                            Spacer()
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    Image("CornealTransplant")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 140, height: 140)
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text(LocalizedStringKey.noMeasurements.localized())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.accentColor.opacity(0.7))
                                        .id(currentLanguage)
                                    
                                    Text(LocalizedStringKey.addFirstMeasurementToTrack.localized())
                                        .font(.subheadline)
                                        .foregroundColor(Color.accentColor.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .id(currentLanguage)
                                }
                                // Start Tracking button
                                Button(action: { showingDataEntry = true }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text(LocalizedStringKey.startTracking.localized())
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .id(currentLanguage)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .frame(maxWidth: 320)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                    } else {
                        ForEach(measurements) { measurement in
                            CornealTransplantMeasurementRow(measurement: measurement, localizedRegimen: localizedRegimen, viewModel: viewModel)
                                .padding(.vertical, 4)
                        }
                        // Add Measurement button at end of history
                        HStack {
                            Spacer()
                            Button(action: { showingDataEntry = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                    Text(LocalizedStringKey.addMeasurement.localized())
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.accentColor)
                            }
                            Spacer()
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey.cornealTransplant.localized())
        .sheet(isPresented: $showingDataEntry) {
            NavigationStack {
                CornealTransplantDataEntryView(viewModel: viewModel, selectedEye: selectedEye)
            }
        }
        .sheet(isPresented: $showingInfo) {
            NavigationStack {
                CornealTransplantInfoView()
            }
        }
        .alert(LocalizedStringKey.diseaseInformation.localized(), isPresented: $showingInfoAlert) {
            Button(LocalizedStringKey.ok.localized(), role: .cancel) { }
        } message: {
            Text(currentInfoText)
        }
        .task {
            await viewModel.fetchMeasurements()
        }
        .id(currentLanguage) // Force re-render on language change
    }

    private func createGraphCard(
        title: String,
        subtitle: String,
        data: [(Date, Double, Bool)],
        color: Color,
        unit: String,
        chartId: String
    ) -> some View {
        let sortedData = data.sorted(by: { $0.0 < $1.0 })
        let isActive = activeChartId == chartId
        let displayIndex = isActive ? (selectedDataPointIndex ?? (sortedData.count - 1)) : (sortedData.count - 1)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if sortedData.indices.contains(displayIndex) {
                    let displayValue = sortedData[displayIndex].1
                    let displayDate = sortedData[displayIndex].0
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(String(format: "%.0f", displayValue))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                            Text(unit)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        Text(CornealTransplantViewModel.formatDateFull(displayDate, language: currentLanguage))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)

            // Chart content or empty state
            if data.isEmpty {
                // Empty state with message
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey.noData.localized())
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(LocalizedStringKey.addFirstMeasurementToStart.localized())
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: { showingDataEntry = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                            Text(LocalizedStringKey.addMeasurement.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.accentColor.opacity(0.6))
                        .cornerRadius(8)
                        .shadow(color: color.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Chart with integrated Y-axis labels
                UnifiedChartView(
                    data: sortedData,
                    color: color,
                    selectedIndex: isActive ? selectedDataPointIndex : nil,
                    onSelectIndex: { index in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDataPointIndex = index
                        }
                    },
                    onInteractionStart: {
                        activeChartId = chartId
                    },
                    onInteractionEnd: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            activeChartId = nil
                        }
                    },
                    valueFormatter: { value in
                        String(format: "%.0f", value)
                    },
                    currentLanguage: currentLanguage,
                    allowNegativeValues: false,
                    allowDecimals: false,
                    specialBadgeText: chartId == "pachymetry" ? "Regraft" : nil
                )
                .frame(height: 220)
                .padding(.vertical, 5)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .onAppear {
            selectedDataPointIndex = nil
            activeChartId = nil
        }
    }
    
    // Helper function to get measurement type name for empty state
    private func getMeasurementTypeName(_ title: String) -> String {
        if title.contains("Specular Microscopy") || title.contains("ECD") {
            return "endothelial cell density"
        } else if title.contains("Pachymetry") {
            return "corneal thickness"
        } else if title.contains("IOP") {
            return "intraocular pressure"
        } else {
            return title.lowercased()
        }
    }
    
    private func localizedRegimen(_ regimen: String?) -> String {
        guard let regimen = regimen, !regimen.isEmpty else {
            return LocalizedStringKey.noRegimen.localized()
        }
        
        // Map common regimen values to localization keys
        let regimenKey: String
        switch regimen.lowercased() {
        case "daily":
            regimenKey = LocalizedStringKey.daily
        case "weekly":
            regimenKey = LocalizedStringKey.weekly
        case "monthly":
            regimenKey = LocalizedStringKey.monthly
        case "twice daily", "twice_daily":
            regimenKey = LocalizedStringKey.twiceDaily
        case "three times daily", "three_times_daily":
            regimenKey = LocalizedStringKey.threeTimesDaily
        case "every other day", "every_other_day":
            regimenKey = LocalizedStringKey.everyOtherDay
        case "as needed", "as_needed":
            regimenKey = LocalizedStringKey.asNeeded
        default:
            // For custom regimens, return as-is
            return regimen
        }
        
        return LocalizedStrings.localizedString(for: regimenKey)
    }
}

struct CornealTransplantMeasurementRow: View {
    let measurement: TransplantMeasurement
    let localizedRegimen: (String?) -> String
    @ObservedObject var viewModel: CornealTransplantViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with date, time, and action buttons
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(formattedDate(measurement.date))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if measurement.isEdited {
                            Text(LocalizedStringKey.edited.localized())
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(formattedTime(measurement.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status badges
                HStack(spacing: 8) {
                    if measurement.isRegraft {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text(LocalizedStringKey.regraft.localized())
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    
                    // Action buttons
                    HStack(spacing: 6) {
                        Button(action: { showingEditSheet = true }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .frame(width: 32, height: 32)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .disabled(isDeleting)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Main measurements grid
            VStack(spacing: 16) {
                // Top row - Key metrics
                HStack(spacing: 0) {
                    // ECD (Endothelial Cell Density)
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(LocalizedStringKey.specularMicroscopy.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.0f", measurement.ecd))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(LocalizedStrings.localizedString(for: LocalizedStringKey.cellsPerMm2))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 50)
                        .padding(.horizontal, 16)
                    
                    // IOP (Intraocular Pressure)
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.high")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(LocalizedStringKey.iop.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", measurement.iop))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text(LocalizedStrings.localizedString(for: LocalizedStringKey.mmHg))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Bottom row - Additional metrics
                HStack(spacing: 0) {
                    // Corneal Thickness
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "ruler")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(LocalizedStringKey.cornealThickness.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(measurement.pachymetry)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text(LocalizedStrings.localizedString(for: LocalizedStringKey.micrometers))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 50)
                        .padding(.horizontal, 16)
                    
                    // Medication Regimen
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "pills.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text(LocalizedStringKey.medicationRegimen.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        Text(localizedRegimen(measurement.steroidRegimen))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Additional information section
            if (measurement.medicationName != nil && !measurement.medicationName!.isEmpty) ||
               (measurement.steroidRegimen != nil && !measurement.steroidRegimen!.isEmpty) ||
               (measurement.notes != nil && !measurement.notes!.isEmpty) {
                
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    if let medicationName = measurement.medicationName, !medicationName.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "pills")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("\(LocalizedStringKey.medication.localized()): \(medicationName)")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let steroidRegimen = measurement.steroidRegimen, !steroidRegimen.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(LocalizedStringKey.steroidRegimen.localized()): \(localizedRegimen(steroidRegimen))")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let notes = measurement.notes, !notes.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                CornealTransplantDataEntryView(
                    viewModel: viewModel,
                    selectedEye: measurement.eye,
                    existingMeasurement: measurement
                )
            }
        }
        .alert(LocalizedStringKey.deleteMeasurement.localized(), isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
            Button(LocalizedStringKey.deleteConfirmation.localized(), role: .destructive) {
                deleteMeasurement()
            }
        } message: {
            Text(LocalizedStringKey.deleteMeasurementConfirmation.localized())
        }
    }

    private func deleteMeasurement() {
        isDeleting = true
        Task {
            do {
                try await viewModel.deleteMeasurement(measurement)
                await MainActor.run {
                    isDeleting = false
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    // Handle error - could show an alert here
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
}

struct CornealTransplantInfoView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text(LocalizedStringKey.cornealTransplantInfo.localized())
                        .font(.title2)
                        .fontWeight(.bold)
                        .id(currentLanguage)
                    
                    Text(LocalizedStringKey.cornealTransplantSurgicalProcedure.localized())
                        .font(.body)
                        .id(currentLanguage)
                }
                
                Group {
                    Text(LocalizedStringKey.keyMeasurements.localized())
                        .font(.headline)
                        .padding(.top)
                        .id(currentLanguage)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        measurementSection(
                            title: "\(LocalizedStringKey.endothelialCellDensity.localized()) (ECD)",
                            description: LocalizedStringKey.ecdDescription.localized()
                        )
                        
                        measurementSection(
                            title: "\(LocalizedStringKey.cornealThickness.localized()) (Pachymetry)",
                            description: LocalizedStringKey.pachymetryDescription.localized()
                        )
                        
                        measurementSection(
                            title: "\(LocalizedStringKey.intraocularPressure.localized()) (IOP)",
                            description: LocalizedStringKey.iopDescription.localized()
                        )
                    }
                }
                
                Group {
                    Text(LocalizedStringKey.medicationManagement.localized())
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        treatmentSection(
                            title: LocalizedStringKey.steroidDrops.localized(),
                            description: LocalizedStringKey.steroidDropsDescription.localized()
                        )
                        
                        treatmentSection(
                            title: LocalizedStringKey.antibioticDrops.localized(),
                            description: LocalizedStringKey.antibioticDropsDescription.localized()
                        )
                        
                        treatmentSection(
                            title: LocalizedStringKey.otherMedications.localized(),
                            description: LocalizedStringKey.otherMedicationsDescription.localized()
                        )
                    }
                }
                
                Group {
                    Text(LocalizedStringKey.warningSigns.localized())
                        .font(.headline)
                        .padding(.top)
                    
                    Text(LocalizedStringKey.warningSignsDescription.localized())
                        .foregroundColor(.red)
                }
                
                Group {
                    Text(LocalizedStringKey.monitoringSchedule.localized())
                        .font(.headline)
                        .padding(.top)
                    
                    Text(LocalizedStringKey.monitoringScheduleDescription.localized())
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey.diseaseInformation.localized())
        .navigationBarTitleDisplayMode(.inline)
        .id(currentLanguage) // Force re-render on language change
    }
    
    private func measurementSection(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .id(currentLanguage)
            Text(description)
                .font(.callout)
                .foregroundColor(.gray)
                .id(currentLanguage)
        }
    }
    
    private func treatmentSection(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .id(currentLanguage)
            Text(description)
                .font(.callout)
                .foregroundColor(.gray)
                .id(currentLanguage)
        }
    }
}


