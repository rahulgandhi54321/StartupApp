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
}

enum NoticePeriod: String, CaseIterable, Codable {
    case immediate    = "Immediate"
    case fifteen      = "15 Days"
    case thirty       = "30 Days"
    case sixty        = "60 Days"
    case ninety       = "90 Days"
}
