import SwiftUI
import UIKit

struct HomeView: View {
    @StateObject private var store: IncParStore
    @StateObject private var syncCoordinator: SyncCoordinator
    @State private var searchText = ""
    @State private var showRegisterScreen = false
    @State private var showReportScreen = false
    @State private var showSavedReportsScreen = false
    @State private var showResidentProfileScreen = false
    @State private var revealBrand = false
    @State private var selectedSocietyID: UUID?
    @State private var selectedReportSociety: Society?
    @State private var searchHintIndex = 0
    @State private var lastAutoRegisterQuery = ""
    @State private var resultsVisible = false
    @State private var petAttentionActive = false
    @State private var petAttentionLevel: CGFloat = 1.0
    @State private var petHintPulse = false
    @State private var petIntroBounce = false
    @State private var petBlinkPause = false
    @State private var petSideEyeShift = false
    @State private var petCuriousTilt = false
    @State private var previousQueryLength = 0
    @State private var attentionResetTask: Task<Void, Never>?
    @State private var blinkPauseTask: Task<Void, Never>?
    @State private var sideEyeTask: Task<Void, Never>?
    @State private var sideEyeResetTask: Task<Void, Never>?
    @State private var curiousTiltTask: Task<Void, Never>?
    @State private var syncPulse = false
    @State private var syncPulseTask: Task<Void, Never>?

    private let searchHints = [
        "Search by society, city, or state",
        "Try Palm Grove Heights",
        "Find your gated community",
    ]

    init() {
        let store = IncParStore()
        _store = StateObject(wrappedValue: store)
        _syncCoordinator = StateObject(wrappedValue: SyncCoordinator(store: store))
    }

