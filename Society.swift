import Foundation

struct Society: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var city: String
    var state: String

    init(id: UUID = UUID(), name: String, city: String, state: String) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
    }
}
