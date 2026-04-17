import Foundation

struct Job: Identifiable, Codable, Equatable {
    var id:          String
    var title:       String
    var company:     String
    var location:    String
    var description: String
    var url:         String
    var salary:      String
    var posted_at:   String
    var category:    String
}

struct JobsResponse: Codable {
    var jobs:    [Job]
    var total:   Int
    var page:    Int
    var keyword: String?
    var error:   String?
}
