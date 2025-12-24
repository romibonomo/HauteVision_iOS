import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RetinaInjectionViewModel: ObservableObject {
    @Published var measurements: [RetinaInjectionMeasurement] = []
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
    
    func fetchMeasurements() async {
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedStringKey.mustBeLoggedInView.localized()
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("retinaInjectionMeasurements")
                .order(by: "date", descending: false)
                .getDocuments()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements = snapshot.documents.compactMap { document in
                try? document.data(as: RetinaInjectionMeasurement.self)
            }
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
        } catch {
            errorMessage = "\(LocalizedStringKey.failedToFetchMeasurements.localized()) \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func addMeasurement(_ measurement: RetinaInjectionMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: LocalizedStringKey.mustBeLoggedInAdd.localized()])
        }
        isLoading = true
        errorMessage = nil
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let docRef = db.collection("users")
                .document(userId)
                .collection("retinaInjectionMeasurements")
                .document()
            var newMeasurement = measurement
            newMeasurement.id = docRef.documentID
            try docRef.setData(from: newMeasurement)
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements.append(newMeasurement)
            measurements.sort(by: { $0.date < $1.date })
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
            throw CancellationError()
        } catch {
            errorMessage = "\(LocalizedStringKey.failedToAddMeasurement.localized()) \(error.localizedDescription)"
            throw error
        }
        isLoading = false
    }
    
    func deleteMeasurement(_ measurement: RetinaInjectionMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: LocalizedStringKey.mustBeLoggedInDelete.localized()])
        }
        guard let measurementId = measurement.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: LocalizedStringKey.invalidMeasurementId.localized()])
        }
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            try await db.collection("users")
                .document(userId)
                .collection("retinaInjectionMeasurements")
                .document(measurementId)
                .delete()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements.removeAll { $0.id == measurementId }
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            throw CancellationError()
        } catch {
            errorMessage = "\(LocalizedStringKey.failedToDeleteMeasurement.localized()) \(error.localizedDescription)"
            throw error
        }
    }
    
    // Filtering helpers for graphs
    func getMeasurements(for eye: EyeType) -> [RetinaInjectionMeasurement] {
        measurements.filter { $0.eye == eye }
    }
    
    // Chart helpers
    func getInjectionTimelineData() -> [(Date, Bool)] {
        measurements.map { ($0.date, $0.isNewMedication) }
    }
    func getCRTChartData(for eye: EyeType) -> [(Date, Double)] {
        measurements.filter { $0.eye == eye }.map { ($0.date, $0.crt) }.sorted { $0.0 < $1.0 }
    }
    func getVisionHistory(for eye: EyeType) -> [(Date, String)] {
        measurements.filter { $0.eye == eye }.map { ($0.date, $0.vision) }.sorted { $0.0 < $1.0 }
    }
    func getUpcomingReminder() -> Date? {
        let today = Calendar.current.startOfDay(for: Date())
        return measurements
            .compactMap { $0.reminderDate }
            .filter { Calendar.current.startOfDay(for: $0) >= today }
            .sorted()
            .first
    }
} 