import SwiftData
import Foundation

@Model
final class UserProfile {
    var name: String
    var email: String
    var phone: String
    var updatedAt: Date

    init(name: String, email: String, phone: String) {
        self.name = name
        self.email = email
        self.phone = phone
        self.updatedAt = Date()
    }
}
