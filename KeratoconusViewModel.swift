import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class KeratoconusViewModel: ObservableObject {
    @Published var measurementsOD: [KeratoconusMeasurement] = []
    @Published var measurementsOS: [KeratoconusMeasurement] = []
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
    
    // Fetch measurements for both eyes
    func fetchMeasurements() async {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("keratoconusMeasurements")
                .order(by: "date", descending: true)
                .getDocuments()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            let allMeasurements = snapshot.documents.compactMap { document -> KeratoconusMeasurement? in
                try? document.data(as: KeratoconusMeasurement.self)
            }
            
            // Separate measurements by eye
            self.measurementsOD = allMeasurements.filter { $0.eye == .OD }
            self.measurementsOS = allMeasurements.filter { $0.eye == .OS }
            
            isLoading = false
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
        } catch {
            errorMessage = "Failed to load measurements"
            isLoading = false
        }
    }
    
    // Add a new measurement
    func addMeasurement(_ measurement: KeratoconusMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "KeratoconusError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            // Create a new measurement with a document ID
            var newMeasurement = measurement
            let docRef = db.collection("users")
                .document(userId)
                .collection("keratoconusMeasurements")
                .document()
            
            // Set the document ID
            newMeasurement.id = docRef.documentID
            
            // Explicitly create the async operation
            let encodedData = try Firestore.Encoder().encode(newMeasurement)
            try await docRef.setData(encodedData)
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            // Update local collections
            if newMeasurement.eye == .OD {
                measurementsOD.insert(newMeasurement, at: 0)
            } else {
                measurementsOS.insert(newMeasurement, at: 0)
            }
            
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
    
    // Delete a measurement
    func deleteMeasurement(_ measurement: KeratoconusMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "KeratoconusError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        guard let docId = measurement.id else {
            throw NSError(domain: "KeratoconusError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid document ID"])
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            try await db.collection("users")
                .document(userId)
                .collection("keratoconusMeasurements")
                .document(docId)
                .delete()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            // Update local collections
            if measurement.eye == .OD {
                measurementsOD.removeAll { $0.id == measurement.id }
            } else {
                measurementsOS.removeAll { $0.id == measurement.id }
            }
            
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
    
    // Get measurements for a specific eye
    func getMeasurements(for eye: EyeType) -> [KeratoconusMeasurement] {
        return eye == .OD ? measurementsOD : measurementsOS
    }
    
    // Check if there are any crosslinking events for a specific eye
    func hasCrossLinking(for eye: EyeType) -> Bool {
        let measurements = getMeasurements(for: eye)
        return measurements.contains { $0.hasCrossLinking }
    }
    
    // Get crosslinking dates for a specific eye
    func getCrossLinkingDates(for eye: EyeType) -> [Date] {
        let measurements = getMeasurements(for: eye)
        return measurements.filter { $0.hasCrossLinking }.map { $0.date }
    }
} 