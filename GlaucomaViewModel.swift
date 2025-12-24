import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class GlaucomaViewModel: ObservableObject {
    @Published var measurementsOD: [GlaucomaMeasurement] = []
    @Published var measurementsOS: [GlaucomaMeasurement] = []
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
        // Starting cleanup
        
        // Cancel any ongoing async tasks
        Task {
            do {
                try await Task.sleep(nanoseconds: 1) // Minimal delay to ensure proper cancellation
            } catch {
                if error is CancellationError {
                    // Tasks cancelled successfully
                } else {
                    // Error during cleanup: \(error)
                }
            }
        }
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Cleanup completed
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
    
    // Fetch measurements for both eyes
    func fetchMeasurements() async {
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to view measurements"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("glaucomaMeasurements")
                .order(by: "date", descending: true)
                .getDocuments()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            let allMeasurements = snapshot.documents.compactMap { document in
                try? document.data(as: GlaucomaMeasurement.self)
            }
            
            measurementsOD = allMeasurements.filter { $0.eye == .OD }
            measurementsOS = allMeasurements.filter { $0.eye == .OS }
            
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch measurements: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addMeasurement(_ measurement: GlaucomaMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to add measurements"])
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let docRef = db.collection("users")
                .document(userId)
                .collection("glaucomaMeasurements")
                .document()
            
            var newMeasurement = measurement
            newMeasurement.id = docRef.documentID
            
            try docRef.setData(from: newMeasurement)
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            if measurement.eye == .OD {
                measurementsOD.append(newMeasurement)
                measurementsOD.sort(by: { $0.date > $1.date })
            } else {
                measurementsOS.append(newMeasurement)
                measurementsOS.sort(by: { $0.date > $1.date })
            }
            
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
            throw CancellationError()
        } catch {
            errorMessage = "Failed to add measurement: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func deleteMeasurement(_ measurement: GlaucomaMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to delete measurements"])
        }
        
        guard let measurementId = measurement.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid measurement ID"])
        }
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            try await db.collection("users")
                .document(userId)
                .collection("glaucomaMeasurements")
                .document(measurementId)
                .delete()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            if measurement.eye == .OD {
                measurementsOD.removeAll { $0.id == measurement.id }
            } else {
                measurementsOS.removeAll { $0.id == measurement.id }
            }
            
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            throw CancellationError()
        } catch {
            errorMessage = "Failed to delete measurement: \(error.localizedDescription)"
            throw error
        }
    }
    
    // Helper methods to get measurements for a specific eye
    func getMeasurements(for eye: EyeType) -> [GlaucomaMeasurement] {
        switch eye {
        case .OD:
            return measurementsOD
        case .OS:
            return measurementsOS
        }
    }
    
    func getSortedMeasurements(for eye: EyeType) -> [GlaucomaMeasurement] {
        return getMeasurements(for: eye).sorted(by: { $0.date < $1.date })
    }
    
    // Chart data helpers
    func getIOPChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getSortedMeasurements(for: eye).map { ($0.date, $0.iop, false) }
    }
    
    func getRNFLChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getSortedMeasurements(for: eye).map { ($0.date, Double($0.rnflOverall), false) }
    }
    
    func getRNFLSuperiorChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getSortedMeasurements(for: eye).map { ($0.date, Double($0.rnflSuperior), false) }
    }
    
    func getRNFLInferiorChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getSortedMeasurements(for: eye).map { ($0.date, Double($0.rnflInferior), false) }
    }
    
    func getMacularGCCChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getSortedMeasurements(for: eye).map { ($0.date, Double($0.macularGCC), false) }
    }
    
    func getMeanDefectChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getSortedMeasurements(for: eye).map { ($0.date, $0.meanDefect, false) }
    }
    
    func getPSDChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getSortedMeasurements(for: eye).map { ($0.date, $0.patternStandardDeviation, false) }
    }
    
    // Helper function to get value range for charts
    static func getValueRange(_ data: [(Date, Double, Bool)], defaultRange: ClosedRange<Double> = 0...1) -> ClosedRange<Double> {
        guard !data.isEmpty else { return defaultRange }
        
        let values = data.map { $0.1 }
        var minValue = values.min() ?? defaultRange.lowerBound
        var maxValue = values.max() ?? defaultRange.upperBound
        
        // Add padding (30%) to ensure values don't get cut off at edges
        let valueRange = maxValue - minValue
        let padding = max(valueRange * 0.3, 10.0)
        
        // If min and max are the same, create a range with padding
        if minValue == maxValue {
            minValue = max(0, minValue - padding)
            maxValue = maxValue + padding
            return minValue...maxValue
        }
        
        // Add padding to both min and max values
        minValue = max(0, minValue - padding)
        maxValue = maxValue + padding
        
        // Round min/max to nice numbers for better axis labels
        minValue = (minValue / 5).rounded(.down) * 5
        maxValue = (maxValue / 5).rounded(.up) * 5
        
        return minValue...maxValue
    }
    
    // Normal ranges for different measurements
    static var normalIOPRange: ClosedRange<Double> {
        return 10...21
    }
    
    static var normalRNFLRange: ClosedRange<Double> {
        return 90...110
    }
    
    static var normalMeanDefectRange: ClosedRange<Double> {
        return -2...2
    }
    
    static var normalPSDRange: ClosedRange<Double> {
        return 0...2
    }
} 