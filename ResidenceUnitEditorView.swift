import SwiftUI

struct ResidenceUnitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IncParStore

    let initialResidence: ResidenceUnit?
    let defaultSocietyName: String?
    let onSave: (ResidenceUnit) -> Void

    @State private var societyName: String
    @State private var flatNumber: String
    @State private var occupancyType: ResidentOccupancyType
    @State private var showCreateSocietySheet = false

    init(
        initialResidence: ResidenceUnit? = nil,
        defaultSocietyName: String? = nil,
        onSave: @escaping (ResidenceUnit) -> Void
    ) {
        self.initialResidence = initialResidence
        self.defaultSocietyName = defaultSocietyName
        self.onSave = onSave
        _societyName = State(initialValue: initialResidence?.societyName ?? defaultSocietyName ?? "")
        _flatNumber = State(initialValue: initialResidence?.flatNumber ?? "")
        _occupancyType = State(initialValue: initialResidence?.occupancyType ?? .owner)
    }

    private var canSave: Bool {
        !societyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !flatNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    formCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Residence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .sheet(isPresented: $showCreateSocietySheet) {
                RegisterSocietyView(initialSocietyName: societyName.trimmingCharacters(in: .whitespacesAndNewlines)) { newSociety in
                    societyName = newSociety.name
                }
                .environmentObject(store)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Add another flat")
                .font(.system(size: 19, weight: .semibold, design: .rounded))
            Text("Name and mobile stay fixed in your profile. Add only the society and flat here.")
                .font(.system(size: 12.25, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel("Society Name")
            societyAutocomplete

            fieldLabel("Flat No")
            TextField("A-203 / 12B", text: $flatNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .premiumFieldStyle()

            fieldLabel("Resident Type")
            HStack(spacing: 8) {
                residentPill(.owner)
                residentPill(.tenant)
            }

            Button {
                saveResidence()
            } label: {
                HStack {
                    Spacer()
                    Label("Save Residence", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.45)
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

    private func saveResidence() {
        guard canSave else { return }
        let residence = ResidenceUnit(
            societyName: societyName.trimmingCharacters(in: .whitespacesAndNewlines),
            flatNumber: flatNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            occupancyType: occupancyType,
            isActive: false
        )
        onSave(residence)
        dismiss()
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
                            ? [Color.cyan.opacity(0.97), Color.blue.opacity(0.56)]
                            : [Color.orange.opacity(0.97), Color.yellow.opacity(0.64)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(occupancyType == type ? .cyan.opacity(0.24) : .white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var societyAutocomplete: some View {
        let query = societyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = matchingSocieties(for: query)

        return VStack(alignment: .leading, spacing: 8) {
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
                                    Text("Add it now and continue the residence setup.")
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

private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }
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
