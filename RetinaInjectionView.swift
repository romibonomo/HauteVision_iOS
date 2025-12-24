import SwiftUI
import UIKit

// MARK: - Main View (iPhone only)

@MainActor
struct RetinaInjectionView: View {
    @StateObject private var viewModel = RetinaInjectionViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingAddMeasurement = false
    @State private var selectedEye: EyeType = .OD
    @State private var showingInfo = false
    @State private var selectedDataPointIndex: Int? = nil
    @State private var activeChartId: String? = nil
    @State private var selectedYear: Int? = 2025
    @State private var selectedMonth: Int? = Calendar.current.component(.month, from: Date())
    @State private var showingInjectionDetails = false
    @State private var selectedInjectionDate: Date? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Disease Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(LocalizedStringKey.aboutRetinaInjections.localized())
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
                    
                    Text(LocalizedStringKey.retinaInjectionsDescription.localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Eye Selection
                EyeToggleView(selectedEye: $selectedEye)
                    .padding(.horizontal)
                
                // Add Measurement button when there's data
                if !filteredMeasurements().isEmpty {
                    Button(action: { showingAddMeasurement = true }) {
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
                .id(LocalizationManager.shared.currentLanguage)
                
                // Measurements Over Time title - only show when there's data
                if !filteredMeasurements().isEmpty {
                    Text(LocalizedStringKey.measurementsOverTime.localized())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }
                
                // Graphs Section - only show when there's data
                if !filteredMeasurements().isEmpty {
                    // Injection Calendar (heatmap)
                    InjectionCalendarView(
                        allMeasurements: viewModel.getMeasurements(for: selectedEye),
                        selectedYear: $selectedYear,
                        selectedMonth: $selectedMonth,
                        showingInjectionDetails: $showingInjectionDetails,
                        selectedInjectionDate: $selectedInjectionDate
                    )
                    createCRTGraph()
                    createVisionGraph()
                    createUpcomingReminderSection()
                }
                
                // Measurement History Section
                VStack(alignment: .leading, spacing: 12) {
                    // Only show Measurement History title when there's data
                    if !filteredMeasurements().isEmpty {
                        Text(LocalizedStringKey.measurementHistory.localized())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    if filteredMeasurements().isEmpty {
                        VStack {
                            Spacer()
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    Image("RetinalInjections")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 140, height: 140)
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text(LocalizedStringKey.noMeasurements.localized())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.accentColor.opacity(0.7))
                                        .id(LocalizationManager.shared.currentLanguage)
                                    
                                    Text(LocalizedStringKey.addFirstMeasurement.localized())
                                        .font(.subheadline)
                                        .foregroundColor(Color.accentColor.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .id(LocalizationManager.shared.currentLanguage)
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
                                            .id(LocalizationManager.shared.currentLanguage)
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
                        ForEach(filteredMeasurements()) { measurement in
                            RetinaInjectionMeasurementCard(measurement: measurement)
                                .padding(.vertical, 4)
                        }
                    }
                    
                    // Add Measurement button at end of history (only when there's data)
                    if !filteredMeasurements().isEmpty {
                        HStack {
                            Spacer()
                            Button(action: { showingAddMeasurement = true }) {
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
        .navigationTitle(LocalizedStringKey.retinalInjections.localized())
        .sheet(isPresented: $showingAddMeasurement) {
            NavigationStack {
                RetinaInjectionDataEntryView(viewModel: viewModel, selectedEye: selectedEye)
            }
        }
        .sheet(isPresented: $showingInfo) {
            NavigationStack {
                RetinaInjectionInfoView()
            }
        }
        .task {
            await viewModel.fetchMeasurements()
        }
        .refreshable {
            await viewModel.fetchMeasurements()
        }
        .onAppear {
            selectedDataPointIndex = nil
            activeChartId = nil
        }
        .overlay {
            if showingInjectionDetails, let selectedDate = selectedInjectionDate {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingInjectionDetails = false
                    }
                
                InjectionDetailsPopup(
                    date: selectedDate,
                    measurements: getInjectionDetails(for: selectedDate),
                    onDismiss: {
                        showingInjectionDetails = false
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingInjectionDetails)
    }

    private func filteredMeasurements() -> [RetinaInjectionMeasurement] {
        viewModel.getMeasurements(for: selectedEye)
    }
}

// MARK: - Graph Builders (iPhone compliant)

private extension RetinaInjectionView {
    func createCRTGraph() -> some View {
        let crtData = viewModel.getCRTChartData(for: selectedEye)
        let series: [(Date, Double, Bool)] = crtData.map { ($0.0, $0.1, false) }
        let values = series.map { $0.1 }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let _ = (minV + maxV) / 2

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey.centralRetinalThickness.localized())
                        .font(.headline)
                        .fontWeight(.medium)
                    Text(LocalizedStringKey.crtMeasurement.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                let isActive = activeChartId == "crt"
                let displayIndex = isActive ? selectedDataPointIndex : (series.count - 1)
                if let idx = displayIndex, idx >= 0, idx < series.count {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(Int(series[idx].1.rounded()))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("μm")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                        Text(formattedDateFull(series[idx].0))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)

            // Chart with integrated Y-axis labels
            UnifiedChartView(
                data: series,
                color: .purple,
                selectedIndex: activeChartId == "crt" ? selectedDataPointIndex : nil,
                onSelectIndex: { index in
                    if index != selectedDataPointIndex {
                        Haptics.selection()
                    }
                    selectedDataPointIndex = index
                },
                onInteractionStart: {
                    activeChartId = "crt"
                },
                onInteractionEnd: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        activeChartId = nil
                    }
                },
                valueFormatter: { value in
                    "\(Int(value.rounded()))"
                },
                currentLanguage: LocalizationManager.shared.currentLanguage,
                allowNegativeValues: false,
                allowDecimals: false,
                specialBadgeText: nil
            )
            .frame(height: 220)
            .padding(.vertical, 5)
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    func createVisionGraph() -> some View {
        // Convert Snellen "20/x" to numeric denominator x
        let raw = viewModel.getVisionHistory(for: selectedEye)
        let vaData: [(Date, Double, Bool)] = raw.compactMap { (date, vaString) in
            guard let denom = extractDenominator(from: vaString) else { return nil }
            return (date, Double(denom), false)
        }

        let values = vaData.map { $0.1 }
        let minD = values.min() ?? 20
        let maxD = values.max() ?? 200
        let _ = (minD + maxD) / 2

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey.visualAcuity.localized())
                        .font(.headline)
                        .fontWeight(.medium)
                    Text(LocalizedStringKey.visionMeasurement.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                let isActive = activeChartId == "vision"
                let displayIndex = isActive ? selectedDataPointIndex : (raw.count - 1)
                if let idx = displayIndex, idx >= 0, idx < raw.count {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(raw[idx].1)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        Text(formattedDateFull(raw[idx].0))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)

            // Chart with integrated Y-axis labels
            UnifiedChartView(
                data: vaData,
                color: .green,
                selectedIndex: activeChartId == "vision" ? selectedDataPointIndex : nil,
                onSelectIndex: { index in
                    if index != selectedDataPointIndex {
                        Haptics.selection()
                    }
                    selectedDataPointIndex = index
                },
                onInteractionStart: {
                    activeChartId = "vision"
                },
                onInteractionEnd: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        activeChartId = nil
                    }
                },
                valueFormatter: { value in
                    "\(Int(value.rounded()))"
                },
                currentLanguage: LocalizationManager.shared.currentLanguage,
                allowNegativeValues: false,
                allowDecimals: false,
                specialBadgeText: nil
            )
            .frame(height: 220)
            .padding(.vertical, 5)
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    func createUpcomingReminderSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let next = viewModel.getUpcomingReminder() {
                HStack {
                    Image(systemName: "bell")
                        .foregroundStyle(.tint)
                    Text(LocalizedStringKey.upcomingFollowUp.localized())
                        .font(.headline)
                    Spacer()
                    Text(dateString(next))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 10)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Upcoming follow up on \(dateString(next))")
            }
        }
    }

    func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return f.string(from: date)
    }

    // Extract denominator from Snellen "20/x"
    func extractDenominator(from snellen: String) -> Int? {
        let parts = snellen.split(separator: "/")
        guard parts.count == 2, let denom = Int(parts[1]) else { return nil }
        return denom
    }
    
    private func formattedDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
    private func getInjectionDetails(for date: Date) -> [RetinaInjectionMeasurement] {
        return viewModel.getMeasurements(for: selectedEye).filter { measurement in
            Calendar.current.isDate(measurement.date, inSameDayAs: date)
        }
    }
}

// MARK: - Injection Calendar Placeholder (kept generic; iPhone safe)

struct InjectionCalendarView: View {
    let allMeasurements: [RetinaInjectionMeasurement]
    @Binding var selectedYear: Int?
    @Binding var selectedMonth: Int?
    @Binding var showingInjectionDetails: Bool
    @Binding var selectedInjectionDate: Date?
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let currentMonth = Calendar.current.component(.month, from: Date())
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey.injectionCalendar.localized())
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                
                // Month/Year picker
                HStack(spacing: 8) {
                    Button(action: { decrementMonth() }) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("\(monthNameLocalized(selectedMonth ?? currentMonth)) \(String(selectedYear ?? currentYear))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Button(action: { incrementMonth() }) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                // Day headers
                ForEach(getLocalizedDayHeaders(), id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(height: 24)
                }
                
                // Calendar days
                ForEach(Array(calendarDays().enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        let hasInjection = hasInjectionOnDate(date)
                        Button(action: {
                            if hasInjection {
                                selectedInjectionDate = date
                                showingInjectionDetails = true
                            }
                        }) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                                .fontWeight(hasInjection ? .bold : .regular)
                                .foregroundColor(hasInjection ? .white : .primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(hasInjection ? Color.accentColor : Color.clear)
                                )
                        }
                        .disabled(!hasInjection)
                    } else {
                        Text("")
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month)) ?? Date()
        return formatter.string(from: date)
    }
    
    private func decrementMonth() {
        if selectedMonth == nil { selectedMonth = currentMonth }
        if selectedYear == nil { selectedYear = currentYear }
        
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear! -= 1
        } else {
            selectedMonth! -= 1
        }
    }
    
    private func incrementMonth() {
        if selectedMonth == nil { selectedMonth = currentMonth }
        if selectedYear == nil { selectedYear = currentYear }
        
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear! += 1
        } else {
            selectedMonth! += 1
        }
    }
    
    private func calendarDays() -> [Date?] {
        let year = selectedYear ?? currentYear
        let month = selectedMonth ?? currentMonth
        
        guard let firstOfMonth = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return []
        }
        
        let firstWeekday = Calendar.current.component(.weekday, from: firstOfMonth)
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty days for first week
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...daysInMonth {
            if let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasInjectionOnDate(_ date: Date) -> Bool {
        return allMeasurements.contains { measurement in
            Calendar.current.isDate(measurement.date, inSameDayAs: date)
        }
    }
    
    private func monthNameLocalized(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.monthSymbols[month - 1]
    }
    
    private func getLocalizedDayHeaders() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.shortWeekdaySymbols
    }
}


// MARK: - Info View

struct RetinaInjectionInfoView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text(LocalizedStringKey.aboutRetinaInjections.localized())
                        .font(.title3.weight(.semibold))
                        .id(currentLanguage)
                    Text(LocalizedStringKey.retinaInjectionsUsedToTreat.localized())
                        .font(.body)
                        .id(currentLanguage)
                }
                Group {
                    Text(LocalizedStringKey.keyMeasurementsRetina.localized()).font(.headline).padding(.top)
                        .id(currentLanguage)
                    VStack(alignment: .leading, spacing: 12) {
                        measurementSection(
                            title: LocalizedStringKey.centralRetinaThicknessCrt.localized(),
                            description: LocalizedStringKey.thicknessCentralRetina.localized()
                        )
                        measurementSection(
                            title: LocalizedStringKey.visionVisualAcuity.localized(),
                            description: LocalizedStringKey.tracksVisionChanges.localized()
                        )
                        measurementSection(
                            title: LocalizedStringKey.injectionTimeline.localized(),
                            description: LocalizedStringKey.datesMedicationsInjection.localized()
                        )
                        measurementSection(
                            title: LocalizedStringKey.newInjectionIndicates.localized(),
                            description: LocalizedStringKey.whenNewMedication.localized()
                        )
                        measurementSection(
                            title: LocalizedStringKey.followUpReminders.localized(),
                            description: LocalizedStringKey.helpsRememberAppointments.localized()
                        )
                    }
                }
                Group {
                    Text(LocalizedStringKey.treatmentGoals.localized()).font(.headline).padding(.top)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey.reduceRetinalSwelling.localized())
                        Text(LocalizedStringKey.maintainImproveVision.localized())
                        Text(LocalizedStringKey.preventFurtherVisionLoss.localized())
                        Text(LocalizedStringKey.minimizeTreatmentBurden.localized())
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                Group {
                    Text(LocalizedStringKey.whenToSeekHelpRetina.localized()).font(.headline).padding(.top)
                    Text(LocalizedStringKey.contactDoctorSuddenVision.localized())
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey.retinaInjectionInfo.localized())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func measurementSection(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.medium))
                .id(currentLanguage)
            Text(description).font(.callout).foregroundStyle(.secondary)
                .id(currentLanguage)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Haptics (iPhone only)

