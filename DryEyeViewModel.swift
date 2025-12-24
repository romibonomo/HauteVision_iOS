import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DryEyeViewModel: ObservableObject {
    @Published var measurements: [DryEyeMeasurement] = []
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
                .collection("dryEyeMeasurements")
                .order(by: "date", descending: true)
                .getDocuments()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            measurements = snapshot.documents.compactMap { document in
                try? document.data(as: DryEyeMeasurement.self)
            }
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch measurements: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addMeasurement(_ measurement: DryEyeMeasurement) async throws {
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
                .collection("dryEyeMeasurements")
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
    
    func deleteMeasurement(_ measurement: DryEyeMeasurement) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to delete measurements"])
        }
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            try await db.collection("users")
                .document(userId)
                .collection("dryEyeMeasurements")
                .document(measurement.id)
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
    
    func getMeasurements(for eye: EyeType) -> [DryEyeMeasurement] {
        measurements.filter { $0.eye == eye }
    }
    
    // Chart data helpers for new metrics
    func getOsmolarityChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).compactMap { m in
            guard let value = m.osmolarity else { return nil }
            return (m.date, value, false)
        }
    }
    func getMeibographyChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).compactMap { m in
            guard let value = m.meibographyPercentLoss else { return nil }
            return (m.date, value, m.hadIPLOrRF)
        }
    }
    func getTMHChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).compactMap { m in
            guard let value = m.tmh else { return nil }
            return (m.date, value, false)
        }
    }
    func getMMP9ChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).map { m in
            (m.date, m.mmp9 ? 1.0 : 0.0, m.mmp9) // 1 for positive, 0 for negative, highlight if positive
        }
    }
    func getdryEyeQuestionnaireChartData(for eye: EyeType) -> [(Date, Double, Bool)] {
        getMeasurements(for: eye).map { m in
            (m.date, m.dryEyeQuestionnaire, false)
        }
    }
}

struct DryEyeMeasurement: Codable, Identifiable {
    var id: String = UUID().uuidString
    let date: Date
    let eye: EyeType
    let dryEyeQuestionnaire: Double
    let notes: String?
    let osmolarity: Double?
    let meibographyPercentLoss: Double?
    let hadIPLOrRF: Bool
    let hadRadioFrequency: Bool?
    let nextIPLDate: Date?
    let nextRadioFrequencyDate: Date?
    let tmh: Double?
    let mmp9: Bool
    let mmp9Note: String?
    let edited: Bool? // Track if this entry has been edited, optional for backward compatibility
    
    // Initializer for new measurements
    init(date: Date, eye: EyeType, dryEyeQuestionnaire: Double, notes: String?, osmolarity: Double?, meibographyPercentLoss: Double?, hadIPLOrRF: Bool, hadRadioFrequency: Bool, nextIPLDate: Date?, nextRadioFrequencyDate: Date?, tmh: Double?, mmp9: Bool, mmp9Note: String?, edited: Bool? = nil) {
        self.date = date
        self.eye = eye
        self.dryEyeQuestionnaire = dryEyeQuestionnaire
        self.notes = notes
        self.osmolarity = osmolarity
        self.meibographyPercentLoss = meibographyPercentLoss
        self.hadIPLOrRF = hadIPLOrRF
        self.hadRadioFrequency = hadRadioFrequency
        self.nextIPLDate = nextIPLDate
        self.nextRadioFrequencyDate = nextRadioFrequencyDate
        self.tmh = tmh
        self.mmp9 = mmp9
        self.mmp9Note = mmp9Note
        self.edited = edited
    }
    
    // Initializer for editing existing measurements
    init(id: String, date: Date, eye: EyeType, dryEyeQuestionnaire: Double, notes: String?, osmolarity: Double?, meibographyPercentLoss: Double?, hadIPLOrRF: Bool, hadRadioFrequency: Bool, nextIPLDate: Date?, nextRadioFrequencyDate: Date?, tmh: Double?, mmp9: Bool, mmp9Note: String?, edited: Bool?) {
        self.id = id
        self.date = date
        self.eye = eye
        self.dryEyeQuestionnaire = dryEyeQuestionnaire
        self.notes = notes
        self.osmolarity = osmolarity
        self.meibographyPercentLoss = meibographyPercentLoss
        self.hadIPLOrRF = hadIPLOrRF
        self.hadRadioFrequency = hadRadioFrequency
        self.nextIPLDate = nextIPLDate
        self.nextRadioFrequencyDate = nextRadioFrequencyDate
        self.tmh = tmh
        self.mmp9 = mmp9
        self.mmp9Note = mmp9Note
        self.edited = edited
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case eye
        case dryEyeQuestionnaire
        case notes
        case osmolarity
        case meibographyPercentLoss
        case hadIPLOrRF
        case hadRadioFrequency
        case nextIPLDate
        case nextRadioFrequencyDate
        case tmh
        case mmp9
        case mmp9Note
        case edited
    }
    
    // Computed property to handle the optional edited field
    var isEdited: Bool {
        return edited ?? false
    }
    
    // Computed property to handle the optional hadRadioFrequency field
    var hasRadioFrequency: Bool {
        return hadRadioFrequency ?? false
    }
} 
