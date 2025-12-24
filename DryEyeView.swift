import SwiftUI

// Helper to format a date as a short string for x-axis labels
private func formatDateShort(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    // Set locale based on current language
    let currentLanguage = LocalizationManager.shared.currentLanguage
    formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
    return formatter.string(from: date)
}

struct DryEyeView: View {
    @StateObject private var viewModel = DryEyeViewModel()
    @State private var showingAddMeasurement = false
    @State private var selectedEye: EyeType = .OD
    @State private var showingDeleteConfirmation = false
    @State private var measurementToDelete: DryEyeMeasurement?
    @State private var selectedDataPointIndex: Int? = nil
    @State private var activeChartId: String? = nil
    @State private var showingInfo = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Disease Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(LocalizedStringKey.aboutDryEye.localized())
                            .font(.headline)
                            .id(currentLanguage)
                        Spacer()
                        Button {
                            showingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    
                    Text(LocalizedStringKey.trackDryEyeMeasurements.localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .id(currentLanguage)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                
                                // Eye Selection
                EyeToggleView(selectedEye: $selectedEye)
                    .padding(.horizontal)
                
                // Add Measurement button when there's data
                if !viewModel.getMeasurements(for: selectedEye).isEmpty {
                    Button(action: { showingAddMeasurement = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text(LocalizedStringKey.addMeasurement.localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .id(currentLanguage)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    //.padding(.bottom, 8)
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        if let url = URL(string: "https://www.instagram.com/dryeyeinstitutemtl?igsh=bXBqeTllMGhldjFm") {
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
                
                // Measurements Over Time title - only show when there's data
                if !viewModel.getMeasurements(for: selectedEye).isEmpty {
                    Text(LocalizedStringKey.measurementsOverTime.localized())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .id(currentLanguage)
                }
                
                // Graphs Section - only show when there's data
                if !viewModel.getMeasurements(for: selectedEye).isEmpty {
                    createGraphCard(
                        title: LocalizedStringKey.osdiQuestionnaire.localized(),
                        subtitle: LocalizedStringKey.symptomScore.localized(),
                        data: viewModel.getdryEyeQuestionnaireChartData(for: selectedEye),
                        color: .purple,
                        unit: "score",
                        infoText: "A standardized questionnaire that measures dry eye symptoms. Higher scores indicate more severe symptoms.",
                        decimalFormat: "%.0f",
                        chartId: "osdi"
                    )
                    
                    createGraphCard(
                        title: LocalizedStringKey.osmolarity.localized(),
                        subtitle: LocalizedStringKey.tearFilmOsmolarity.localized(),
                        data: viewModel.getOsmolarityChartData(for: selectedEye),
                        color: .blue,
                        unit: "mOsm/L",
                        infoText: "Measures the concentration of particles in tears. Elevated osmolarity indicates tear film instability.",
                        decimalFormat: "%.0f",
                        chartId: "osmolarity"
                    )
                    
                    createGraphCard(
                        title: LocalizedStringKey.meibography.localized(),
                        subtitle: LocalizedStringKey.glandLossPercentage.localized(),
                        data: viewModel.getMeibographyChartData(for: selectedEye),
                        color: .orange,
                        unit: "%",
                        infoText: "Measures the percentage of meibomian glands that are lost or non-functional. Higher percentages indicate more severe gland dysfunction.",
                        decimalFormat: "%.0f",
                        chartId: "meibography"
                    )
                    
                    createGraphCard(
                        title: LocalizedStringKey.tearMeniscusHeight.localized(),
                        subtitle: LocalizedStringKey.tmhMeasurement.localized(),
                        data: viewModel.getTMHChartData(for: selectedEye),
                        color: .teal,
                        unit: "mm",
                        infoText: "Measures the height of the tear film at the lower eyelid margin. Lower values may indicate reduced tear volume.",
                        decimalFormat: "%.2f",
                        chartId: "tmh"
                    )
                }
                
                // Upcoming Treatments Section
                let upcomingTreatments = getAllUpcomingTreatments()
                if !upcomingTreatments.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        // Treatments list with light purple line
                        VStack(alignment: .leading, spacing: 0) {
                            // Title
                            Text(LocalizedStringKey.upcomingTreatments.localized())
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .id(currentLanguage)
                                .padding(.top, -8)
                                .padding(.bottom, 10)
                            
                            ForEach(upcomingTreatments, id: \.self) { treatment in
                                HStack(spacing: 10) {
                                    Image(systemName: "star.fill")
                                        .font(.subheadline)
                                        .foregroundColor(treatment.type == .ipl ? .orange : .purple)
                                    
                                    Text(treatment.type == .ipl ? LocalizedStringKey.nextIplTreatment.localized() : LocalizedStringKey.nextRfTreatment.localized())
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(treatment.type == .ipl ? .orange : .purple)
                                    
                                    Spacer()
                                    
                                    Text(formattedDateShort(treatment.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .background(
                            Rectangle()
                                .fill(Color(.systemBackground))
                                .overlay(
                                    Rectangle()
                                        .fill(Color.purple.opacity(0.15))
                                        .frame(width: 5)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                )
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Measurement History Section
                VStack(alignment: .leading, spacing: 12) {
                    // Only show Measurement History title when there's data
                    if !viewModel.getMeasurements(for: selectedEye).isEmpty {
                        Text(LocalizedStringKey.measurementHistory.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .id(currentLanguage)
                    }
                    
                    if viewModel.getMeasurements(for: selectedEye).isEmpty {
                        VStack {
                            Spacer()
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    Image("DryEye")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 140, height: 140)
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text(LocalizedStringKey.noMeasurements.localized())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.accentColor.opacity(0.7))
                                        .id(currentLanguage)
                                    
                                    Text(LocalizedStringKey.addFirstMeasurement.localized())
                                        .font(.subheadline)
                                        .foregroundColor(Color.accentColor.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .id(currentLanguage)
                                }
                                // Start Tracking button
                                Button(action: { showingAddMeasurement = true }) {
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
                        ForEach(viewModel.getMeasurements(for: selectedEye)) { measurement in
                            DryEyeMeasurementCard(measurement: measurement, viewModel: viewModel)
                                .padding(.vertical, 4)
                        }
                    }
                                        // Add Measurement button at end of history (only when there's data)
                    if !viewModel.getMeasurements(for: selectedEye).isEmpty {
                        HStack {
                            Spacer()
                            Button(action: { showingAddMeasurement = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                    Text(LocalizedStringKey.addMeasurement.localized())
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .id(currentLanguage)
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
        .navigationTitle(LocalizedStringKey.dryEye.localized())
        .id(currentLanguage)
        .sheet(isPresented: $showingAddMeasurement) {
            NavigationStack {
                DryEyeDataEntryView(viewModel: viewModel, selectedEye: selectedEye)
            }
        }
        .sheet(isPresented: $showingInfo) {
            NavigationStack {
                DryEyeInfoView()
            }
        }
        .task {
            await viewModel.fetchMeasurements()
        }
        .refreshable {
            await viewModel.fetchMeasurements()
        }
    }
    
    
    private func createGraphCard(
        title: String,
        subtitle: String,
        data: [(Date, Double, Bool)],
        color: Color,
        unit: String,
        infoText: String? = nil,
        decimalFormat: String = "%.1f",
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
                            Text(String(format: decimalFormat, displayValue))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                            Text(unit)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        Text(formatDateFull(displayDate))
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
                    
                    Button(action: { showingAddMeasurement = true }) {
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
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.7), color.opacity(0.5)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                    data: data.sorted(by: { $0.0 < $1.0 }),
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
                        String(format: decimalFormat, value)
                    },
                    currentLanguage: currentLanguage,
                    allowNegativeValues: false,
                    allowDecimals: chartId == "tmh",
                    specialBadgeText: chartId == "meibography" ? "RF/IPL" : nil
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
        if title.contains("Questionnaire") || title.contains("Symptom Score") {
            return LocalizedStringKey.symptomScore.localized()
        } else if title.contains("Osmolarity") {
            return LocalizedStringKey.osmolarity.localized()
        } else if title.contains("Meibography") || title.contains("Gland Loss") {
            return LocalizedStringKey.meibography.localized()
        } else if title.contains("TMH") || title.contains("Tear Meniscus") {
            return LocalizedStringKey.tearMeniscusHeight.localized()
        } else {
            return title.lowercased()
        }
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        // Set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Functions
    private func getAllUpcomingTreatments() -> [UpcomingTreatment] {
        let measurements = viewModel.getMeasurements(for: selectedEye)
        var iplAppointments: [UpcomingTreatment] = []
        var rfAppointments: [UpcomingTreatment] = []
        
        for measurement in measurements {
            // Check IPL appointments
            if let nextIPLDate = measurement.nextIPLDate {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let appointmentDay = calendar.startOfDay(for: nextIPLDate)
                
                if appointmentDay >= today {
                    iplAppointments.append(UpcomingTreatment(
                        type: .ipl,
                        date: nextIPLDate,
                        measurement: measurement
                    ))
                }
            }
            
            // Check RF appointments
            if let nextRFDate = measurement.nextRadioFrequencyDate {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let appointmentDay = calendar.startOfDay(for: nextRFDate)
                
                if appointmentDay >= today {
                    rfAppointments.append(UpcomingTreatment(
                        type: .rf,
                        date: nextRFDate,
                        measurement: measurement
                    ))
                }
            }
        }
        
        // Get the earliest upcoming treatment of each type
        let earliestIPL = iplAppointments.min { $0.date < $1.date }
        let earliestRF = rfAppointments.min { $0.date < $1.date }
        
        // Combine and return the earliest of each type
        var result: [UpcomingTreatment] = []
        if let ipl = earliestIPL {
            result.append(ipl)
        }
        if let rf = earliestRF {
            result.append(rf)
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    private func formattedDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        // Set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        
        // Use full month name for both English and French
        if currentLanguage == .french {
            formatter.dateFormat = "d MMMM yyyy"
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Upcoming Treatment Models and Views
struct UpcomingTreatment: Hashable {
    enum TreatmentType: Hashable {
        case ipl
        case rf
    }
    
    let type: TreatmentType
    let date: Date
    let measurement: DryEyeMeasurement
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(date)
        hasher.combine(measurement.id)
    }
    
    static func == (lhs: UpcomingTreatment, rhs: UpcomingTreatment) -> Bool {
        return lhs.type == rhs.type && lhs.date == rhs.date && lhs.measurement.id == rhs.measurement.id
    }
}


struct MeasurementRow: View {
    let measurement: DryEyeMeasurement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate(measurement.date))
                .font(.headline)
    
            
            HStack {
                SharedMeasurementValueView(
                    label: "dryEyeQuestionnaire",
                    value: String(format: "%.1f", measurement.dryEyeQuestionnaire),
                    unit: "score"
                )
                                
            }
            
            if let notes = measurement.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        // Set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
}

struct DryEyeMeasurementCard: View {
    let measurement: DryEyeMeasurement
    @ObservedObject var viewModel: DryEyeViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
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
                
                // Action buttons
                HStack(spacing: 8) {
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            // Main measurements grid
            VStack(spacing: 16) {
                // Top row - Primary measurements
                HStack(spacing: 0) {
                    // OSDI Score
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text(LocalizedStringKey.osdiScore.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", measurement.dryEyeQuestionnaire))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text(LocalizedStringKey.score.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Severity indicator
                        Text(osdiSeverityText(measurement.dryEyeQuestionnaire))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(osdiSeverityColor(measurement.dryEyeQuestionnaire))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(osdiSeverityColor(measurement.dryEyeQuestionnaire).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                    
                    // Osmolarity (if available)
                    if let osm = measurement.osmolarity {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(LocalizedStringKey.osmolarity.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.0f", osm))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text(LocalizedStringKey.mosmL.localized())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Osmolarity status indicator
                            Text(osmolarityStatusText(osm))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(osmolarityStatusColor(osm))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(osmolarityStatusColor(osm).opacity(0.15))
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text(LocalizedStringKey.osmolarity.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Text("—")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Bottom row - Secondary measurements
                HStack(spacing: 0) {
                    // Meibography (if available)
                    if let meibo = measurement.meibographyPercentLoss {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(LocalizedStringKey.meibography.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.0f", meibo))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text(LocalizedStringKey.percent.localized())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Meibography status indicator
                            Text(meibographyStatusText(meibo))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(meibographyStatusColor(meibo))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(meibographyStatusColor(meibo).opacity(0.15))
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text(LocalizedStringKey.meibography.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Text("—")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                    
                    // TMH (if available)
                    if let tmh = measurement.tmh {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "ruler")
                                    .font(.caption)
                                    .foregroundColor(.teal)
                                Text(LocalizedStringKey.tearMeniscusHeight.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.2f", tmh))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.teal)
                                Text(LocalizedStringKey.mm.localized())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // TMH status indicator
                            Text(tmhStatusText(tmh))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(tmhStatusColor(tmh))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(tmhStatusColor(tmh).opacity(0.15))
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "ruler")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text(LocalizedStringKey.tearMeniscusHeight.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Text("—")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Additional information section
            if measurement.hadIPLOrRF || measurement.hasRadioFrequency || measurement.mmp9 || measurement.notes != nil || measurement.nextIPLDate != nil || measurement.nextRadioFrequencyDate != nil {
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Treatment indicators
                    if measurement.hadIPLOrRF || measurement.hasRadioFrequency {
                        HStack(spacing: 12) {
                            if measurement.hadIPLOrRF {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text(LocalizedStringKey.ipl.localized())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            if measurement.hasRadioFrequency {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.purple)
                                    Text(LocalizedStringKey.rf.localized())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.purple)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Follow-up appointment reminders
                    if measurement.nextIPLDate != nil || measurement.nextRadioFrequencyDate != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizedStringKey.nextAppointments.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    if let nextIPLDate = measurement.nextIPLDate {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(Color.orange)
                                                .frame(width: 6, height: 6)
                                            Text("\(LocalizedStringKey.ipl.localized()) \(formattedDate(nextIPLDate))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if let nextRFDate = measurement.nextRadioFrequencyDate {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(Color.purple)
                                                .frame(width: 6, height: 6)
                                            Text("\(LocalizedStringKey.rf.localized()) \(formattedDate(nextRFDate))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // MMP9 status
                    if measurement.mmp9 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(LocalizedStringKey.mmp9Positive.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Notes
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
                DryEyeDataEntryView(
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
        // Set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // Set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    // MARK: - Status Indicator Functions
    private func osdiSeverityColor(_ score: Double) -> Color {
        switch score {
        case 0..<13: return .green
        case 13..<23: return .yellow
        case 23..<33: return .orange
        default: return .red
        }
    }
    
    private func osdiSeverityText(_ score: Double) -> String {
        switch score {
        case 0..<13: return LocalizedStringKey.normal.localized()
        case 13..<23: return LocalizedStringKey.mild.localized()
        case 23..<33: return LocalizedStringKey.moderate.localized()
        default: return LocalizedStringKey.severe.localized()
        }
    }
    
    private func osmolarityStatusColor(_ osmolarity: Double) -> Color {
        switch osmolarity {
        case 0..<308: return .green
        case 308..<316: return .yellow
        default: return .red
        }
    }
    
    private func osmolarityStatusText(_ osmolarity: Double) -> String {
        switch osmolarity {
        case 0..<308: return LocalizedStringKey.normal.localized()
        case 308..<316: return LocalizedStringKey.elevated.localized()
        default: return LocalizedStringKey.high.localized()
        }
    }
    
    private func meibographyStatusColor(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }
    
    private func meibographyStatusText(_ percentage: Double) -> String {
        switch percentage {
        case 0..<25: return LocalizedStringKey.normal.localized()
        case 25..<50: return LocalizedStringKey.mild.localized()
        case 50..<75: return LocalizedStringKey.moderate.localized()
        default: return LocalizedStringKey.severe.localized()
        }
    }
    
    private func tmhStatusColor(_ tmh: Double) -> Color {
        switch tmh {
        case 0.2...: return .green
        case 0.1..<0.2: return .yellow
        case 0.05..<0.1: return .orange
        default: return .red
        }
    }
    
    private func tmhStatusText(_ tmh: Double) -> String {
        switch tmh {
        case 0.2...: return LocalizedStringKey.normal.localized()
        case 0.1..<0.2: return LocalizedStringKey.low.localized()
        case 0.05..<0.1: return LocalizedStringKey.veryLow.localized()
        default: return LocalizedStringKey.critical.localized()
        }
    }
}


struct DryEyeInfoView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text(LocalizedStringKey.aboutDryEyeSyndrome.localized())
                        .font(.title2)
                        .fontWeight(.bold)
                        .id(currentLanguage)
                    
                    Text(LocalizedStringKey.dryEyeSyndromeDescription.localized())
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
                            title: LocalizedStringKey.osdiQuestionnaire.localized(),
                            description: LocalizedStringKey.dryEyeQuestionnaireDescription.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.osmolarity.localized(),
                            description: LocalizedStringKey.osmolarityDescription.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.meibography.localized(),
                            description: LocalizedStringKey.meibographyDescription.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.tearMeniscusHeight.localized(),
                            description: LocalizedStringKey.tmhDescription.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.mmp9Positive.localized(),
                            description: LocalizedStringKey.mmp9StatusDescription.localized()
                        )
                    }
                }
                
                Group {
                    Text(LocalizedStringKey.treatmentOptions.localized())
                        .font(.headline)
                        .padding(.top)
                        .id(currentLanguage)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        treatmentSection(
                            title: LocalizedStringKey.artificialTears.localized(),
                            description: LocalizedStringKey.artificialTearsDescription.localized()
                        )
                        
                        treatmentSection(
                            title: LocalizedStringKey.warmCompresses.localized(),
                            description: LocalizedStringKey.warmCompressesDescription.localized()
                        )
                        
                        treatmentSection(
                            title: LocalizedStringKey.iplRfTreatments.localized(),
                            description: LocalizedStringKey.iplRfTreatmentsDescription.localized()
                        )
                        
                        treatmentSection(
                            title: LocalizedStringKey.prescriptionMedications.localized(),
                            description: LocalizedStringKey.prescriptionMedicationsDescription.localized()
                        )
                    }
                }
                
                Group {
                    Text(LocalizedStringKey.whenToSeekHelp.localized())
                        .font(.headline)
                        .padding(.top)
                        .id(currentLanguage)
                    
                    Text(LocalizedStringKey.whenToSeekHelpDescription.localized())
                        .foregroundColor(.red)
                        .id(currentLanguage)
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey.diseaseInformation.localized())
        .navigationBarTitleDisplayMode(.inline)
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


