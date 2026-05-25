import SwiftUI
import UIKit

struct ResidentProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IncParStore
    @State private var showEditor = false
    @State private var expandedSocieties: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let profile = store.residentProfile {
                        profileCard(profile)
                    } else {
                        emptyState
                    }
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
            .sheet(isPresented: $showEditor) {
                ResidentProfileEditorView(initialProfile: store.residentProfile) { _ in }
                    .environmentObject(store)
            }
        }
    }

    private func profileCard(_ profile: ResidentProfile) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 8) {
                    profileAvatar(profile)
                    occupancyBadge(profile.occupancyType)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .font(.system(size: 21, weight: .semibold, design: .rounded))

                        occupancyBadge(profile.occupancyType)
                    }

                    Text("Local resident profile")
                        .font(.system(size: 12.75, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            elegantSocietyRow(profile.societyName.isEmpty ? "Not set yet" : profile.societyName)
            profileRow(title: "Flat No", value: profile.flatNumber)
            profileRow(title: "Phone", value: profile.phoneNumber)
            residencesSection(profile)

            Text("This profile stays private on the device and only the name is shown when you reveal identity in a report.")
                .font(.system(size: 12.25, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)

            Button {
                showEditor = true
            } label: {
                HStack {
                    Spacer()
                    Label("Edit Profile", systemImage: "square.and.pencil")
                        .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.16),
                                    Color.white.opacity(0.06),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.overlay)
                        .mask(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
        )
    }

    private func profileAvatar(_ profile: ResidentProfile) -> some View {
        Group {
            if let data = profile.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private func occupancyBadge(_ occupancyType: ResidentOccupancyType) -> some View {
        HStack(spacing: 4) {
            Text(occupancyType.shortLabel)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
            Text(occupancyType.title)
                .font(.system(size: 10.75, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: occupancyType == .owner
                        ? [
                            Color.cyan.opacity(0.96),
                            Color.blue.opacity(0.56)
                        ]
                        : [
                            Color.orange.opacity(0.96),
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

    private func profileRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 74, alignment: .leading)

            Text(value)
                .font(.system(size: 13.75, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
    }

    private func residencesSection(_ profile: ResidentProfile) -> some View {
        let residences = profile.residences.sorted(by: { $0.updatedAt > $1.updatedAt })
        let groupedBySociety = Dictionary(grouping: residences) { residence in
            residence.societyName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let societyNames = groupedBySociety.keys.sorted {
            let leftUpdated = groupedBySociety[$0]?.first?.updatedAt ?? .distantPast
            let rightUpdated = groupedBySociety[$1]?.first?.updatedAt ?? .distantPast
            return leftUpdated > rightUpdated
        }
        let defaultExpanded = Set(societyNames.filter { societyName in
            (groupedBySociety[societyName] ?? []).contains { profileHasActiveResidence($0.id) }
        })

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Residences")
                    .font(.system(size: 12.25, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                Button {
                    showEditor = true
                } label: {
                    Label("Manage", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.white.opacity(0.05))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            if residences.isEmpty {
                Text("Add more flats here to switch the active one later.")
                    .font(.system(size: 12.25, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else {
                VStack(spacing: 12) {
                    ForEach(societyNames, id: \.self) { societyName in
                        let groupResidences = (groupedBySociety[societyName] ?? []).sorted(by: { $0.updatedAt > $1.updatedAt })
                        let hasActiveResidence = groupResidences.contains { profileHasActiveResidence($0.id) }
                        societyResidenceGroup(
                            societyName: societyName.isEmpty ? "Unlisted society" : societyName,
                            residences: groupResidences,
                            isActiveGroup: hasActiveResidence,
                            isExpanded: expandedSocieties.contains(societyName) || defaultExpanded.contains(societyName),
                            onToggleExpansion: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                                    if expandedSocieties.contains(societyName) {
                                        expandedSocieties.remove(societyName)
                                    } else {
                                        expandedSocieties.insert(societyName)
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.top, 2)
        .onAppear {
            if expandedSocieties.isEmpty {
                expandedSocieties = defaultExpanded
            }
        }
    }

    private func societyResidenceGroup(
        societyName: String,
        residences: [ResidenceUnit],
        isActiveGroup: Bool,
        isExpanded: Bool,
        onToggleExpansion: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggleExpansion) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(societyName)
                            .font(.system(size: 15.25, weight: .semibold, design: .rounded))
                            .foregroundStyle(isActiveGroup ? Color.primary : Color.primary.opacity(0.96))
                            .lineLimit(2)

                        Text("\(residences.count) \(residences.count == 1 ? "residence" : "residences")")
                            .font(.system(size: 11.5, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    if isExpanded, isActiveGroup {
                        Text("Active society")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan.opacity(0.96), Color.blue.opacity(0.62)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isActiveGroup ? .cyan : .secondary.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.cyan.opacity(0.10),
                                Color.white.opacity(0.08),
                                Color.cyan.opacity(0.10),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                    .padding(.bottom, 2)

                VStack(spacing: 10) {
                    ForEach(residences) { residence in
                        residenceCard(residence, showSocietyName: false)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isActiveGroup ? .cyan.opacity(0.16) : .white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: isActiveGroup ? .cyan.opacity(0.08) : .black.opacity(0.04), radius: isActiveGroup ? 16 : 10, y: 5)
        )
    }

    private func residenceCard(_ residence: ResidenceUnit, showSocietyName: Bool = true) -> some View {
        let isActive = profileHasActiveResidence(residence.id)

        return Button {
            if !isActive {
                store.setActiveResidence(residence.id)
            }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isActive
                            ? [Color.cyan.opacity(0.92), Color.blue.opacity(0.56)]
                            : [Color.white.opacity(0.07), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 4, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    if showSocietyName {
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
                                                    colors: [Color.cyan.opacity(0.92), Color.blue.opacity(0.58)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Text(residence.flatNumber)
                                .font(.system(size: 12.75, weight: isActive ? .semibold : .regular, design: .rounded))
                                .foregroundStyle(isActive ? .primary : .secondary)
                            occupancyBadge(residence.occupancyType)
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
                                                    colors: [Color.cyan.opacity(0.92), Color.blue.opacity(0.58)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                            }
                        }
                    }

                    if showSocietyName == false {
                        Text(isActive ? "Selected for reports" : "Tap to make active")
                            .font(.system(size: 11.5, weight: .regular, design: .rounded))
                            .foregroundStyle(isActive ? Color.secondary.opacity(0.95) : Color.secondary)
                    }
                }

                Spacer()

                Text(isActive ? "Active" : "Set Active")
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(isActive ? .cyan : .secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? .white.opacity(0.10) : .white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isActive ? .cyan.opacity(0.24) : .white.opacity(0.08), lineWidth: 1)
            )
        }
        .disabled(isActive)
        .buttonStyle(.plain)
    }

    private func profileHasActiveResidence(_ residenceID: UUID) -> Bool {
        store.residentProfile?.activeResidenceID == residenceID
    }

    private func elegantSocietyRow(_ societyName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resident Society")
                .font(.system(size: 12.25, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(alignment: .center, spacing: 10) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.88),
                                Color.white.opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 3, height: 18)
                    .shadow(color: .cyan.opacity(0.14), radius: 4, x: 0, y: 1)

                Text(societyName)
                    .font(.system(size: 15.25, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .padding(.vertical, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.8))

            Text("No profile saved yet")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            Text("Save your name, flat number, and mobile number so reveal identity stays smooth later.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showEditor = true
            } label: {
                Label("Create Profile", systemImage: "plus.circle.fill")
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.14),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.overlay)
                        .mask(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                        )
                )
        )
    }
}
