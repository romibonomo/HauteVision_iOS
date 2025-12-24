import Foundation
import FirebaseFirestore

struct RetinaInjectionMeasurement: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let date: Date
    let eye: EyeType
    let medication: String
    let isNewMedication: Bool
    let vision: String
    let crt: Double
    let notes: String?
    let reminderDate: Date?
    let edited: Bool? // Track if this entry has been edited, optional for backward compatibility
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case eye
        case medication
        case isNewMedication
        case vision
        case crt
        case notes
        case reminderDate
        case edited
    }
    
    // Computed property to handle the optional edited field
    var isEdited: Bool {
        return edited ?? false
    }
    
    init(id: String? = nil,
         userId: String,
         date: Date = Date(),
         eye: EyeType,
         medication: String,
         isNewMedication: Bool = false,
         vision: String,
         crt: Double,
         notes: String? = nil,
         reminderDate: Date? = nil,
         edited: Bool? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.eye = eye
        self.medication = medication
        self.isNewMedication = isNewMedication
        self.vision = vision
        self.crt = crt
        self.notes = notes
        self.reminderDate = reminderDate
        self.edited = edited
    }
} 