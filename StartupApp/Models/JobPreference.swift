import Foundation

enum Gender: String, CaseIterable, Codable {
    case male          = "Male"
    case female        = "Female"
    case nonBinary     = "Non-binary"
    case preferNotSay  = "Prefer not to say"
}

enum PreferredLocation: String, CaseIterable, Codable {
    case bangaloreIndia  = "Bangalore, India"
    case remoteAnywhere  = "Remote (Anywhere)"
    case hybrid          = "Hybrid"
    case mumbai          = "Mumbai, India"
    case delhi           = "Delhi, India"
    case hyderabad       = "Hyderabad, India"
    case pune            = "Pune, India"
    case chennai         = "Chennai, India"
}

extension PreferredLocation {
    /// Comma-joined string → Set of locations
    static func decode(_ raw: String) -> Set<PreferredLocation> {
        Set(raw.split(separator: "|").compactMap { PreferredLocation(rawValue: String($0).trimmingCharacters(in: .whitespaces)) })
    }
    /// Set → pipe-joined string for DB storage
    static func encode(_ set: Set<PreferredLocation>) -> String {
        set.map(\.rawValue).sorted().joined(separator: " | ")
    }
}

enum NoticePeriod: String, CaseIterable, Codable {
    case immediate    = "Immediate"
    case fifteen      = "15 Days"
    case thirty       = "30 Days"
    case sixty        = "60 Days"
    case ninety       = "90 Days"
}
