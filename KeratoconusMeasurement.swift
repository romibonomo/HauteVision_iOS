import Foundation
import FirebaseFirestore

struct KeratoconusMeasurement: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let date: Date
    let eye: EyeType
    let k2: Double
    let kMax: Double
    let thinnestPachymetry: Int
    let thickestEpithelialSpot: Double
    let thinnestEpithelialSpot: Int
    let keratoconusRiskScore: Int
    let documentedCylindricalIncrease: Bool
    let subjectiveVisionLoss: Bool
    let hasCrossLinking: Bool
    let notes: String?
    let edited: Bool? // Track if this entry has been edited, optional for backward compatibility
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case eye
        case k2
        case kMax
        case thinnestPachymetry
        case thickestEpithelialSpot
        case thinnestEpithelialSpot
        case keratoconusRiskScore
        case documentedCylindricalIncrease
        case subjectiveVisionLoss
        case hasCrossLinking
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
         k2: Double,
         kMax: Double,
         thinnestPachymetry: Int,
         thickestEpithelialSpot: Double,
         thinnestEpithelialSpot: Int,
         keratoconusRiskScore: Int,
         documentedCylindricalIncrease: Bool = false,
         subjectiveVisionLoss: Bool = false,
         hasCrossLinking: Bool = false,
         notes: String? = nil,
         edited: Bool? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.eye = eye
        self.k2 = k2
        self.kMax = kMax
        self.thinnestPachymetry = thinnestPachymetry
        self.thickestEpithelialSpot = thickestEpithelialSpot
        self.thinnestEpithelialSpot = thinnestEpithelialSpot
        self.keratoconusRiskScore = keratoconusRiskScore
        self.documentedCylindricalIncrease = documentedCylindricalIncrease
        self.subjectiveVisionLoss = subjectiveVisionLoss
        self.hasCrossLinking = hasCrossLinking
        self.notes = notes
        self.edited = edited
    }
} 