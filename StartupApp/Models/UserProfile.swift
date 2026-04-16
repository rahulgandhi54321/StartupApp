import SwiftData
import Foundation

enum JobRole: String, CaseIterable, Codable {
    case product          = "Product"
    case investmentBanking = "Investment Banking"

    var icon: String {
        switch self {
        case .product:           return "briefcase.fill"
        case .investmentBanking: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: String {
        switch self {
        case .product:           return "6C63FF"
        case .investmentBanking: return "F59E0B"
        }
    }
}

@Model
final class UserProfile {
    var name: String
    var email: String
    var phone: String
    var jobRole: String
    var updatedAt: Date

    init(name: String, email: String, phone: String, jobRole: String = "") {
        self.name = name
        self.email = email
        self.phone = phone
        self.jobRole = jobRole
        self.updatedAt = Date()
    }
}
