import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - View Models
@MainActor
class FuchsViewModel: ObservableObject {
    @Published private(set) var measurements: [FuchsMeasurement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var currentTask: Task<Void, Never>?
    private var isCleanedUp = false
    
    init() {
        currentTask = Task {
            await fetchMeasurements()
        }
        
        // Listen for app termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: .appWillTerminate,
            object: nil
        )
    }
    
    @objc private func handleAppTermination() {
        Task { @MainActor in
            cleanup()
        }
    }
    
    @MainActor
    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        
        // Cancel any ongoing tasks
        currentTask?.cancel()
        currentTask = nil
    }
    
    deinit {
        // Call cleanup without MainActor context since deinit cannot be @MainActor
        guard !isCleanedUp else { return }
        isCleanedUp = true
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        
        // Cancel any ongoing tasks
        currentTask?.cancel()
        currentTask = nil
    }
    
    func fetchMeasurements() async {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("fuchsMeasurements")
                .order(by: "date", descending: true)
                .getDocuments()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            self.measurements = snapshot.documents.compactMap { document -> FuchsMeasurement? in
                try? document.data(as: FuchsMeasurement.self)
            }
            
            isLoading = false
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
        } catch {
            errorMessage = "Failed to load measurements"
            isLoading = false
        }
    }
    
    func addMeasurement(_ measurement: FuchsMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FuchsError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let docRef = db.collection("users")
                .document(userId)
                .collection("fuchsMeasurements")
                .document()
            
            var newMeasurement = measurement
            newMeasurement.id = docRef.documentID
            
            let encodedData = try Firestore.Encoder().encode(newMeasurement)
            try await docRef.setData(encodedData)
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements.insert(newMeasurement, at: 0)
            isLoading = false
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
            throw CancellationError()
        } catch {
            errorMessage = "Failed to save measurement"
            isLoading = false
            throw error
        }
    }
    
    func deleteMeasurement(_ measurement: FuchsMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FuchsError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        guard let docId = measurement.id else {
            throw NSError(domain: "FuchsError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid document ID"])
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            try await db.collection("users")
                .document(userId)
                .collection("fuchsMeasurements")
                .document(docId)
                .delete()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements.removeAll { $0.id == measurement.id }
            isLoading = false
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
            throw CancellationError()
        } catch {
            errorMessage = "Failed to delete measurement"
            isLoading = false
            throw error
        }
    }
}

struct FuchsDystrophyView: View {
    @StateObject private var viewModel = FuchsViewModel()
    @State private var showingAddMeasurement = false
    @State private var selectedEye: EyeType = .OD
    @State private var showingInfo = false
    @State private var selectedDataPointIndex: Int? = nil
    @State private var activeChartId: String? = nil
    
    var filteredMeasurements: [FuchsMeasurement] {
        return viewModel.measurements.filter { $0.eye == selectedEye }
    }
    
    private var currentLanguage: Language {
        LocalizationManager.shared.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
            // Disease Info Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(LocalizedStringKey.aboutFuchsDystrophy.localized())
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        showingInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text(LocalizedStringKey.trackCornealHealth.localized())
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
            if !filteredMeasurements.isEmpty {
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
            
            // Measurements Over Time title - only show when there's data
            if !filteredMeasurements.isEmpty {
                Text(LocalizedStringKey.measurementsOverTime.localized())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
            }
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Graphs Section
                        if !filteredMeasurements.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                // ECD Graph
                                let ecdData = filteredMeasurements.map { ($0.date, $0.ecd, false) }
                                createGraphCard(
                                    title: LocalizedStringKey.endothelialCellDensity.localized(),
                                    data: ecdData,
                                    valueLabel: { String(format: "%.0f", $0) },
                                    color: .blue,
                                    normalRange: 2000...3000,
                                    unit: LocalizedStringKey.cellsPerMm2.localized(),
                                    infoText: LocalizedStringKey.ecdDescription.localized(),
                                    chartId: "ecd"
                                )
                                
                                // Pachymetry Graph
                                let pachyData = filteredMeasurements.map { ($0.date, Double($0.pachymetry), false) }
                                createGraphCard(
                                    title: LocalizedStringKey.cornealThickness.localized(),
                                    data: pachyData,
                                    valueLabel: { String(format: "%.0f", $0) },
                                    color: .green,
                                    normalRange: 500...550,
                                    unit: LocalizedStringKey.micrometers.localized(),
                                    infoText: LocalizedStringKey.pachymetryDescription.localized(),
                                    chartId: "pachymetry"
                                )
                                
                                // Severity Score Graph
                                let scoreData = filteredMeasurements.map { ($0.date, Double($0.score), false) }
                                createGraphCard(
                                    title: LocalizedStringKey.severityScore.localized(),
                                    data: scoreData,
                                    valueLabel: { String(format: "%.0f", $0) },
                                    color: .purple,
                                    normalRange: 0...2,
                                    unit: "/6",
                                    infoText: LocalizedStringKey.scoreDescription.localized(),
                                    chartId: "severity"
                                )
                                
                                // V-Fuchs Questionnaire Graph
                                let vfuchsData = filteredMeasurements.map { ($0.date, $0.vfuchsQuestionnaire, false) }
                                createGraphCard(
                                    title: LocalizedStringKey.vFuchsQuestionnaire.localized(),
                                    data: vfuchsData,
                                    valueLabel: { String(format: "%.0f", $0) },
                                    color: .teal,
                                    normalRange: 0...15,
                                    unit: LocalizedStringKey.score.localized(),
                                    infoText: LocalizedStringKey.vFuchsDescription.localized(),
                                    chartId: "vfuchs"
                                )
                            }
                        }
                        