    var filteredSocieties: [Society] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            return []
        }

        return store.societies.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query) ||
            $0.state.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    ZStack {
                        Text("Incorrect Parking")
                            .font(.system(size: 18, weight: .medium, design: .default))
                            .tracking(1.2)
                            .foregroundStyle(.secondary.opacity(revealBrand ? 0 : 1))
                            .offset(y: revealBrand ? -10 : 0)
                            .scaleEffect(revealBrand ? 0.9 : 1)
                            .blur(radius: revealBrand ? 10 : 0)

                        Text("IncPar")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .tracking(1.0)
                            .foregroundStyle(.secondary)
                            .opacity(revealBrand ? 1 : 0)
                            .scaleEffect(revealBrand ? 1 : 1.06)
                            .offset(y: revealBrand ? 0 : 12)
                            .blur(radius: revealBrand ? 0 : 7)
                    }
                    .animation(.easeInOut(duration: 2.7), value: revealBrand)

                    Text("Community Parking")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .tracking(-1.25)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("Report a parking violation.")
                        .font(.system(size: 14.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2.5)
                        .frame(maxWidth: 560)

                    LandingPetBadge(
                        sheet: AppPetLibrary.mochiPlayful,
                        isAttentive: petAttentionActive,
                        attentionLevel: petAttentionLevel,
                        hintPulse: petHintPulse,
                        introBounce: petIntroBounce,
                        blinkPause: petBlinkPause,
                        sideEyeShift: petSideEyeShift,
                        curiousTilt: petCuriousTilt
                    )
                    .frame(maxWidth: 80)
                    .opacity(revealBrand ? 1 : 0)
                    .offset(y: revealBrand ? 0 : 8)
                    .padding(.bottom, -8)
                }
                .padding(.top, 8)
                .padding(.horizontal)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.85))

                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text(searchHints[searchHintIndex])
                                .font(.system(size: 15.5, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary.opacity(0.38))
                                .transition(.opacity)
                        }

                        TextField("", text: $searchText)
                            .font(.system(size: 15.5, weight: .regular, design: .rounded))
                            .opacity(searchText.isEmpty ? 0.82 : 1)
                    }
                    .animation(.easeInOut(duration: 0.24), value: searchText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 18)

                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if filteredSocieties.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.secondary.opacity(0.8))
                                .padding(9)
                                .background(.thinMaterial, in: Circle())
                                .overlay(
                                    Circle().strokeBorder(.white.opacity(0.08), lineWidth: 1)
                                )

                            Text("No data found")
                                .font(.system(size: 15.5, weight: .semibold, design: .default))

                            Text("Don’t worry, in a few clicks you can register a new society if it is not found.")
                                .font(.system(size: 12.75, weight: .regular, design: .default))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            Button("Register New Society") {
                                showRegisterScreen = true
                            }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.18))
                        }
                        .padding(17)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 18)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .opacity(resultsVisible ? 1 : 0)
                        .offset(y: resultsVisible ? 0 : 6)
                        .blur(radius: resultsVisible ? 0 : 7)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredSocieties, id: \.id) { society in
                                    SocietyResultCard(
                                        society: society,
                                        isSelected: selectedSocietyID == society.id
                                    ) {
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                            selectedSocietyID = society.id
                                            selectedReportSociety = society
                                            showReportScreen = true
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .top)))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 2)
                            .padding(.bottom, 4)
                        }
                        .frame(maxHeight: 240)
                        .scrollIndicators(.hidden)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .opacity(resultsVisible ? 1 : 0)
                        .offset(y: resultsVisible ? 0 : 6)
                        .blur(radius: resultsVisible ? 0 : 7)
                    }
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    syncBadge
                }

                ToolbarItem(placement: .principal) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .opacity(revealBrand ? 1 : 0)
                        .scaleEffect(revealBrand ? 1 : 0.92)
                        .blur(radius: revealBrand ? 0 : 4)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(.thinMaterial, in: Capsule())
                        .overlay(
                            Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                        .animation(.easeInOut(duration: 1.8), value: revealBrand)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSavedReportsScreen = true
                    } label: {
                        Image(systemName: "tray.full")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.thinMaterial, in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Saved Reports")
                }
            }
            .onChange(of: syncCoordinator.badgeState) { _, newValue in
                syncPulseTask?.cancel()

                if newValue == .syncing {
                    syncPulse = false
                    syncPulseTask = Task {
                        while !Task.isCancelled {
                            try? await Task.sleep(for: .milliseconds(1400))
                            guard !Task.isCancelled else { return }
                            await MainActor.run {
                                syncPulse.toggle()
                            }
                        }
                    }
                } else {
                    syncPulse = false
                }
            }
            .sheet(isPresented: $showRegisterScreen) {
                RegisterSocietyView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showReportScreen, onDismiss: {
                selectedReportSociety = nil
            }) {
                if let selectedReportSociety {
                    ReportViolationView(society: selectedReportSociety)
                        .environmentObject(store)
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showSavedReportsScreen) {
                SavedReportsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showResidentProfileScreen) {
                ResidentProfileView()
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onDisappear {
                syncPulseTask?.cancel()
            }
            .task {
                revealBrand = false
                petIntroBounce = false
                try? await Task.sleep(for: .milliseconds(1500))
                withAnimation(.easeInOut(duration: 2.7)) {
                    revealBrand = true
                }
                try? await Task.sleep(for: .milliseconds(240))
                withAnimation(.easeOut(duration: 0.85)) {
                    petIntroBounce = true
                }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.easeInOut(duration: 0.8)) {
                    petIntroBounce = false
                }

                while true {
                    try? await Task.sleep(for: .milliseconds(3800))
                    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                    withAnimation(.easeInOut(duration: 1.15)) {
                        petHintPulse.toggle()
                    }
                    withAnimation(.easeInOut(duration: 1.2)) {
                        searchHintIndex = (searchHintIndex + 1) % searchHints.count
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                let query = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let queryLength = query.count
                attentionResetTask?.cancel()
                blinkPauseTask?.cancel()
                sideEyeTask?.cancel()
                sideEyeResetTask?.cancel()
                curiousTiltTask?.cancel()
                petBlinkPause = false

                if query.isEmpty {
                    previousQueryLength = 0
                    petCuriousTilt = false

                    sideEyeResetTask = Task {
                        try? await Task.sleep(for: .milliseconds(420))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                petSideEyeShift = false
                            }
                        }
                    }

                    attentionResetTask = Task {
                        try? await Task.sleep(for: .milliseconds(260))
                        guard !Task.isCancelled else { return }

                        await MainActor.run {
                            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                petAttentionActive = false
                                petAttentionLevel = 1.0
                            }
                        }
                    }

                    withAnimation(.easeInOut(duration: 0.6)) {
                        petAttentionActive = false
                        petAttentionLevel = 1.0
                    }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        resultsVisible = false
                    }
                    return
                }

                if queryLength == 1 && previousQueryLength == 0 {
                    petCuriousTilt = true
                    curiousTiltTask = Task {
                        try? await Task.sleep(for: .milliseconds(180))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            petCuriousTilt = false
                        }
                    }
                } else {
                    petCuriousTilt = false
                }

                if query.count >= 2 {
                    petAttentionActive = true
                    petAttentionLevel = min(1.28, 1.0 + CGFloat(query.count) * 0.035)
                    sideEyeTask = Task {
                        try? await Task.sleep(for: .milliseconds(260))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return }
                            petSideEyeShift = true
                        }

                        try? await Task.sleep(for: .milliseconds(180))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            petSideEyeShift = false
                        }
                    }
                    blinkPauseTask = Task {
                        try? await Task.sleep(for: .milliseconds(240))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return }
                            petBlinkPause = true
                        }

                        try? await Task.sleep(for: .milliseconds(300))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            petBlinkPause = false
                        }
                    }
                } else {
                    petAttentionActive = false
                    petAttentionLevel = 1.0
                    petSideEyeShift = false
                }

                withAnimation(.easeInOut(duration: 0.78)) {
                    resultsVisible = true
                }
                previousQueryLength = queryLength

                if filteredSocieties.isEmpty, lastAutoRegisterQuery != query {
                    lastAutoRegisterQuery = query
                    showRegisterScreen = true
                }
            }
            .animation(.easeInOut(duration: 0.78), value: resultsVisible)
            .overlay(alignment: .bottomLeading) {
                profileAccessButton
                    .padding(.leading, 14)
                    .padding(.bottom, 14)
            }
        }
    }

    private var syncBadge: some View {
        let state = syncCoordinator.badgeState
        let iconName: String
        let tint: Color
        let fill: Color

        switch state {
        case .online:
            iconName = "wifi"
            tint = .green.opacity(0.84)
            fill = .green.opacity(0.075)
        case .syncing:
            iconName = "arrow.triangle.2.circlepath"
            tint = .orange.opacity(0.82)
            fill = .orange.opacity(0.12)
        case .offline:
            iconName = "wifi.slash"
            tint = .secondary.opacity(0.82)
            fill = .white.opacity(0.035)
        }

        return Image(systemName: iconName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(fill)
                    .overlay {
                        if state == .syncing {
                            Capsule()
                                .fill(tint.opacity(syncPulse ? 0.10 : 0.055))
                                .blur(radius: 6)
                                .scaleEffect(syncPulse ? 1.05 : 1.0)
                                .opacity(syncPulse ? 0.60 : 0.40)
                        }
                    }
            )
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(
                color: state == .syncing ? tint.opacity(syncPulse ? 0.07 : 0.04) : .clear,
                radius: state == .syncing ? (syncPulse ? 5 : 3) : 0,
                y: 0
            )
            .animation(.easeInOut(duration: 1.35), value: syncPulse)
            .accessibilityLabel(syncAccessibilityLabel(for: state))
    }

    private var profileAccessButton: some View {
        let hasPhoto = store.residentProfile?.profileImageData.flatMap(UIImage.init(data:)) != nil
        let hasProfile = store.residentProfile != nil

        return Button {
            showResidentProfileScreen = true
        } label: {
            ZStack {
                if let profile = store.residentProfile, let photoData = profile.profileImageData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let initials = profileInitials {
                    Text(initials)
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.7)
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.86))
                }
            }
            .frame(width: 26, height: 26)
            .clipShape(Circle())
            .overlay {
                if hasPhoto {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.50),
                                    Color.cyan.opacity(0.48),
                                    Color.white.opacity(0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.25
                        )
                } else {
                    Circle()
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                }
            }
            .background(
                Circle()
                    .fill(hasProfile ? .thinMaterial : .ultraThinMaterial)
            )
            .shadow(color: hasPhoto ? .cyan.opacity(0.08) : .black.opacity(0.05), radius: hasPhoto ? 7 : 4, y: 2)
            .overlay {
                if hasPhoto {
                    Circle()
                        .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
                        .blur(radius: 0.6)
                        .opacity(0.58)
                }
            }
        }
        .buttonStyle(ProfileBadgeButtonStyle())
        .accessibilityLabel("Profile")
    }

    private var profileInitials: String? {
        guard let name = store.residentProfile?.name.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return nil
        }

        let pieces = name.split(separator: " ").prefix(2)
        let initials = pieces.map { String($0.prefix(1)).uppercased() }.joined()
        return initials.isEmpty ? nil : initials
    }

    private func syncAccessibilityLabel(for state: SyncCoordinator.BadgeState) -> String {
        switch state {
        case .online:
            return "Connected to internet"
        case .syncing:
            return "Syncing with master file"
        case .offline:
            return "Not connected to internet"
        }
    }
}

private struct ProfileBadgeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .offset(y: configuration.isPressed ? -0.5 : 0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.03 : 0.05), radius: configuration.isPressed ? 5 : 7, y: configuration.isPressed ? 1 : 2)
            .animation(.spring(response: 0.26, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct SocietyResultCard: View {
    let society: Society
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(isSelected ? Color.cyan.opacity(0.9) : Color.white.opacity(0.12))
                    .frame(width: 3, height: 34)

                VStack(alignment: .leading, spacing: 6) {
                    Text(society.name)
                        .font(.system(size: 15.5, weight: .semibold, design: .rounded))

                    Text("\(society.city), \(society.state)")
                        .font(.system(size: 12.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .cyan : .secondary.opacity(0.7))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 13)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.clear)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        } else {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected ? .cyan.opacity(0.22) : .white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(isSelected ? 0.14 : 0.08), radius: isSelected ? 16 : 10, y: isSelected ? 7 : 4)
                    .blur(radius: 0)
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
