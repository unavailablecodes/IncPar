import Foundation

struct ViolationReport: Identifiable, Codable, Hashable {
    var id: UUID
    var createdAt: Date
    var societyID: UUID
    var societyName: String
    var societyCity: String
    var societyState: String
    var vehicleNumber: String?
    var reporterName: String?
    var reporterResidenceID: UUID?
    var reporterResidenceSocietyName: String?
    var reporterResidenceFlatNumber: String?
    var reporterResidenceOccupancyType: ResidentOccupancyType?
    var violationType: String
    var parkingArea: String
    var comments: String
    var primaryImageData: Data
    var secondaryImageData: Data?
    var syncStatus: String
    var isAnonymous: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        societyID: UUID,
        societyName: String,
        societyCity: String,
        societyState: String,
        vehicleNumber: String? = nil,
        reporterName: String? = nil,
        reporterResidenceID: UUID? = nil,
        reporterResidenceSocietyName: String? = nil,
        reporterResidenceFlatNumber: String? = nil,
        reporterResidenceOccupancyType: ResidentOccupancyType? = nil,
        violationType: String,
        parkingArea: String,
        comments: String,
        primaryImageData: Data,
        secondaryImageData: Data? = nil,
        syncStatus: String = "pending",
        isAnonymous: Bool = true
    ) {
        self.id = id
        self.createdAt = createdAt
        self.societyID = societyID
        self.societyName = societyName
        self.societyCity = societyCity
        self.societyState = societyState
        self.vehicleNumber = vehicleNumber
        self.reporterName = reporterName
        self.reporterResidenceID = reporterResidenceID
        self.reporterResidenceSocietyName = reporterResidenceSocietyName
        self.reporterResidenceFlatNumber = reporterResidenceFlatNumber
        self.reporterResidenceOccupancyType = reporterResidenceOccupancyType
        self.violationType = violationType
        self.parkingArea = parkingArea
        self.comments = comments
        self.primaryImageData = primaryImageData
        self.secondaryImageData = secondaryImageData
        self.syncStatus = syncStatus
        self.isAnonymous = isAnonymous
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case societyID
        case societyName
        case societyCity
        case societyState
        case vehicleNumber
        case reporterName
        case reporterResidenceID
        case reporterResidenceSocietyName
        case reporterResidenceFlatNumber
        case reporterResidenceOccupancyType
        case violationType
        case parkingArea
        case comments
        case primaryImageData
        case secondaryImageData
        case syncStatus
        case isAnonymous
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        societyID = try container.decode(UUID.self, forKey: .societyID)
        societyName = try container.decode(String.self, forKey: .societyName)
        societyCity = try container.decode(String.self, forKey: .societyCity)
        societyState = try container.decode(String.self, forKey: .societyState)
        vehicleNumber = try container.decodeIfPresent(String.self, forKey: .vehicleNumber)
        reporterName = try container.decodeIfPresent(String.self, forKey: .reporterName)
        reporterResidenceID = try container.decodeIfPresent(UUID.self, forKey: .reporterResidenceID)
        reporterResidenceSocietyName = try container.decodeIfPresent(String.self, forKey: .reporterResidenceSocietyName)
        reporterResidenceFlatNumber = try container.decodeIfPresent(String.self, forKey: .reporterResidenceFlatNumber)
        reporterResidenceOccupancyType = try container.decodeIfPresent(ResidentOccupancyType.self, forKey: .reporterResidenceOccupancyType)
        violationType = try container.decode(String.self, forKey: .violationType)
        parkingArea = try container.decode(String.self, forKey: .parkingArea)
        comments = try container.decode(String.self, forKey: .comments)
        primaryImageData = try container.decode(Data.self, forKey: .primaryImageData)
        secondaryImageData = try container.decodeIfPresent(Data.self, forKey: .secondaryImageData)
        syncStatus = try container.decodeIfPresent(String.self, forKey: .syncStatus) ?? "pending"
        isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(societyID, forKey: .societyID)
        try container.encode(societyName, forKey: .societyName)
        try container.encode(societyCity, forKey: .societyCity)
        try container.encode(societyState, forKey: .societyState)
        try container.encode(vehicleNumber, forKey: .vehicleNumber)
        try container.encodeIfPresent(reporterName, forKey: .reporterName)
        try container.encodeIfPresent(reporterResidenceID, forKey: .reporterResidenceID)
        try container.encodeIfPresent(reporterResidenceSocietyName, forKey: .reporterResidenceSocietyName)
        try container.encodeIfPresent(reporterResidenceFlatNumber, forKey: .reporterResidenceFlatNumber)
        try container.encodeIfPresent(reporterResidenceOccupancyType, forKey: .reporterResidenceOccupancyType)
        try container.encode(violationType, forKey: .violationType)
        try container.encode(parkingArea, forKey: .parkingArea)
        try container.encode(comments, forKey: .comments)
        try container.encode(primaryImageData, forKey: .primaryImageData)
        try container.encodeIfPresent(secondaryImageData, forKey: .secondaryImageData)
        try container.encode(syncStatus, forKey: .syncStatus)
        try container.encode(isAnonymous, forKey: .isAnonymous)
    }

    var reporterResidenceSummary: String {
        let society = reporterResidenceSocietyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let flat = reporterResidenceFlatNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let type = reporterResidenceOccupancyType?.title ?? ""
        let parts = [society, flat, type].filter { !$0.isEmpty }
        return parts.isEmpty ? "Not set" : parts.joined(separator: " • ")
    }
}
