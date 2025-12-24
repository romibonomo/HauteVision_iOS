import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let email: String
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        return ""
    }
    
    // Custom coding keys to handle date formatting
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
    }
    
    // Custom decoder to handle optional date
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.email = try container.decode(String.self, forKey: .email)
    }
    
    // Custom initializer for creating a user
    init(name: String, email: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email
    }
} 
