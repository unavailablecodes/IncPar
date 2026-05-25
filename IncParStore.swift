import Foundation
import SwiftUI
import Combine

@MainActor
final class IncParStore: ObservableObject {
    @Published var societies: [Society] = []
    @Published var violationReports: [ViolationReport] = []
    @Published var residentProfile: ResidentProfile?

    private let societiesFileName = "societies.json"
    private let reportsFileName = "violation_reports.json"
    private let profileFileName = "resident_profile.json"
    private let seedSocieties = [
        Society(name: "Palm Grove Heights", city: "Bengaluru", state: "Karnataka"),
        Society(name: "Maple Residency", city: "Pune", state: "Maharashtra"),
        Society(name: "Lake View Towers", city: "Hyderabad", state: "Telangana")
    ]

    init() {
        loadSocieties()
        loadViolationReports()
        loadResidentProfile()

        if societies.isEmpty {
            societies = seedSocieties
            saveSocieties()
        }
    }

    func addSociety(name: String, city: String, state: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)
        let society = Society(name: trimmedName, city: trimmedCity, state: trimmedState)
        societies.append(society)
        saveSocieties()
    }

    func addViolationReport(_ report: ViolationReport) {
        violationReports.append(report)
        saveViolationReports()
    }

    func saveResidentProfile(_ profile: ResidentProfile) {
        var normalizedProfile = profile
        normalizedProfile.normalizeResidences()
        residentProfile = normalizedProfile
        saveResidentProfile()
    }

    func saveResidentProfile(
        name: String,
        societyName: String,
        occupancyType: ResidentOccupancyType,
        flatNumber: String,
        phoneNumber: String,
        profileImageData: Data?
    ) {
        let profile = ResidentProfile(
            name: name,
            societyName: societyName,
            occupancyType: occupancyType,
            flatNumber: flatNumber,
            phoneNumber: phoneNumber,
            profileImageData: profileImageData
        )
        saveResidentProfile(profile)
    }

    func setActiveResidence(_ residenceID: UUID) {
        guard var profile = residentProfile else { return }
        profile.activateResidence(with: residenceID)
        saveResidentProfile(profile)
    }

    func deleteViolationReport(_ reportID: UUID) {
        violationReports.removeAll { $0.id == reportID }
        saveViolationReports()
    }

    func markPendingViolationReportsSynced() {
        var didChange = false

        for index in violationReports.indices {
            if violationReports[index].syncStatus.lowercased() == "pending" {
                violationReports[index].syncStatus = "synced"
                didChange = true
            }
        }

        if didChange {
            saveViolationReports()
        }
    }

    private func loadSocieties() {
        guard let data = try? Data(contentsOf: societiesURL) else { return }
        societies = (try? JSONDecoder().decode([Society].self, from: data)) ?? []
    }

    private func saveSocieties() {
        guard let data = try? JSONEncoder().encode(societies) else { return }
        try? data.write(to: societiesURL, options: [.atomic])
    }

    private func loadViolationReports() {
        guard let data = try? Data(contentsOf: reportsURL) else { return }
        violationReports = (try? JSONDecoder().decode([ViolationReport].self, from: data)) ?? []
    }

    private func loadResidentProfile() {
        guard let data = try? Data(contentsOf: profileURL) else { return }
        guard let loadedProfile = try? JSONDecoder().decode(ResidentProfile.self, from: data) else { return }
        var normalizedProfile = loadedProfile
        normalizedProfile.normalizeResidences()
        residentProfile = normalizedProfile
    }

    private func saveViolationReports() {
        guard let data = try? JSONEncoder().encode(violationReports) else { return }
        try? data.write(to: reportsURL, options: [.atomic])
    }

    private func saveResidentProfile() {
        guard let residentProfile, let data = try? JSONEncoder().encode(residentProfile) else { return }
        try? data.write(to: profileURL, options: [.atomic])
    }

    private var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDirectory = base.appendingPathComponent("IncPar", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            try? FileManager.default.createDirectory(
                at: appDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return appDirectory
    }

    private var societiesURL: URL {
        supportDirectory.appendingPathComponent(societiesFileName)
    }

    private var reportsURL: URL {
        supportDirectory.appendingPathComponent(reportsFileName)
    }

    private var profileURL: URL {
        supportDirectory.appendingPathComponent(profileFileName)
    }
}