                        // History Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Only show Measurement History title when there's data
                            if !filteredMeasurements.isEmpty {
                                Text(LocalizedStringKey.measurementHistory.localized())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            
                            if filteredMeasurements.isEmpty {
                                VStack {
                                    Spacer()
                                    VStack(spacing: 24) {
                                        VStack(spacing: 12) {
                                            Image("Fuchs")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 140, height: 140)
                                                .foregroundColor(.gray.opacity(0.5))
                                            
                                            Text(LocalizedStringKey.noMeasurements.localized())
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color.accentColor.opacity(0.7))
                                                .id(currentLanguage)
                                            
                                            Text(LocalizedStringKey.emptyStateFuchsMeasurement.localized().replacingOccurrences(of: "{eye}", with: selectedEye.shortName))
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
                                ForEach(filteredMeasurements) { measurement in
                                    FuchsMeasurementRow(measurement: measurement, viewModel: viewModel)
                                        .padding(.vertical, 4)
                                }
                            }
                            // Add Measurement button at end of history (only when there's data)
                            if !filteredMeasurements.isEmpty {
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
                    }
                    .padding(.bottom, 20)
                }
            }
            }            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey.fuchsDystrophy.localized())
        .sheet(isPresented: $showingAddMeasurement) {
            NavigationStack {
                FuchsDystrophyDataEntryView(viewModel: viewModel, selectedEye: selectedEye)
            }
        }
        .sheet(isPresented: $showingInfo) {
            NavigationStack {
                FuchsInfoView()
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
        data: [(Date, Double, Bool)],
        valueLabel: @escaping (Double) -> String,
        color: Color,
        normalRange: ClosedRange<Double>,
        unit: String,
        subtitle: String? = nil,
        infoText: String? = nil,
        chartId: String
    ) -> some View {
        let sortedData = data.sorted(by: { $0.0 < $1.0 })
        let isActive = activeChartId == chartId
        let displayIndex = isActive ? (selectedDataPointIndex ?? (sortedData.count - 1)) : (sortedData.count - 1)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Show the selected value with highlighted display
                if sortedData.indices.contains(displayIndex) {
                    let displayValue = sortedData[displayIndex].1
                    let displayDate = sortedData[displayIndex].0
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(valueLabel(displayValue))
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
                        
                        Text(LocalizedStringKey.addYourFirstMeasurement.localized())
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
                        .background(Color.accentColor.opacity(0.6))
                        .cornerRadius(8)
                        .shadow(color: Color.accentColor.opacity(0.12), radius: 2, x: 0, y: 1)
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
        valueFormatter: valueLabel,
        currentLanguage: LocalizationManager.shared.currentLanguage,
        allowNegativeValues: false,
        allowDecimals: false,
        specialBadgeText: nil
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
        if title.contains("Endothelial Cell Density") || title.contains("ECD") {
            return "endothelial cell density"
        } else if title.contains("Corneal Thickness") || title.contains("Pachymetry") {
            return "corneal thickness"
        } else if title.contains("Severity Score") {
            return "severity score"
        } else {
            return title.lowercased()
        }
    }
    
    // Helper function to get the actual range of values for better scaling
    private static func getValueRange(_ data: [(Date, Double, Bool)]) -> ClosedRange<Double> {
        guard !data.isEmpty else { return 0...1 }
        let values = data.map { $0.1 }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        if minValue == maxValue {
            return (minValue - 0.5)...(maxValue + 0.5)
        }
        return minValue...maxValue
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
}

struct FuchsMeasurementRow: View {
    let measurement: FuchsMeasurement
    @ObservedObject var viewModel: FuchsViewModel
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
                    // ECD (Endothelial Cell Density)
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "aqi.medium")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(LocalizedStringKey.ecdTooltip.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.0f", measurement.ecd))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(LocalizedStringKey.cellsPerMm2.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // ECD status indicator
                        Text(ecdStatusText(measurement.ecd))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(ecdStatusColor(measurement.ecd))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ecdStatusColor(measurement.ecd).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                    
                    // Pachymetry (Corneal Thickness)
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "ruler")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(LocalizedStringKey.cornealThickness.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(measurement.pachymetry)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text(LocalizedStringKey.micrometers.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Pachymetry status indicator
                        Text(pachymetryStatusText(measurement.pachymetry))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(pachymetryStatusColor(measurement.pachymetry))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(pachymetryStatusColor(measurement.pachymetry).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Bottom row - Secondary measurements
                HStack(spacing: 0) {
                    // Severity Score
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text(LocalizedStringKey.severityScore.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(measurement.score)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("/6")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Severity status indicator
                        Text(severityStatusText(measurement.score))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(severityColor(score: measurement.score))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(severityColor(score: measurement.score).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                    
                    // V-Fuchs Questionnaire
                    VStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "list.clipboard")
                                .font(.caption)
                                .foregroundColor(.teal)
                            Text(LocalizedStringKey.vFuchsQuestionnaire.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.0f", measurement.vfuchsQuestionnaire))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.teal)
                            Text(LocalizedStringKey.score.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // V-Fuchs status indicator
                        Text(vfuchsStatusText(measurement.vfuchsQuestionnaire))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(vfuchsStatusColor(measurement.vfuchsQuestionnaire))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(vfuchsStatusColor(measurement.vfuchsQuestionnaire).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Notes section
            if let notes = measurement.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                FuchsDystrophyDataEntryView(
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
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
    private func severityColor(score: Int) -> Color {
        switch score {
        case 0: return .green
        case 1...2: return .yellow
        case 3...4: return .orange
        case 5...6: return .red
        default: return .gray
        }
    }
    
    private func ecdStatusColor(_ ecd: Double) -> Color {
        switch ecd {
        case 2000...: return .green
        case 1500..<2000: return .yellow
        case 1000..<1500: return .orange
        default: return .red
        }
    }
    
    private func ecdStatusText(_ ecd: Double) -> String {
        switch ecd {
        case 2000...: return "Normal"
        case 1500..<2000: return "Mild"
        case 1000..<1500: return "Moderate"
        default: return "Severe"
        }
    }
    
    private func pachymetryStatusColor(_ pachymetry: Int) -> Color {
        switch pachymetry {
        case 500..<600: return .green
        case 450..<500: return .yellow
        case 400..<450: return .orange
        default: return .red
        }
    }
    
    private func pachymetryStatusText(_ pachymetry: Int) -> String {
        switch pachymetry {
        case 500..<600: return "Normal"
        case 450..<500: return "Thin"
        case 400..<450: return "Very Thin"
        default: return "Critical"
        }
    }
    
    private func severityStatusText(_ score: Int) -> String {
        switch score {
        case 0: return "Normal"
        case 1...2: return "Mild"
        case 3...4: return "Moderate"
        case 5...6: return "Severe"
        default: return "Unknown"
        }
    }
    
    private func vfuchsStatusColor(_ score: Double) -> Color {
        switch score {
        case 0..<5: return .green
        case 5..<10: return .yellow
        case 10..<15: return .orange
        default: return .red
        }
    }
    
    private func vfuchsStatusText(_ score: Double) -> String {
        switch score {
        case 0..<5: return "Normal"
        case 5..<10: return "Mild"
        case 10..<15: return "Moderate"
        default: return "Severe"
        }
    }
}

struct FuchsInfoView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text(LocalizedStringKey.aboutFuchsDystrophy.localized())
                        .font(.title2)
                        .fontWeight(.bold)
                        .id(currentLanguage)
                    
                    Text(LocalizedStringKey.fuchsDystrophyDescription.localized())
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
                            title: LocalizedStringKey.severityScore.localized(),
                            description: LocalizedStringKey.scoreDescription.localized()
                        )
                    }
                }
                
                Group {
                    Text(LocalizedStringKey.monitoring.localized())
                        .font(.headline)
                        .padding(.top)
                        .id(currentLanguage)
                    
                    Text(LocalizedStringKey.monitoringDescription.localized())
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
}

