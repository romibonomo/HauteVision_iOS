import SwiftUI

struct GlaucomaView: View {
    @StateObject private var viewModel = GlaucomaViewModel()
    @State private var showingAddMeasurement = false
    @State private var selectedEye: EyeType = .OD
    @State private var showingInfo = false
    @State private var selectedDataPointIndex: Int? = nil
    @State private var activeChartId: String? = nil
    @EnvironmentObject var localizationManager: LocalizationManager
    
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        return ScrollView {
            VStack(spacing: 24) {
            // Disease Info Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(LocalizedStringKey.aboutGlaucoma.localized())
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
                
                Text(LocalizedStringKey.glaucomaDescription.localized())
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
            if !viewModel.getMeasurements(for: selectedEye).isEmpty {
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
                // Visualization and measurement history
                ScrollView {
                    VStack(spacing: 24) {
                        // Only show graphs if there's data
                        if !viewModel.getMeasurements(for: selectedEye).isEmpty {
                            // IOP Graph Card
                            let iopData = viewModel.getSortedMeasurements(for: selectedEye).map { ($0.date, $0.iop, false) }
                            createGraphCard(
                                title: LocalizedStringKey.intraocularPressure.localized(),
                                data: iopData,
                                valueLabel: { String(format: "%.0f", $0) },
                                color: .blue,
                                normalRange: GlaucomaViewModel.normalIOPRange,
                                unit: LocalizedStringKey.mmHg.localized(),
                                infoText: LocalizedStringKey.iopTooltip.localized(),
                                chartId: "iop"
                            )

                            // Combined RNFL Graph Card
                            createCombinedRNFLGraph()
                            
                            // Macular GCC Graph Card
                            let gccData = viewModel.getSortedMeasurements(for: selectedEye).map { ($0.date, Double($0.macularGCC), false) }
                            createGraphCard(
                                title: LocalizedStringKey.macularGcc.localized(),
                                data: gccData,
                                valueLabel: { String(format: "%d", Int($0)) },
                                color: .teal,
                                normalRange: 70...100,
                                unit: LocalizedStringKey.micrometers.localized(),
                                infoText: LocalizedStringKey.gccTooltip.localized(),
                                chartId: "gcc"
                            )

                            // Mean Defect (MD) Graph Card
                            let mdData = viewModel.getSortedMeasurements(for: selectedEye).map { ($0.date, $0.meanDefect, false) }
                            createGraphCard(
                                title: LocalizedStringKey.meanDefect.localized(),
                                data: mdData,
                                valueLabel: { String(format: "%.2f", $0) },
                                color: .orange,
                                normalRange: -2...2,
                                unit: LocalizedStringKey.db.localized(),
                                infoText: LocalizedStringKey.mdTooltip.localized(),
                                chartId: "mean_defect"
                            )

                            // Pattern Standard Deviation (PSD) Graph Card
                            let psdData = viewModel.getSortedMeasurements(for: selectedEye).map { ($0.date, $0.patternStandardDeviation, false) }
                            createGraphCard(
                                title: LocalizedStringKey.patternStandardDeviation.localized(),
                                data: psdData,
                                valueLabel: { String(format: "%.2f", $0) },
                                color: .purple,
                                normalRange: 0...2,
                                unit: LocalizedStringKey.db.localized(),
                                infoText: LocalizedStringKey.psdTooltip.localized(),
                                chartId: "psd"
                            )
                        }

                        // Measurement history section
                        VStack(alignment: .leading, spacing: 12) {
                            // Only show Measurement History title when there's data
                            if !viewModel.getMeasurements(for: selectedEye).isEmpty {
                                Text(LocalizedStringKey.measurementHistory.localized())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            if viewModel.getMeasurements(for: selectedEye).isEmpty {
                                VStack {
                                    Spacer()
                                    VStack(spacing: 24) {
                                        VStack(spacing: 12) {
                                            Image("Glaucoma")
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
                                    GlaucomaMeasurementRow(measurement: measurement, viewModel: viewModel)
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                }
                                // Add Measurement button at end of history
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
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .padding(.vertical)
        .navigationTitle(LocalizedStringKey.glaucoma.localized())
        .sheet(isPresented: $showingAddMeasurement) {
            NavigationStack {
                GlaucomaDataEntryView(viewModel: viewModel, selectedEye: selectedEye)
            }
        }
        .sheet(isPresented: $showingInfo) {
            NavigationStack {
                GlaucomaInfoView()
            }
        }
        .task {
            await viewModel.fetchMeasurements()
        }
        .refreshable {
            await viewModel.fetchMeasurements()
        }
        .id(currentLanguage)
        }
    }
    
    private func createGraphCard(
    title: String,
    data: [(Date, Double, Bool)],
    valueLabel: @escaping (Double) -> String,
    color: Color,
    normalRange: ClosedRange<Double>,
    unit: String,
    infoText: String? = nil,
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
            }
            Spacer()
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
                valueFormatter: { value in String(format: "%.0f", value) },
                currentLanguage: currentLanguage,
                allowNegativeValues: chartId == "mean_defect",
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
    
    private func createCombinedRNFLGraph() -> some View {
        let measurements = viewModel.getSortedMeasurements(for: selectedEye)
        let rnflOverallData = measurements.map { ($0.date, Double($0.rnflOverall), false) }
        let rnflSuperiorData = measurements.map { ($0.date, Double($0.rnflSuperior), false) }
        let rnflInferiorData = measurements.map { ($0.date, Double($0.rnflInferior), false) }
        
        let isActive = activeChartId == "rnfl_combined"
        
        return VStack(alignment: .leading, spacing: 8) {
            // Header with title, legend, and dynamic values
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.retinalNerveFiberLayer.localized())
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        // Legend with inline values - using full words
                        if !measurements.isEmpty {
                            let displayIndex = isActive ? (selectedDataPointIndex ?? (measurements.count - 1)) : (measurements.count - 1)
                            if measurements.indices.contains(displayIndex) {
                                let measurement = measurements[displayIndex]
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text(LocalizedStringKey.rnflOverall.localized())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        + Text("\(measurement.rnflOverall)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                        + Text(" µm")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.mint)
                                            .frame(width: 8, height: 8)
                                        Text(LocalizedStringKey.rnflSuperior.localized())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        + Text("\(measurement.rnflSuperior)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.mint)
                                        + Text(" µm")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.indigo)
                                            .frame(width: 8, height: 8)
                                        Text(LocalizedStringKey.rnflInferior.localized())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        + Text("\(measurement.rnflInferior)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.indigo)
                                        + Text(" µm")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Date display
                    if !measurements.isEmpty {
                        let displayIndex = isActive ? (selectedDataPointIndex ?? (measurements.count - 1)) : (measurements.count - 1)
                        if measurements.indices.contains(displayIndex) {
                            let measurement = measurements[displayIndex]
                            Text(formatDateFull(measurement.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Chart content or empty state
            if measurements.isEmpty {
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
                        .background(Color.accentColor.opacity(0.6))
                        .cornerRadius(8)
                        .shadow(color: Color.green.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Multi-series chart
                MultiSeriesChartView(
                    dataSeries: [
                        (rnflOverallData, Color.green, LocalizedStringKey.rnfl.localized()),
                        (rnflSuperiorData, Color.mint, LocalizedStringKey.rnflSuperior.localized()),
                        (rnflInferiorData, Color.indigo, LocalizedStringKey.rnflInferior.localized())
                    ],
                    selectedIndex: isActive ? selectedDataPointIndex : nil,
                    onSelectIndex: { index in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDataPointIndex = index
                        }
                    },
                    onInteractionStart: {
                        activeChartId = "rnfl_combined"
                    },
                    onInteractionEnd: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            activeChartId = nil
                        }
                    },
                    valueFormatter: { String(format: "%d", Int($0)) },
                    currentLanguage: currentLanguage,
                    allowNegativeValues: false,
                    allowDecimals: false,
                    unit: LocalizedStringKey.micrometers.localized()
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
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
}

// Single measurement row component
struct GlaucomaMeasurementRow: View {
    let measurement: GlaucomaMeasurement
    @ObservedObject var viewModel: GlaucomaViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
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
                    // IOP
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.high")
                        .font(.caption)
                                .foregroundColor(.blue)
                            Text(LocalizedStringKey.iop.localized())
                                .font(.caption)
                            .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", measurement.iop))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(LocalizedStringKey.mmHg.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                Divider()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                    
                    // RNFL
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image("LinesMeasurementHorizontal")
                        .font(.caption)
                                .foregroundColor(.green)
                            Text(LocalizedStringKey.rnfl.localized())
                                .font(.caption)
                            .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(measurement.rnflOverall)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        Text(LocalizedStringKey.micrometers.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Bottom row - Secondary measurements
                HStack(spacing: 0) {
                    // MD
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lines.measurement.horizontal")
                        .font(.caption)
                                .foregroundColor(.orange)
                            Text(LocalizedStringKey.md.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", measurement.meanDefect))
                                .font(.title2)
                                .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text(LocalizedStringKey.db.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                    }
                }
                    .frame(maxWidth: .infinity)
                    
                Divider()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                    
                    // PSD
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.xaxis")
                        .font(.caption)
                                .foregroundColor(.red)
                            Text(LocalizedStringKey.psd.localized())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", measurement.patternStandardDeviation))
                                .font(.title2)
                                .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text(LocalizedStringKey.db.localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Additional information section
            if measurement.hasGlaucomaFamilyHistory || measurement.hasLasikSurgery || 
               measurement.hasVisualFieldChange || measurement.hasRNFLChange || measurement.newEyeDrops {
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    // First row
                    HStack(spacing: 0) {
                        if measurement.hasGlaucomaFamilyHistory {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text(LocalizedStringKey.familyHistory.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer()
                        }
                        
                        if measurement.hasGlaucomaFamilyHistory && measurement.hasLasikSurgery {
                            Divider()
                                .frame(height: 20)
                                .padding(.horizontal, 8)
                        }
                        
                        if measurement.hasLasikSurgery {
                            HStack(spacing: 4) {
                                Image("Lasik")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                                Text(LocalizedStringKey.lasikSurgery.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer()
                        }
                    }
                    
                    // Second row
                    HStack(spacing: 0) {
                        if measurement.hasVisualFieldChange {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                Text(LocalizedStringKey.visualFieldChange.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer()
                        }
                        
                        if measurement.hasVisualFieldChange && measurement.hasRNFLChange {
                            Divider()
                                .frame(height: 20)
                                .padding(.horizontal, 8)
                        }
                        
                        if measurement.hasRNFLChange {
                            HStack(spacing: 4) {
                                Image("MD")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                Text(LocalizedStringKey.rnflChange.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer()
                        }
                    }
                    
                    // Third row (if needed)
                    if measurement.newEyeDrops {
                        HStack(spacing: 0) {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(LocalizedStringKey.newEyeDrops.localized())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
            
            // Notes
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
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                GlaucomaDataEntryView(
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
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
}

// Info view for Glaucoma
struct GlaucomaInfoView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text(LocalizedStringKey.aboutGlaucoma.localized())
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(LocalizedStringKey.glaucomaDescription.localized())
                        .font(.body)
                }
                
                Group {
                    Text(LocalizedStringKey.keyMeasurements.localized())
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        measurementSection(
                            title: LocalizedStringKey.intraocularPressure.localized(),
                            description: LocalizedStringKey.iopTooltip.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.visualFieldParameters.localized(),
                            description: LocalizedStringKey.averageSensitivityLoss.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.retinalNerveFiberLayer.localized(),
                            description: LocalizedStringKey.thicknessNerveFibers.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.macularGanglionCellComplex.localized(),
                            description: LocalizedStringKey.thicknessGanglionCells.localized()
                        )
                    }
                }
                
                Group {
                    Text(LocalizedStringKey.riskFactors.localized())
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        measurementSection(
                            title: LocalizedStringKey.familyHistory.localized(),
                            description: LocalizedStringKey.familyHistoryDescription.localized()
                        )
                        
                        measurementSection(
                            title: LocalizedStringKey.lasikSurgery.localized(),
                            description: LocalizedStringKey.lasikSurgeryDescription.localized()
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
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey.glaucomaInformation.localized())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func measurementSection(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(description)
                .font(.callout)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyChartView: View {
    let message: String
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay(
                VStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                    Text(message)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            )
            .cornerRadius(8)
            .padding(.horizontal)
    }
}

// MARK: - Unified Chart Components
struct UnifiedChartData {
    let data: [(Date, Double, Bool)]
    let geometry: GeometryProxy
    let selectedIndex: Int?
    let allowNegativeValues: Bool
    let allowDecimals: Bool
    
    // Constants for consistent chart layout
    let topPadding: CGFloat = 15
    private let bottomPadding: CGFloat = 30
    let leftPadding: CGFloat = 20
    let rightPadding: CGFloat = 20
    let yAxisWidth: CGFloat = 40
    
    // Calculated properties
    var chartHeight: CGFloat { 
        geometry.size.height - topPadding - bottomPadding 
    }
    
    var availableWidth: CGFloat { 
        geometry.size.width - leftPadding - rightPadding - yAxisWidth 
    }
    
    var minValue: Double { 
        data.map { $0.1 }.min() ?? 0 
    }
    
    var maxValue: Double { 
        data.map { $0.1 }.max() ?? 1 
    }
    
    var midValue: Double { 
        (maxValue + minValue) / 2 
    }
    
    // Calculate adjusted range with consistent padding
    private var adjustedRange: (min: Double, max: Double, range: Double) {
        let range = maxValue - minValue
        let paddingPercent: Double = 0.15 // 15% padding on top and bottom
        
        // Handle case where all values are the same
        if range < 0.001 {
            let centerValue = minValue
            let padding = max(centerValue * 0.2, 1.0) // At least 1 unit padding
            let adjustedMin = allowNegativeValues ? centerValue - padding : max(centerValue - padding, 0.0)
            let adjustedMax = centerValue + padding
            return (adjustedMin, adjustedMax, adjustedMax - adjustedMin)
        }
        
        let padding = range * paddingPercent
        let adjustedMin = allowNegativeValues ? minValue - padding : max(minValue - padding, 0.0)
        let adjustedMax = maxValue + padding
        
        return (adjustedMin, adjustedMax, adjustedMax - adjustedMin)
    }
    
    // Calculate Y position with consistent scaling
    func calculateY(_ value: Double) -> CGFloat {
        // Use the same scaling logic as calculateYForAxisValue for alignment
        guard let firstValue = yAxisValues.first, let lastValue = yAxisValues.last, yAxisValues.count > 1 else {
            // Fallback to adjusted range if yAxisValues are not sufficient
            let adjusted = adjustedRange
            let normalizedValue = (value - adjusted.min) / adjusted.range
            let clampedValue = max(0.0, min(1.0, normalizedValue))
            return topPadding + chartHeight - (clampedValue * chartHeight)
        }
        
        let displayMin = firstValue
        let displayMax = lastValue
        let displayRange = displayMax - displayMin
        
        guard displayRange > 0 else {
            // Handle zero range case (all yAxisValues are the same)
            return topPadding + chartHeight / 2 // Center it
        }
        
        let normalizedValue = (value - displayMin) / displayRange
        let clampedValue = max(0.0, min(1.0, normalizedValue))
        
        // Invert Y coordinate (0 = top, 1 = bottom)
        return topPadding + chartHeight - (clampedValue * chartHeight)
    }
    
    // Calculate X position with consistent spacing
    func calculateX(_ index: Int) -> CGFloat {
        guard data.count > 1 else {
            return leftPadding + yAxisWidth + (availableWidth / 2)
        }
        
        let progress = CGFloat(index) / CGFloat(data.count - 1)
        return leftPadding + yAxisWidth + (progress * availableWidth)
    }
    
    // Get Y-axis values for labels and grid lines
    var yAxisValues: [Double] {
        let adjusted = adjustedRange
        let range = adjusted.range
        
        // Determine if we should use whole numbers based on allowDecimals parameter
        let useWholeNumbers = !allowDecimals
        
        // Handle very small ranges
        if range < 0.001 {
            return [adjusted.min, adjusted.max]
        }
        
        // Try different step sizes to get between 2-6 tick marks
        let possibleSteps = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0]
        let magnitudes = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0]
        
        var bestStepSize: Double = 1.0
        var bestTickCount = 0
        
        // Try different step sizes to find the best one
        for magnitude in magnitudes {
            for stepMultiplier in possibleSteps {
                let stepSize = magnitude * stepMultiplier
                
                // Generate values with this step size
                let min = floor(adjusted.min / stepSize) * stepSize
                let max = ceil(adjusted.max / stepSize) * stepSize
                
                var tickCount = 0
                var current = min
                while current <= max {
                    tickCount += 1
                    current += stepSize
                }
                
                // Check if this gives us a good number of ticks (2-6)
                if tickCount >= 2 && tickCount <= 6 {
                    // Prefer step sizes that give us closer to 4-5 ticks
                    if bestTickCount == 0 || (tickCount >= 4 && tickCount <= 5) || 
                       (bestTickCount < 4 && tickCount > bestTickCount) {
                        bestStepSize = stepSize
                        bestTickCount = tickCount
                    }
                }
            }
        }
        
        // If we didn't find a good step size, use a simple calculation
        if bestTickCount == 0 {
            let targetSteps = 4.0
            let rawStep = range / targetSteps
            let magnitude = pow(10, floor(log10(rawStep)))
            let normalized = rawStep / magnitude
            
            if normalized < 1.5 {
                bestStepSize = magnitude
            } else if normalized < 3.5 {
                bestStepSize = 2 * magnitude
            } else if normalized < 7.5 {
                bestStepSize = 5 * magnitude
            } else {
                bestStepSize = 10 * magnitude
            }
        }
        
        // Generate final values
        let min = floor(adjusted.min / bestStepSize) * bestStepSize
        let max = ceil(adjusted.max / bestStepSize) * bestStepSize
        
        var values: [Double] = []
        var current = min
        while current <= max {
            // Round based on allowDecimals parameter
            let roundedValue: Double
            if useWholeNumbers {
                // For whole number data, round to whole numbers
                roundedValue = round(current)
            } else {
                // For decimal data, round to avoid floating point precision issues
                roundedValue = round(current * 1000) / 1000
            }
            values.append(roundedValue)
            current += bestStepSize
        }
        
        // Remove duplicates by converting to Set and back to Array, then sort
        let uniqueValues = Array(Set(values)).sorted()
        
        // Ensure we have at least 2 values
        if uniqueValues.count < 2 {
            return [adjusted.min, adjusted.max]
        }
        
        return uniqueValues
    }
    
    // Calculate Y position for a given value, using the same rounding as yAxisValues
    func calculateYForAxisValue(_ value: Double) -> CGFloat {
        // Use the same rounding logic as yAxisValues
        let useWholeNumbers = !allowDecimals
        let roundedValue: Double
        if useWholeNumbers {
            roundedValue = round(value)
        } else {
            roundedValue = round(value * 1000) / 1000
        }
        
        guard let firstValue = yAxisValues.first, let lastValue = yAxisValues.last, yAxisValues.count > 1 else {
            // Fallback to original calculateY if yAxisValues are not sufficient
            return calculateY(roundedValue)
        }
        
        let displayMin = firstValue
        let displayMax = lastValue
        let displayRange = displayMax - displayMin
        
        guard displayRange > 0 else {
            // Handle zero range case (all yAxisValues are the same)
            return topPadding + chartHeight / 2 // Center it
        }
        
        let normalizedValue = (roundedValue - displayMin) / displayRange
        let clampedValue = max(0.0, min(1.0, normalizedValue))
        
        // Invert Y coordinate (0 = top, 1 = bottom)
        return topPadding + chartHeight - (clampedValue * chartHeight)
    }
}

struct UnifiedGridLinesView: View {
    let chartData: UnifiedChartData
    
    var body: some View {
        ZStack {
            // Horizontal grid lines - more subtle
            ForEach(chartData.yAxisValues, id: \.self) { value in
                Path { path in
                    let y = chartData.calculateYForAxisValue(value)
                    let startX = chartData.leftPadding + chartData.yAxisWidth
                    let endX = chartData.geometry.size.width - chartData.rightPadding
                    path.move(to: CGPoint(x: startX, y: y))
                    path.addLine(to: CGPoint(x: endX, y: y))
                }
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
            }
            
            // Vertical grid lines - dashed for major x-axis tick marks
            if chartData.data.count > 1 {
                let step = max(1, (chartData.data.count - 1) / 3)
                ForEach(0..<chartData.data.count, id: \.self) { index in
                    if index % step == 0 || index == chartData.data.count - 1 {
                        let x = chartData.calculateX(index)
            Path { path in
                path.move(to: CGPoint(x: x, y: chartData.topPadding))
                path.addLine(to: CGPoint(x: x, y: chartData.topPadding + chartData.chartHeight))
            }
                        .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundColor(Color.gray.opacity(0.12))
                    }
                }
            }
        }
    }
}

struct UnifiedChartPathView: View {
    let chartData: UnifiedChartData
    let color: Color
    
    var body: some View {
        ZStack {
            // Area fill (shading)
        Path { path in
            guard !chartData.data.isEmpty else { return }
                
                let startX = chartData.calculateX(0)
                let startY = chartData.calculateY(chartData.data[0].1)
                
                // Start at bottom of chart area
                path.move(to: CGPoint(x: startX, y: chartData.topPadding + chartData.chartHeight))
                path.addLine(to: CGPoint(x: startX, y: startY))
                
                // Draw curve through all points
            for i in 1..<chartData.data.count {
                let x = chartData.calculateX(i)
                let y = chartData.calculateY(chartData.data[i].1)
                let prevX = chartData.calculateX(i - 1)
                let prevY = chartData.calculateY(chartData.data[i - 1].1)
                
                    // Create smooth curve
                let control1 = CGPoint(x: prevX + (x - prevX) / 2, y: prevY)
                let control2 = CGPoint(x: prevX + (x - prevX) / 2, y: y)
                path.addCurve(to: CGPoint(x: x, y: y), control1: control1, control2: control2)
            }
                
                // Close the path to bottom
                let lastX = chartData.calculateX(chartData.data.count - 1)
                path.addLine(to: CGPoint(x: lastX, y: chartData.topPadding + chartData.chartHeight))
                path.closeSubpath()
            }
            .fill(LinearGradient(
                gradient: Gradient(colors: [color.opacity(0.15), color.opacity(0.02)]),
                startPoint: .top,
                endPoint: .bottom
            ))
            
            // Line stroke
        Path { path in
            guard !chartData.data.isEmpty else { return }
                
                let startX = chartData.calculateX(0)
            let startY = chartData.calculateY(chartData.data[0].1)
            
                path.move(to: CGPoint(x: startX, y: startY))
                
                // Draw smooth curve through all points
            for i in 1..<chartData.data.count {
                let x = chartData.calculateX(i)
                let y = chartData.calculateY(chartData.data[i].1)
                let prevX = chartData.calculateX(i - 1)
                let prevY = chartData.calculateY(chartData.data[i - 1].1)
                
                    // Create smooth curve
                let control1 = CGPoint(x: prevX + (x - prevX) / 2, y: prevY)
                let control2 = CGPoint(x: prevX + (x - prevX) / 2, y: y)
                path.addCurve(to: CGPoint(x: x, y: y), control1: control1, control2: control2)
            }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}

struct UnifiedDataPointsView: View {
    let chartData: UnifiedChartData
    let color: Color
    let onSelectIndex: (Int) -> Void
    let specialBadgeText: String?
    
    var body: some View {
        ForEach(0..<chartData.data.count, id: \.self) { index in
            let x = chartData.calculateX(index)
            let y = chartData.calculateY(chartData.data[index].1)
            let point = CGPoint(x: x, y: y)
            let isSelected = index == (chartData.selectedIndex ?? (chartData.data.count - 1))
            let isSpecial = chartData.data[index].2
            
            // Selection indicator line - more subtle
            if isSelected {
                Rectangle()
                    .fill(isSpecial ? Color.red.opacity(0.2) : color.opacity(0.2))
                    .frame(width: 0.5, height: chartData.chartHeight)
                    .position(x: point.x, y: chartData.topPadding + chartData.chartHeight / 2)
            }
                
            // Data point - cleaner design
                Circle()
                .fill(isSelected ? Color.white : (isSpecial ? Color.red.opacity(0.2) : color.opacity(0.2)))
                .frame(width: isSelected ? 12 : 4, height: isSelected ? 12 : 4)
                .overlay(
                Circle()
                        .fill(isSpecial ? .red : color)
                        .frame(width: isSelected ? 8 : 4, height: isSelected ? 8 : 4)
                )
                    .position(point)
            
            // Special Badge - appears when hovering over special data points
            if isSelected && isSpecial, let badgeText = specialBadgeText {
                Text(badgeText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
                    .position(x: point.x, y: chartData.topPadding - 8)
                    .zIndex(10)
            }
            
            // Touch area
                Circle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
                    .position(point)
                    .onTapGesture {
                        onSelectIndex(index)
                    }
        }
    }
}

struct UnifiedYAxisLabelsView: View {
    let chartData: UnifiedChartData
    let valueFormatter: (Double) -> String
    
    var body: some View {
        ZStack {
            ForEach(chartData.yAxisValues, id: \.self) { value in
                Text(valueFormatter(value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: chartData.yAxisWidth, alignment: .trailing)
                    .position(
                        x: chartData.yAxisWidth / 2,
                        y: chartData.calculateYForAxisValue(value)
                    )
            }
        }
    }
}

struct UnifiedXAxisView: View {
    let chartData: UnifiedChartData
    let currentLanguage: Language
    
    var body: some View {
        ZStack(alignment: .top) {
            let step = max(1, (chartData.data.count - 1) / 3)
            
            ForEach(0..<chartData.data.count, id: \.self) { index in
                if index % step == 0 || index == chartData.data.count - 1 {
                    let x = chartData.calculateX(index)
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 0.5, height: 4)
                        
                        Text(formatDateShort(chartData.data[index].0))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .position(x: x, y: 15)
                }
            }
        }
        .frame(height: 25)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
}

struct UnifiedChartView: View {
    let data: [(Date, Double, Bool)]
    let color: Color
    let selectedIndex: Int?
    let onSelectIndex: (Int) -> Void
    let onInteractionStart: () -> Void
    let onInteractionEnd: () -> Void
    let valueFormatter: (Double) -> String
    let currentLanguage: Language
    let allowNegativeValues: Bool
    let allowDecimals: Bool
    let specialBadgeText: String?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    let chartData = UnifiedChartData(
                        data: data,
                        geometry: geometry,
                        selectedIndex: selectedIndex,
                        allowNegativeValues: allowNegativeValues,
                        allowDecimals: allowDecimals
                    )
                    
                    // Y-axis labels
                    UnifiedYAxisLabelsView(chartData: chartData, valueFormatter: valueFormatter)
                    
                    // Grid lines
                    UnifiedGridLinesView(chartData: chartData)
                    
                    // Chart path and area
                    UnifiedChartPathView(chartData: chartData, color: color)
                    
                    // Data points
                    UnifiedDataPointsView(
                        chartData: chartData,
                        color: color,
                        onSelectIndex: onSelectIndex,
                        specialBadgeText: specialBadgeText
                    )
                }
                .frame(height: 180)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !data.isEmpty else { return }
                            onInteractionStart()
                            let fraction = max(0, min(1, value.location.x / max(1, geometry.size.width)))
                            let index = Int((fraction * CGFloat(max(0, data.count - 1))).rounded())
                            if index >= 0 && index < data.count {
                                onSelectIndex(index)
                            }
                        }
                        .onEnded { _ in
                            onInteractionEnd()
                        }
                )

                // X-Axis
                GeometryReader { axisGeometry in
                    let chartData = UnifiedChartData(
                        data: data,
                        geometry: axisGeometry,
                        selectedIndex: selectedIndex,
                        allowNegativeValues: allowNegativeValues,
                        allowDecimals: allowDecimals
                    )
                    UnifiedXAxisView(chartData: chartData, currentLanguage: currentLanguage)
                }
                .frame(height: 25)
            }
        }
        .frame(height: 210)
    }
}

// MARK: - Multi-Series Chart Components
struct MultiSeriesChartView: View {
    let dataSeries: [(data: [(Date, Double, Bool)], color: Color, name: String)]
    let selectedIndex: Int?
    let onSelectIndex: (Int) -> Void
    let onInteractionStart: () -> Void
    let onInteractionEnd: () -> Void
    let valueFormatter: (Double) -> String
    let currentLanguage: Language
    let allowNegativeValues: Bool
    let allowDecimals: Bool
    let unit: String
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    // Create chart data for the first series (for Y-axis calculations)
                    let chartData = MultiSeriesChartData(
                        dataSeries: dataSeries,
                        geometry: geometry,
                        selectedIndex: selectedIndex,
                        allowNegativeValues: allowNegativeValues,
                        allowDecimals: allowDecimals
                    )
                    
                    // Y-axis labels
                    MultiSeriesYAxisLabelsView(chartData: chartData, valueFormatter: valueFormatter)
                    
                    // Grid lines
                    MultiSeriesGridLinesView(chartData: chartData)
                    
                    // Chart paths for each series
                    ForEach(0..<dataSeries.count, id: \.self) { seriesIndex in
                        MultiSeriesChartPathView(
                            chartData: chartData,
                            seriesIndex: seriesIndex,
                            color: dataSeries[seriesIndex].color
                        )
                    }
                    
                    // Data points for each series
                    ForEach(0..<dataSeries.count, id: \.self) { seriesIndex in
                        MultiSeriesDataPointsView(
                            chartData: chartData,
                            seriesIndex: seriesIndex,
                            color: dataSeries[seriesIndex].color,
                            onSelectIndex: onSelectIndex
                        )
                    }
                }
                .frame(height: 180)
                .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let firstSeries = dataSeries.first, !firstSeries.data.isEmpty else { return }
                                        onInteractionStart()
                                        let fraction = max(0, min(1, value.location.x / max(1, geometry.size.width)))
                                        let index = Int((fraction * CGFloat(max(0, firstSeries.data.count - 1))).rounded())
                                        if index >= 0 && index < firstSeries.data.count {
                                            onSelectIndex(index)
                                        }
                                    }
                                    .onEnded { _ in
                                        onInteractionEnd()
                                    }
                            )
                
                // X-Axis
                GeometryReader { axisGeometry in
                    let chartData = MultiSeriesChartData(
                        dataSeries: dataSeries,
                        geometry: axisGeometry,
                        selectedIndex: selectedIndex,
                        allowNegativeValues: allowNegativeValues,
                        allowDecimals: allowDecimals
                    )
                    MultiSeriesXAxisView(chartData: chartData, currentLanguage: currentLanguage)
                }
                .frame(height: 25)
            }
        }
        .frame(height: 210)
    }
}

struct MultiSeriesChartData {
    let dataSeries: [(data: [(Date, Double, Bool)], color: Color, name: String)]
    let geometry: GeometryProxy
    let selectedIndex: Int?
    let allowNegativeValues: Bool
    let allowDecimals: Bool
    
    // Constants for consistent chart layout
    let topPadding: CGFloat = 15
    private let bottomPadding: CGFloat = 30
    let leftPadding: CGFloat = 20
    let rightPadding: CGFloat = 20
    let yAxisWidth: CGFloat = 40
    
    // Calculated properties
    var chartHeight: CGFloat { 
        geometry.size.height - topPadding - bottomPadding 
    }
    
    var availableWidth: CGFloat { 
        geometry.size.width - leftPadding - rightPadding - yAxisWidth 
    }
    
    // Get all values from all series for min/max calculation
    var allValues: [Double] {
        dataSeries.flatMap { $0.data.map { $0.1 } }
    }
    
    var minValue: Double { 
        allValues.min() ?? 0 
    }
    
    var maxValue: Double { 
        allValues.max() ?? 1 
    }
    
    // Calculate adjusted range with consistent padding
    private var adjustedRange: (min: Double, max: Double, range: Double) {
        let range = maxValue - minValue
        let paddingPercent: Double = 0.15 // 15% padding on top and bottom
        
        // Handle case where all values are the same
        if range < 0.001 {
            let centerValue = minValue
            let padding = max(centerValue * 0.2, 1.0) // At least 1 unit padding
            let adjustedMin = allowNegativeValues ? centerValue - padding : max(centerValue - padding, 0.0)
            let adjustedMax = centerValue + padding
            return (adjustedMin, adjustedMax, adjustedMax - adjustedMin)
        }
        
        let padding = range * paddingPercent
        let adjustedMin = allowNegativeValues ? minValue - padding : max(minValue - padding, 0.0)
        let adjustedMax = maxValue + padding
        
        return (adjustedMin, adjustedMax, adjustedMax - adjustedMin)
    }
    
    // Get Y-axis values for labels and grid lines
    var yAxisValues: [Double] {
        let adjusted = adjustedRange
        let range = adjusted.range
        
        // Determine if we should use whole numbers based on allowDecimals parameter
        let useWholeNumbers = !allowDecimals
        
        // Handle very small ranges
        if range < 0.001 {
            return [adjusted.min, adjusted.max]
        }
        
        // Try different step sizes to get between 2-6 tick marks
        let possibleSteps = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0]
        let magnitudes = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0]
        
        var bestStepSize: Double = 1.0
        var bestTickCount = 0
        
        // Try different step sizes to find the best one
        for magnitude in magnitudes {
            for stepMultiplier in possibleSteps {
                let stepSize = magnitude * stepMultiplier
                
                // Generate values with this step size
                let min = floor(adjusted.min / stepSize) * stepSize
                let max = ceil(adjusted.max / stepSize) * stepSize
                
                var tickCount = 0
                var current = min
                while current <= max {
                    tickCount += 1
                    current += stepSize
                }
                
                // Check if this gives us a good number of ticks (2-6)
                if tickCount >= 2 && tickCount <= 6 {
                    // Prefer step sizes that give us closer to 4-5 ticks
                    if bestTickCount == 0 || (tickCount >= 4 && tickCount <= 5) || 
                       (bestTickCount < 4 && tickCount > bestTickCount) {
                        bestStepSize = stepSize
                        bestTickCount = tickCount
                    }
                }
            }
        }
        
        // If we didn't find a good step size, use a simple calculation
        if bestTickCount == 0 {
            let targetSteps = 4.0
            let rawStep = range / targetSteps
            let magnitude = pow(10, floor(log10(rawStep)))
            let normalized = rawStep / magnitude
            
            if normalized < 1.5 {
                bestStepSize = magnitude
            } else if normalized < 3.5 {
                bestStepSize = 2 * magnitude
            } else if normalized < 7.5 {
                bestStepSize = 5 * magnitude
            } else {
                bestStepSize = 10 * magnitude
            }
        }
        
        // Generate final values
        let min = floor(adjusted.min / bestStepSize) * bestStepSize
        let max = ceil(adjusted.max / bestStepSize) * bestStepSize
        
        var values: [Double] = []
        var current = min
        while current <= max {
            // Round based on allowDecimals parameter
            let roundedValue: Double
            if useWholeNumbers {
                // For whole number data, round to whole numbers
                roundedValue = round(current)
            } else {
                // For decimal data, round to avoid floating point precision issues
                roundedValue = round(current * 1000) / 1000
            }
            values.append(roundedValue)
            current += bestStepSize
        }
        
        // Remove duplicates by converting to Set and back to Array, then sort
        let uniqueValues = Array(Set(values)).sorted()
        
        // Ensure we have at least 2 values
        if uniqueValues.count < 2 {
            return [adjusted.min, adjusted.max]
        }
        
        return uniqueValues
    }
    
    // Calculate Y position with consistent scaling
    func calculateY(_ value: Double) -> CGFloat {
        guard let firstValue = yAxisValues.first, let lastValue = yAxisValues.last, yAxisValues.count > 1 else {
            // Fallback to adjusted range if yAxisValues are not sufficient
            let adjusted = adjustedRange
            let normalizedValue = (value - adjusted.min) / adjusted.range
            let clampedValue = max(0.0, min(1.0, normalizedValue))
            return topPadding + chartHeight - (clampedValue * chartHeight)
        }
        
        let displayMin = firstValue
        let displayMax = lastValue
        let displayRange = displayMax - displayMin
        
        guard displayRange > 0 else {
            // Handle zero range case (all yAxisValues are the same)
            return topPadding + chartHeight / 2 // Center it
        }
        
        let normalizedValue = (value - displayMin) / displayRange
        let clampedValue = max(0.0, min(1.0, normalizedValue))
        
        // Invert Y coordinate (0 = top, 1 = bottom)
        return topPadding + chartHeight - (clampedValue * chartHeight)
    }
    
    // Calculate X position with consistent spacing
    func calculateX(_ index: Int) -> CGFloat {
        guard let firstSeries = dataSeries.first, !firstSeries.data.isEmpty else {
            return leftPadding + yAxisWidth + (availableWidth / 2)
        }
        
        guard firstSeries.data.count > 1 else {
            return leftPadding + yAxisWidth + (availableWidth / 2)
        }
        
        let progress = CGFloat(index) / CGFloat(firstSeries.data.count - 1)
        return leftPadding + yAxisWidth + (progress * availableWidth)
    }
    
    // Calculate Y position for a given value, using the same rounding as yAxisValues
    func calculateYForAxisValue(_ value: Double) -> CGFloat {
        // Use the same rounding logic as yAxisValues
        let useWholeNumbers = !allowDecimals
        let roundedValue: Double
        if useWholeNumbers {
            roundedValue = round(value)
        } else {
            roundedValue = round(value * 1000) / 1000
        }
        
        guard let firstValue = yAxisValues.first, let lastValue = yAxisValues.last, yAxisValues.count > 1 else {
            // Fallback to original calculateY if yAxisValues are not sufficient
            return calculateY(roundedValue)
        }
        
        let displayMin = firstValue
        let displayMax = lastValue
        let displayRange = displayMax - displayMin
        
        guard displayRange > 0 else {
            // Handle zero range case (all yAxisValues are the same)
            return topPadding + chartHeight / 2 // Center it
        }
        
        let normalizedValue = (roundedValue - displayMin) / displayRange
        let clampedValue = max(0.0, min(1.0, normalizedValue))
        
        // Invert Y coordinate (0 = top, 1 = bottom)
        return topPadding + chartHeight - (clampedValue * chartHeight)
    }
}

struct MultiSeriesGridLinesView: View {
    let chartData: MultiSeriesChartData
    
    var body: some View {
        ZStack {
            // Horizontal grid lines - very subtle
            ForEach(chartData.yAxisValues, id: \.self) { value in
                Path { path in
                    let y = chartData.calculateYForAxisValue(value)
                    let startX = chartData.leftPadding + chartData.yAxisWidth
                    let endX = chartData.geometry.size.width - chartData.rightPadding
                    path.move(to: CGPoint(x: startX, y: y))
                    path.addLine(to: CGPoint(x: endX, y: y))
                }
                .stroke(Color.gray.opacity(0.08), lineWidth: 0.3)
            }
            
            // Vertical grid lines - very subtle dashed lines
            if let firstSeries = chartData.dataSeries.first, firstSeries.data.count > 1 {
                let step = max(1, (firstSeries.data.count - 1) / 3)
                ForEach(0..<firstSeries.data.count, id: \.self) { index in
                    if index % step == 0 || index == firstSeries.data.count - 1 {
                        let x = chartData.calculateX(index)
                        Path { path in
                            path.move(to: CGPoint(x: x, y: chartData.topPadding))
                            path.addLine(to: CGPoint(x: x, y: chartData.topPadding + chartData.chartHeight))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 0.3, dash: [2, 2]))
                        .foregroundColor(Color.gray.opacity(0.06))
                    }
                }
            }
        }
    }
}

struct MultiSeriesChartPathView: View {
    let chartData: MultiSeriesChartData
    let seriesIndex: Int
    let color: Color
    
    var body: some View {
        ZStack {
            // Area fill (shading) - more subtle for multi-series
            Path { path in
                guard seriesIndex < chartData.dataSeries.count else { return }
                let data = chartData.dataSeries[seriesIndex].data
                guard !data.isEmpty else { return }
                
                let startX = chartData.calculateX(0)
                let startY = chartData.calculateY(data[0].1)
                
                // Start at bottom of chart area
                path.move(to: CGPoint(x: startX, y: chartData.topPadding + chartData.chartHeight))
                path.addLine(to: CGPoint(x: startX, y: startY))
                
                // Draw curve through all points
                for i in 1..<data.count {
                    let x = chartData.calculateX(i)
                    let y = chartData.calculateY(data[i].1)
                    let prevX = chartData.calculateX(i - 1)
                    let prevY = chartData.calculateY(data[i - 1].1)
                    
                    // Create smooth curve
                    let control1 = CGPoint(x: prevX + (x - prevX) / 2, y: prevY)
                    let control2 = CGPoint(x: prevX + (x - prevX) / 2, y: y)
                    path.addCurve(to: CGPoint(x: x, y: y), control1: control1, control2: control2)
                }
                
                // Close the path to bottom
                let lastX = chartData.calculateX(data.count - 1)
                path.addLine(to: CGPoint(x: lastX, y: chartData.topPadding + chartData.chartHeight))
                path.closeSubpath()
            }
            .fill(LinearGradient(
                gradient: Gradient(colors: [color.opacity(0.04), color.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            ))
            
            // Line stroke
            Path { path in
                guard seriesIndex < chartData.dataSeries.count else { return }
                let data = chartData.dataSeries[seriesIndex].data
                guard !data.isEmpty else { return }
                
                let startX = chartData.calculateX(0)
                let startY = chartData.calculateY(data[0].1)
                
                path.move(to: CGPoint(x: startX, y: startY))
                
                // Draw smooth curve through all points
                for i in 1..<data.count {
                    let x = chartData.calculateX(i)
                    let y = chartData.calculateY(data[i].1)
                    let prevX = chartData.calculateX(i - 1)
                    let prevY = chartData.calculateY(data[i - 1].1)
                    
                    // Create smooth curve
                    let control1 = CGPoint(x: prevX + (x - prevX) / 2, y: prevY)
                    let control2 = CGPoint(x: prevX + (x - prevX) / 2, y: y)
                    path.addCurve(to: CGPoint(x: x, y: y), control1: control1, control2: control2)
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}

struct MultiSeriesDataPointsView: View {
    let chartData: MultiSeriesChartData
    let seriesIndex: Int
    let color: Color
    let onSelectIndex: (Int) -> Void
    
    var body: some View {
        if seriesIndex < chartData.dataSeries.count {
            let data = chartData.dataSeries[seriesIndex].data
            
            return AnyView(ForEach(0..<data.count, id: \.self) { index in
            let x = chartData.calculateX(index)
            let y = chartData.calculateY(data[index].1)
            let point = CGPoint(x: x, y: y)
            let isSelected = index == (chartData.selectedIndex ?? (data.count - 1))
            let isSpecial = data[index].2
            
            // Selection indicator line - more subtle
            if isSelected {
                Rectangle()
                    .fill(isSpecial ? Color.red.opacity(0.2) : color.opacity(0.2))
                    .frame(width: 0.5, height: chartData.chartHeight)
                    .position(x: point.x, y: chartData.topPadding + chartData.chartHeight / 2)
            }
            
            // Data point - more prominent like reference
            Circle()
                .fill(isSelected ? Color.white : (isSpecial ? Color.red.opacity(0.3) : color.opacity(0.3)))
                .frame(width: isSelected ? 12 : 4, height: isSelected ? 12 : 4)
                .overlay(
                    Circle()
                        .fill(isSpecial ? .red : color)
                        .frame(width: isSelected ? 8 : 4, height: isSelected ? 8 : 4)
                )
                .position(point)
            
            // Touch area
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
                .position(point)
                .onTapGesture {
                    onSelectIndex(index)
                }
            })
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct MultiSeriesYAxisLabelsView: View {
    let chartData: MultiSeriesChartData
    let valueFormatter: (Double) -> String
    
    var body: some View {
        ZStack {
            ForEach(chartData.yAxisValues, id: \.self) { value in
                Text(valueFormatter(value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: chartData.yAxisWidth, alignment: .trailing)
                    .position(
                        x: chartData.yAxisWidth / 2,
                        y: chartData.calculateYForAxisValue(value)
                    )
            }
        }
    }
}

struct MultiSeriesXAxisView: View {
    let chartData: MultiSeriesChartData
    let currentLanguage: Language
    
    var body: some View {
        ZStack(alignment: .top) {
            if let firstSeries = chartData.dataSeries.first, !firstSeries.data.isEmpty {
                let step = max(1, (firstSeries.data.count - 1) / 3)
                
                ForEach(0..<firstSeries.data.count, id: \.self) { index in
                if index % step == 0 || index == firstSeries.data.count - 1 {
                    let x = chartData.calculateX(index)
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 0.5, height: 4)
                        
                        Text(formatDateShort(firstSeries.data[index].0))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .position(x: x, y: 15)
                }
            }
            }
        }
        .frame(height: 25)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: currentLanguage == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
}
