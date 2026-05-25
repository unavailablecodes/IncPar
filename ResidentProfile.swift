import Foundation

struct ResidenceUnit: Identifiable, Codable, Hashable {
    var id: UUID
    var societyName: String
    var flatNumber: String
    var occupancyType: ResidentOccupancyType
    var isActive: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        societyName: String,
        flatNumber: String,
        occupancyType: ResidentOccupancyType = .owner,
        isActive: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.societyName = societyName
        self.flatNumber = flatNumber
        self.occupancyType = occupancyType
        self.isActive = isActive
        self.updatedAt = updatedAt
    }

    var displayTitle: String {
        [societyName, flatNumber].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: " • ")
    }
}

struct ResidentProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var societyName: String
    var occupancyType: ResidentOccupancyType
    var flatNumber: String
    var phoneNumber: String
    var profileImageData: Data?
    var residences: [ResidenceUnit]
    var activeResidenceID: UUID?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        societyName: String,
        occupancyType: ResidentOccupancyType = .owner,
        flatNumber: String,
        phoneNumber: String,
        profileImageData: Data? = nil,
        residences: [ResidenceUnit] = [],
        activeResidenceID: UUID? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.profileImageData = profileImageData
        self.updatedAt = updatedAt

        let legacyResidence = ResidenceUnit(
            societyName: societyName,
            flatNumber: flatNumber,
            occupancyType: occupancyType,
            isActive: true,
            updatedAt: updatedAt
        )

        let sourceResidences = residences.isEmpty ? (legacyResidence.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [legacyResidence]) : residences
        let resolvedActiveResidenceID = Self.resolveActiveResidenceID(from: sourceResidences, activeResidenceID: activeResidenceID)
        let resolvedResidences = Self.normalizeResidences(sourceResidences, activeResidenceID: resolvedActiveResidenceID)
        self.residences = resolvedResidences
        self.activeResidenceID = resolvedActiveResidenceID

        if let activeResidence = resolvedResidences.first(where: { $0.id == resolvedActiveResidenceID }) ?? resolvedResidences.first {
            self.societyName = activeResidence.societyName
            self.occupancyType = activeResidence.occupancyType
            self.flatNumber = activeResidence.flatNumber
        } else {
            self.societyName = societyName
            self.occupancyType = occupancyType
            self.flatNumber = flatNumber
        }

        self.phoneNumber = phoneNumber
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case societyName
        case occupancyType
        case flatNumber
        case phoneNumber
        case profileImageData
        case residences
        case activeResidenceID
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        societyName = try container.decodeIfPresent(String.self, forKey: .societyName) ?? ""
        occupancyType = try container.decodeIfPresent(ResidentOccupancyType.self, forKey: .occupancyType) ?? .owner
        flatNumber = try container.decode(String.self, forKey: .flatNumber)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        profileImageData = try container.decodeIfPresent(Data.self, forKey: .profileImageData)
        residences = try container.decodeIfPresent([ResidenceUnit].self, forKey: .residences) ?? []
        activeResidenceID = try container.decodeIfPresent(UUID.self, forKey: .activeResidenceID)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now

        if residences.isEmpty, !societyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !flatNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            residences = [
                ResidenceUnit(
                    societyName: societyName,
                    flatNumber: flatNumber,
                    occupancyType: occupancyType,
                    isActive: true,
                    updatedAt: updatedAt
                )
            ]
        }

        activeResidenceID = Self.resolveActiveResidenceID(from: residences, activeResidenceID: activeResidenceID)
        residences = Self.normalizeResidences(residences, activeResidenceID: activeResidenceID)

        if let activeResidence = residences.first(where: { $0.id == activeResidenceID }) ?? residences.first {
            societyName = activeResidence.societyName
            occupancyType = activeResidence.occupancyType
            flatNumber = activeResidence.flatNumber
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(societyName, forKey: .societyName)
        try container.encode(occupancyType, forKey: .occupancyType)
        try container.encode(flatNumber, forKey: .flatNumber)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(profileImageData, forKey: .profileImageData)
        try container.encode(residences, forKey: .residences)
        try container.encodeIfPresent(activeResidenceID, forKey: .activeResidenceID)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    var activeResidence: ResidenceUnit? {
        guard !residences.isEmpty else { return nil }
        if let activeResidenceID, let activeResidence = residences.first(where: { $0.id == activeResidenceID }) {
            return activeResidence
        }
        if let activeResidence = residences.first(where: { $0.isActive }) {
            return activeResidence
        }
        return residences.first
    }

    mutating func activateResidence(with id: UUID) {
        guard residences.contains(where: { $0.id == id }) else { return }
        activeResidenceID = id
        residences = Self.normalizeResidences(residences, activeResidenceID: id)

        if let activeResidence = activeResidence {
            societyName = activeResidence.societyName
            occupancyType = activeResidence.occupancyType
            flatNumber = activeResidence.flatNumber
        }
    }

    mutating func normalizeResidences() {
        activeResidenceID = Self.resolveActiveResidenceID(from: residences, activeResidenceID: activeResidenceID)
        residences = Self.normalizeResidences(residences, activeResidenceID: activeResidenceID)

        if let activeResidence = activeResidence {
            societyName = activeResidence.societyName
            occupancyType = activeResidence.occupancyType
            flatNumber = activeResidence.flatNumber
        }
    }

    static func normalizeResidences(_ residences: [ResidenceUnit], activeResidenceID: UUID?) -> [ResidenceUnit] {
        guard !residences.isEmpty else { return [] }
        let resolvedActiveResidenceID = resolveActiveResidenceID(from: residences, activeResidenceID: activeResidenceID)

        return residences.map { residence in
            var updated = residence
            updated.isActive = updated.id == resolvedActiveResidenceID
            return updated
        }
    }

    static func resolveActiveResidenceID(from residences: [ResidenceUnit], activeResidenceID: UUID?) -> UUID? {
        if let activeResidenceID, residences.contains(where: { $0.id == activeResidenceID }) {
            return activeResidenceID
        }

        if let activeResidence = residences.first(where: { $0.isActive }) {
            return activeResidence.id
        }

        return residences.first?.id
    }
}

enum ResidentOccupancyType: String, Codable, Hashable, CaseIterable, Identifiable {
    case owner
    case tenant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Owner"
        case .tenant: return "Tenant"
        }
    }

    var shortLabel: String {
        switch self {
        case .owner: return "O"
        case .tenant: return "T"
        }
    }
}
