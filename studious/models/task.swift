import Foundation

struct Task: Identifiable, Codable {
    var id: Int
    var title: String
    var start_time: String?
    var end_time: String?
    var completed: Bool
}