enum Haptics {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

struct RetinaInjectionMeasurementCard: View {
    let measurement: RetinaInjectionMeasurement
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var viewModel = RetinaInjectionViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and Edit Button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(measurement.date, style: .date)
                        .font(.headline)
                        .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.rawValue))

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
                Spacer()
                Text("\(LocalizedStringKey.time.localized()): \(measurement.date, style: .time)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.rawValue))
                
                HStack(spacing: 8) {
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(8)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(isDeleting)
                }
            }
            
            // Main measurement row with single vertical divider
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image("magnify")
                                .symbolRenderingMode(.hierarchical)
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(LocalizedStringKey.visualAcuity.localized())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(measurement.vision)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image("LinesMeasurementHorizontal")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            Text(LocalizedStringKey.centralRetinalThickness.localized())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.0f", measurement.crt))
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                            Text("μm")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                    .frame(width: 1)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 16)
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "syringe.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(LocalizedStringKey.medication.localized())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(measurement.medication)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(LocalizedStringKey.nextAppointment.localized())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let reminderDate = measurement.reminderDate {
                            Text(formattedDate(reminderDate))
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        } else {
                            Text(LocalizedStringKey.notSet.localized())
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            
            // New Injection badge
            if measurement.isNewMedication {
                HStack {
                    Label(LocalizedStringKey.newInjection.localized(), systemImage: "syringe")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    Spacer()
                }
            }
            
            // Notes if present
            if let notes = measurement.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                RetinaInjectionDataEntryView(
                    viewModel: RetinaInjectionViewModel(),
                    selectedEye: measurement.eye,
                    existingMeasurement: measurement
                )
            }
        }
        .alert(LocalizedStringKey.deleteMeasurement.localized(), isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStringKey.cancel.localized(), role: .cancel) { }
            Button(LocalizedStringKey.delete.localized(), role: .destructive) {
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
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InjectionDetailsPopup: View {
    let date: Date
    let measurements: [RetinaInjectionMeasurement]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Popup content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(LocalizedStringKey.injectionDetails.localized())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            
                            Spacer()
                            
                            Button(action: onDismiss) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(formattedDate(date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    if measurements.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.orange)
                            
                            Text(LocalizedStringKey.noInjectionDetailsFound.localized())
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(LocalizedStringKey.noRecordedInjectionsForDate.localized())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Injection details
                        ForEach(measurements) { measurement in
                            InjectionDetailCard(measurement: measurement)
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct InjectionDetailCard: View {
    let measurement: RetinaInjectionMeasurement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time
            HStack {
                Label(LocalizedStringKey.injectionTime.localized(), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(measurement.date, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
            }
            
            Divider()
            
            // Measurements
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(LocalizedStringKey.visualAcuity.localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(measurement.vision)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text(LocalizedStringKey.centralRetinalThickness.localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.0f", measurement.crt))
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        Text("μm")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Medication
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "syringe.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text(LocalizedStringKey.medication.localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(measurement.medication)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            // Next appointment
            if let reminderDate = measurement.reminderDate {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(LocalizedStringKey.nextAppointment.localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(formattedDate(reminderDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
            
            // Notes
            if let notes = measurement.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(LocalizedStringKey.notes.localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
}

// MARK: - Date Formatting Extensions

private extension RetinaInjectionView {
    func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
    func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.monthSymbols[month - 1]
    }
}

