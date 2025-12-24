import Foundation
import FirebaseFirestore

struct TransplantMeasurement: Identifiable, Codable {
    var id: String?
    let userId: String
    let date: Date
    let eye: EyeType
    let ecd: Double
    let pachymetry: Int
    let iop: Double
    let steroidRegimen: String?
    let medicationName: String?
    let notes: String?
    let reminderTimes: [Date]?
    let isRegraft: Bool
    let edited: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case eye
        case ecd
        case pachymetry
        case iop
        case steroidRegimen
        case medicationName
        case notes
        case reminderTimes
        case isRegraft
        case edited
    }
    
    // Computed property to handle the optional edited field
    var isEdited: Bool {
        return edited ?? false
    }
    
    init(id: String? = nil,
         userId: String,
         date: Date,
         eye: EyeType,
         ecd: Double,
         pachymetry: Int,
         iop: Double,
         steroidRegimen: String? = nil,
         medicationName: String? = nil,
         notes: String? = nil,
         reminderTimes: [Date]? = nil,
         isRegraft: Bool = false,
         edited: Bool? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.eye = eye
        self.ecd = ecd
        self.pachymetry = pachymetry
        self.iop = iop
        self.steroidRegimen = steroidRegimen
        self.medicationName = medicationName
        self.notes = notes
        self.reminderTimes = reminderTimes
        self.isRegraft = isRegraft
        self.edited = edited
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        let timestamp = data["date"] as? Timestamp
        let date = timestamp?.dateValue() ?? Date()
        
        let eyeString = data["eye"] as? String ?? ""
        let eye = EyeType(rawValue: eyeString) ?? EyeType(rawValue: "right")!
        
        let ecd = data["ecd"] as? Double ?? 0.0
        let pachymetry = data["pachymetry"] as? Int ?? 0
        let iop = data["iop"] as? Double ?? 0.0
        let steroidRegimen = data["steroidRegimen"] as? String
        let medicationName = data["medicationName"] as? String
        let notes = data["notes"] as? String
        
        // Convert Firestore timestamps to Date objects for reminder times
        let reminderTimestamps = data["reminderTimes"] as? [Timestamp] ?? []
        let reminderTimes = reminderTimestamps.map { $0.dateValue() }
        
        let isRegraft = data["isRegraft"] as? Bool ?? false
        let edited = data["edited"] as? Bool
        let userId = data["userId"] as? String ?? ""
        
        self.id = document.documentID
        self.userId = userId
        self.date = date
        self.eye = eye
        self.ecd = ecd
        self.pachymetry = pachymetry
        self.iop = iop
        self.steroidRegimen = steroidRegimen
        self.medicationName = medicationName
        self.notes = notes
        self.reminderTimes = reminderTimes.isEmpty ? nil : reminderTimes
        self.isRegraft = isRegraft
        self.edited = edited
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "date": Timestamp(date: date),
            "eye": eye.rawValue,
            "ecd": ecd,
            "pachymetry": pachymetry,
            "iop": iop,
            "isRegraft": isRegraft
        ]
        
        // Add optional fields if they exist
        if let steroidRegimen = steroidRegimen {
            dict["steroidRegimen"] = steroidRegimen
        }
        if let medicationName = medicationName {
            dict["medicationName"] = medicationName
        }
        if let notes = notes {
            dict["notes"] = notes
        }
        if let edited = edited {
            dict["edited"] = edited
        }
        
        // Convert reminder times to Firestore timestamps
        if let reminderTimes = reminderTimes {
            dict["reminderTimes"] = reminderTimes.map { Timestamp(date: $0) }
        }
        
        return dict
    }
} 