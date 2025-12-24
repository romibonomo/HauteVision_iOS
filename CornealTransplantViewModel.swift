import Foundation
import FirebaseFirestore
import FirebaseAuth

enum TransplantError: Error {
    case notAuthenticated
    case networkError
    case invalidData
    case unknown
    case reminderPermissionDenied
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to view measurements"
        case .networkError:
            return "Network error: Please check your connection"
        case .invalidData:
            return "Invalid data received from server"
        case .unknown:
            return "An unknown error occurred"
        case .reminderPermissionDenied:
            return "Please enable notifications in Settings to receive medication reminders"
        }
    }
}

@MainActor
class CornealTransplantViewModel: ObservableObject {
    @Published var measurements: [TransplantMeasurement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
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
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = TransplantError.notAuthenticated.localizedDescription
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("transplantMeasurements")
                .order(by: "date", descending: true)
                .getDocuments()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements = snapshot.documents.compactMap { document in
                do {
                    return try document.data(as: TransplantMeasurement.self)
                } catch {
                    // Error decoding measurement: \(error)
                    return nil
                }
            }
            if measurements.isEmpty {
                errorMessage = "No measurements found"
            }
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
        } catch let error as NSError {
            switch error.code {
            case -1: // Auth error
                errorMessage = TransplantError.notAuthenticated.localizedDescription
            case -1009: // Network error
                errorMessage = TransplantError.networkError.localizedDescription
            default:
                errorMessage = "Failed to fetch measurements: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = TransplantError.unknown.localizedDescription
        }
        isLoading = false
    }
    
    func addMeasurement(_ measurement: TransplantMeasurement) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to add measurements"])
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let docRef = db.collection("users")
                .document(userId)
                .collection("transplantMeasurements")
                .document()
            
            var newMeasurement = measurement
            newMeasurement.id = docRef.documentID
            
            try docRef.setData(from: newMeasurement)
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements.append(newMeasurement)
            measurements.sort(by: { $0.date > $1.date })
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
    
    func deleteMeasurement(_ measurement: TransplantMeasurement) async throws {
        guard let userId = currentUserId else {
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
                .collection("transplantMeasurements")
                .document(measurementId)
                .delete()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements.removeAll { $0.id == measurement.id }
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            throw CancellationError()
        } catch {
            errorMessage = "Failed to delete measurement: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getMeasurements(for eye: EyeType) -> [TransplantMeasurement] {
        measurements.filter { $0.eye == eye }
    }
    
    // Get chronologically sorted measurements for graphing
    func getSortedMeasurements(for eye: EyeType) -> [TransplantMeasurement] {
        getMeasurements(for: eye).sorted(by: { $0.date < $1.date })
    }
    
    // Get ECD chart data
    func getECDChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).map { ($0.date, $0.ecd, $0.isRegraft) }
    }
    
    // Get Pachymetry chart data
    func getPachymetryChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).map { ($0.date, Double($0.pachymetry), $0.isRegraft) }
    }
    
    // Get the current medication for an eye
    func getCurrentMedication(for eye: EyeType) -> TransplantMeasurement? {
        getMeasurements(for: eye).sorted(by: { $0.date > $1.date }).first
    }
    
    // Get Steroid Frequency chart data
    func getSteroidFrequencyChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).map { measurement in
            // Convert steroid regimen to a numeric value based on frequency
            let frequency = parseSteroidFrequency(measurement.steroidRegimen ?? "none")
            return (measurement.date, frequency, measurement.isRegraft)
        }
    }
    
    // Helper function to parse steroid frequency into a numeric value
    private func parseSteroidFrequency(_ regimen: String) -> Double {
        let lowercased = regimen.lowercased()
        
        // Handle predefined frequencies
        switch lowercased {
        case "none":
            return 0.0
        case "daily":
            return 1.0
        case "weekly":
            return 0.25
        default:
            // For custom frequencies, try to extract a number
            let components = lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted)
            for component in components {
                if let number = Double(component) {
                    // If the text contains "per day" or similar, use the number directly
                    if lowercased.contains("per day") || lowercased.contains("daily") {
                        return number
                    }
                    // If the text contains "per week", divide by 7
                    else if lowercased.contains("per week") || lowercased.contains("weekly") {
                        return number / 7.0
                    }
                    // Default to assuming it's per day
                    return number
                }
            }
            return 0.0
        }
    }
    
    // Helper function to get value range for charts
    static func getValueRange(_ data: [(Date, Double, Bool)]) -> ClosedRange<Double> {
        guard !data.isEmpty else { return 0...0 }
        let values = data.map { $0.1 }
        return (values.min() ?? 0)...(values.max() ?? 0)
    }
    
    // Format date for display in charts (short version)
    static func formatDateShort(_ date: Date, language: Language = .english) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: language == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    // Format date for display in detail views (full version)
    static func formatDateFull(_ date: Date, language: Language = .english) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: language == .french ? "fr_FR" : "en_US")
        return formatter.string(from: date)
    }
    
    // Get the normal range for ECD
    static let normalECDRange: ClosedRange<Double> = 2000...3000
    
    // Get the normal range for Pachymetry
    static let normalPachymetryRange: ClosedRange<Double> = 500...550
    
    // Get IOP chart data
    func getIOPChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).map { ($0.date, $0.iop, $0.isRegraft) }
    }
} 