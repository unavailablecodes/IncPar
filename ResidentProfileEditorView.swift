import SwiftUI
import PhotosUI
import UIKit

struct ResidentProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IncParStore

    let initialProfile: ResidentProfile?
    let defaultSocietyName: String?
    let onSave: ((ResidentProfile) -> Void)?

    @State private var name: String
    @State private var societyName: String
    @State private var occupancyType: ResidentOccupancyType
    @State private var flatNumber: String
    @State private var phoneDigits: String
    @State private var profileImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCreateSocietySheet = false
    @State private var residences: [ResidenceUnit]
    @State private var activeResidenceID: UUID?
    @State private var showAddResidenceSheet = false

    init(
        initialProfile: ResidentProfile? = nil,
        defaultSocietyName: String? = nil,
        onSave: ((ResidentProfile) -> Void)? = nil
    ) {
        self.initialProfile = initialProfile
        self.defaultSocietyName = defaultSocietyName
        self.onSave = onSave
        _name = State(initialValue: initialProfile?.name ?? "")
        _societyName = State(initialValue: initialProfile?.societyName ?? defaultSocietyName ?? "")
        _occupancyType = State(initialValue: initialProfile?.occupancyType ?? .owner)
        _flatNumber = State(initialValue: initialProfile?.flatNumber ?? "")
        _phoneDigits = State(initialValue: ResidentProfileEditorView.extractPhoneDigits(from: initialProfile?.phoneNumber ?? ""))
        _profileImageData = State(initialValue: initialProfile?.profileImageData)
        let initialResidences = ResidentProfileEditorView.initialResidences(from: initialProfile)
        _residences = State(initialValue: initialResidences)
        _activeResidenceID = State(initialValue: ResidentProfile.resolveActiveResidenceID(
            from: initialResidences,
            activeResidenceID: initialProfile?.activeResidenceID
        ))
    }

    private var canSave: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSociety = societyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFlat = flatNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !trimmedSociety.isEmpty && !trimmedFlat.isEmpty && phoneDigits.count == 10
    }

    private var formattedPhoneNumber: String {
        "+91 \(phoneDigits)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    avatarCard
                    formCard
                    infoCard
                    saveButton
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .onChange(of: phoneDigits) { _, newValue in
                phoneDigits = Self.sanitizedPhoneDigits(newValue)
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            profileImageData = data
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateSocietySheet) {
                RegisterSocietyView(initialSocietyName: societyName.trimmingCharacters(in: .whitespacesAndNewlines)) { newSociety in
                    societyName = newSociety.name
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showAddResidenceSheet) {
                ResidenceUnitEditorView(defaultSocietyName: societyName) { newResidence in
                    addResidence(newResidence, makeActive: true)
                }
                .environmentObject(store)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Your profile stays on the device")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            Text("Only your name is revealed in reports")
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var avatarCard: some View {
        VStack(spacing: 14) {
            profileImagePreview
            occupancyBadge

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Change Photo", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var profileImagePreview: some View {
        Group {
            if let profileImageData, let uiImage = UIImage(data: profileImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "person.crop.square.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
        }
        .frame(width: 108, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel("Name")
            TextField("Enter your name", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .premiumFieldStyle()

            societyAutocomplete

            fieldLabel("Resident Type")
            HStack(spacing: 8) {
                residentPill(.owner)
                residentPill(.tenant)
            }

            fieldLabel("Flat No")
            TextField("A-203 / 12B", text: $flatNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .premiumFieldStyle()

            fieldLabel("Mobile Number")
            HStack(spacing: 10) {
                Text("+91")
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(0.06))
                    )

                TextField("10 digits", text: $phoneDigits)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .premiumFieldStyle()
            }

            Text("This stays private in your local profile and will only reveal your name in reports.")
                .font(.system(size: 12.25, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            residenceSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Saved locally. It will sync with the master file when the app is online.", systemImage: "lock.shield")
                .font(.system(size: 12.25, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    private var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            HStack {
                Spacer()
                Label("Save Profile", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.black)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.45)
    }

    private func saveProfile() {
        guard canSave else { return }

        let activeResidence = ResidenceUnit(
            id: activeResidenceID ?? residences.first?.id ?? UUID(),
            societyName: societyName.trimmingCharacters(in: .whitespacesAndNewlines),
            flatNumber: flatNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            occupancyType: occupancyType,
            isActive: true,
            updatedAt: .now
        )

        let otherResidences = residences.filter { $0.id != activeResidence.id }
        let combinedResidences = [activeResidence] + otherResidences
            .map { residence in
                var updated = residence
                updated.isActive = false
                return updated
            }

        let profile = ResidentProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            societyName: societyName.trimmingCharacters(in: .whitespacesAndNewlines),
            occupancyType: occupancyType,
            flatNumber: flatNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: formattedPhoneNumber,
            profileImageData: profileImageData,
            residences: combinedResidences,
            activeResidenceID: activeResidence.id
        )

        store.saveResidentProfile(profile)
        onSave?(profile)
        dismiss()
    }

    private var residenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                fieldLabel("Residences")
                Spacer()
                Button {
                    showAddResidenceSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 12.25, weight: .semibold, design: .rounded))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.white.opacity(0.06))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            if residences.isEmpty {
                Text("Add extra flats here if you own or rent more than one residence.")
                    .font(.system(size: 12.25, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(residences.sorted(by: { $0.updatedAt > $1.updatedAt })) { residence in
                        residenceCard(residence)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func residenceCard(_ residence: ResidenceUnit) -> some View {
        let isActive = residence.id == activeResidenceID

        return Button {
            activateResidence(residence)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isActive
                            ? [Color.cyan.opacity(0.92), Color.blue.opacity(0.58)]
                            : [Color.white.opacity(0.07), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 4, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(residence.societyName)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if isActive {
                            Text("Active")
                                .font(.system(size: 10.25, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.cyan.opacity(0.92), Color.blue.opacity(0.60)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                    }

                    HStack(spacing: 8) {
                        Text(residence.flatNumber)
                            .font(.system(size: 12.5, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                        occupancyBadge(for: residence.occupancyType)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: isActive ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isActive ? .cyan : .secondary.opacity(0.8))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? .white.opacity(0.08) : .white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isActive ? .cyan.opacity(0.20) : .white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func occupancyBadge(for type: ResidentOccupancyType) -> some View {
        HStack(spacing: 4) {
            Text(type.shortLabel)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
            Text(type.title)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 4)
        .padding(.horizontal, 7)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: type == .owner
                        ? [Color.cyan.opacity(0.97), Color.blue.opacity(0.56)]
                        : [Color.orange.opacity(0.97), Color.yellow.opacity(0.64)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func activateResidence(_ residence: ResidenceUnit) {
        activeResidenceID = residence.id
        societyName = residence.societyName
        flatNumber = residence.flatNumber
        occupancyType = residence.occupancyType
        if !residences.contains(where: { $0.id == residence.id }) {
            residences.append(residence)
        }
    }

    private func addResidence(_ residence: ResidenceUnit, makeActive: Bool) {
        var newResidence = residence
        newResidence.isActive = makeActive
        if makeActive {
            residences = residences.map {
                var updated = $0
                updated.isActive = false
                return updated
            }
            activeResidenceID = newResidence.id
            societyName = newResidence.societyName
            flatNumber = newResidence.flatNumber
            occupancyType = newResidence.occupancyType
        }
        residences.append(newResidence)
    }

    private static func initialResidences(from profile: ResidentProfile?) -> [ResidenceUnit] {
        if let profile, !profile.residences.isEmpty {
            return profile.residences
        }

        guard let profile else { return [] }
        let society = profile.societyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let flat = profile.flatNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !society.isEmpty || !flat.isEmpty else { return [] }

        return [
            ResidenceUnit(
                societyName: profile.societyName,
                flatNumber: profile.flatNumber,
                occupancyType: profile.occupancyType,
                isActive: true,
                updatedAt: profile.updatedAt
            )
        ]
    }

    private var occupancyBadge: some View {
        HStack(spacing: 6) {
            Text(occupancyType.shortLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            Text(occupancyType.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: occupancyType == .owner
                            ? [
                                Color.cyan.opacity(0.97),
                                Color.blue.opacity(0.56)
                            ]
                            : [
                                Color.orange.opacity(0.97),
                                Color.yellow.opacity(0.64)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: occupancyType == .owner ? .cyan.opacity(0.14) : .orange.opacity(0.14), radius: 6, y: 2)
    }

    private func residentPill(_ type: ResidentOccupancyType) -> some View {
        Button {
            occupancyType = type
        } label: {
            HStack(spacing: 6) {
                Text(type.shortLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Text(type.title)
                    .font(.system(size: 12.25, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        occupancyType == type
                        ? LinearGradient(
                            colors: type == .owner
                            ? [
                                Color.cyan.opacity(0.97),
                                Color.blue.opacity(0.56)
                            ]
                            : [
                                Color.orange.opacity(0.97),
                                Color.yellow.opacity(0.64)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(occupancyType == type ? .cyan.opacity(0.24) : .white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: occupancyType == type ? (type == .owner ? .cyan.opacity(0.12) : .orange.opacity(0.12)) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private static func extractPhoneDigits(from phoneNumber: String) -> String {
        phoneNumber.filter(\.isNumber).suffix(10).string
    }

    private static func sanitizedPhoneDigits(_ input: String) -> String {
        input.filter(\.isNumber).prefix(10).string
    }

    private var societyAutocomplete: some View {
        let query = societyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = matchingSocieties(for: query)

        return VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Society Name")

            TextField("Palm Grove Heights", text: $societyName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .premiumFieldStyle()

            if !query.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    if matches.isEmpty {
                        Button {
                            showCreateSocietySheet = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.cyan.opacity(0.85))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Not listed? Create new society")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text("Add it now and continue the profile setup.")
                                        .font(.system(size: 11.5, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 11)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(matches.prefix(5), id: \.id) { society in
                                Button {
                                    societyName = society.name
                                } label: {
                                    HStack(spacing: 10) {
                                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                                            .fill(Color.cyan.opacity(0.88))
                                            .frame(width: 3, height: 22)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(society.name)
                                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.primary)
                                            Text("\(society.city), \(society.state)")
                                                .font(.system(size: 11.5, weight: .regular, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer(minLength: 0)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                showCreateSocietySheet = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.cyan.opacity(0.85))

                                    Text("Create a new society with this name")
                                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)

                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
        }
    }

    private func matchingSocieties(for query: String) -> [Society] {
        guard !query.isEmpty else { return [] }
        return store.societies.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query) ||
            $0.state.localizedCaseInsensitiveContains(query)
        }
    }
}

private extension StringProtocol {
    var string: String { String(self) }
}

private extension View {
    func premiumFieldStyle() -> some View {
        self
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
    }
}
