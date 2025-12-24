import Foundation
import FirebaseFirestore

struct GlaucomaMeasurement: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let date: Date
    let eye: EyeType
    
    // Patient history
    let hasGlaucomaFamilyHistory: Bool
    let hasLasikSurgery: Bool
    
    // IOP measurement with timestamp
    let iop: Double
    let iopTime: Date
    
    // Visual field parameters
    let meanDefect: Double
    let patternStandardDeviation: Double
    
    // OCT measurements
    let rnflOverall: Int
    let rnflSuperior: Int
    let rnflInferior: Int
    let macularGCC: Int
    
    // Changes
    let hasVisualFieldChange: Bool
    let hasRNFLChange: Bool
    
    // Medication changes
    let newEyeDrops: Bool
    let eyeDropsDetails: String?
    
    // Additional info
    let notes: String?
    let edited: Bool? // Track if this entry has been edited, optional for backward compatibility
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case eye
        case hasGlaucomaFamilyHistory
        case hasLasikSurgery
        case iop
        case iopTime
        case meanDefect
        case patternStandardDeviation
        case rnflOverall
        case rnflSuperior
        case rnflInferior
        case macularGCC
        case hasVisualFieldChange
        case hasRNFLChange
        case newEyeDrops
        case eyeDropsDetails
        case notes
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
         hasGlaucomaFamilyHistory: Bool = false,
         hasLasikSurgery: Bool = false,
         iop: Double,
         iopTime: Date = Date(),
         meanDefect: Double,
         patternStandardDeviation: Double,
         rnflOverall: Int,
         rnflSuperior: Int,
         rnflInferior: Int,
         macularGCC: Int,
         hasVisualFieldChange: Bool = false,
         hasRNFLChange: Bool = false,
         newEyeDrops: Bool = false,
         eyeDropsDetails: String? = nil,
         notes: String? = nil,
         edited: Bool? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.eye = eye
        self.hasGlaucomaFamilyHistory = hasGlaucomaFamilyHistory
        self.hasLasikSurgery = hasLasikSurgery
        self.iop = iop
        self.iopTime = iopTime
        self.meanDefect = meanDefect
        self.patternStandardDeviation = patternStandardDeviation
        self.rnflOverall = rnflOverall
        self.rnflSuperior = rnflSuperior
        self.rnflInferior = rnflInferior
        self.macularGCC = macularGCC
        self.hasVisualFieldChange = hasVisualFieldChange
        self.hasRNFLChange = hasRNFLChange
        self.newEyeDrops = newEyeDrops
        self.eyeDropsDetails = eyeDropsDetails
        self.notes = notes
        self.edited = edited
    }
} 