import SwiftUI
import PhotosUI
import UIKit

struct ReportViolationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IncParStore

    let society: Society

    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showCameraPicker = false
    @State private var vehicleNumber = ""
    @State private var selectedViolationType: ViolationType?
    @State private var selectedArea: ParkingArea?
    @State private var comments = ""
    @State private var postAnonymously = true
    @State private var showIdentityEditor = false
    @State private var showActiveResidenceConfirmation = false
    @State private var showSubmissionAlert = false
    @State private var identityShimmer = false
    @State private var activeResidenceChoiceID: UUID?

    private let maxImages = 2

    private var remainingImageSlots: Int {
        max(0, maxImages - selectedImages.count)
    }

    private var canSubmit: Bool {
        !selectedImages.isEmpty && selectedViolationType != nil && selectedArea != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    societyCard
                    imageUploadCard
                    violationTypeCard
                    parkingAreaCard
                    vehicleNumberCard
                    commentsCard
                reviewCard
            }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report Violation")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(
                    sourceType: .camera,
                    onImagePicked: { image in
                        appendImage(image)
                        showCameraPicker = false
                    },
                    onCancel: {
                        showCameraPicker = false
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showIdentityEditor) {
                ResidentProfileEditorView(
                    initialProfile: store.residentProfile,
                    defaultSocietyName: society.name
                ) { _ in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                        postAnonymously = false
                    }
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showActiveResidenceConfirmation) {
                ActiveResidenceConfirmationSheet(
                    society: society,
                    residences: profileResidencesForCurrentSociety,
                    selectedResidenceID: Binding(
                        get: { activeResidenceChoiceID ?? selectedResidenceForReport?.id },
                        set: { activeResidenceChoiceID = $0 }
                    ),
                    onEditProfile: {
                        showIdentityEditor = true
                    },
                    onConfirm: { residence in
                        submitReportLocally(using: residence)
                        showActiveResidenceConfirmation = false
                    }
                )
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: galleryItems) { _, newItems in
                Task {
                    await loadGalleryImages(from: newItems)
                }
            }
            .onChange(of: store.residentProfile?.activeResidenceID) { _, newValue in
                activeResidenceChoiceID = newValue
            }
            .onAppear {
                activeResidenceChoiceID = store.residentProfile?.activeResidenceID
            }
            .task {
                withAnimation(.linear(duration: 9.0).repeatForever(autoreverses: false)) {
                    identityShimmer = true
                }
            }
            .alert("Saved locally", isPresented: $showSubmissionAlert) {
                Button("Done", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your report has been stored on this device and is ready to sync later.")
            }
        }
    }

    private var societyCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("Selected for report")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(society.name)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("\(society.city), \(society.state)")
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("This report is saved locally first and can sync later.")
                    .font(.system(size: 12.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.9))
            }
        }
    }

    private var imageUploadCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 14) {
                headerTitle("Upload Images")
                Text("Add up to 2 photos from your gallery or camera.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    PhotosPicker(
                        selection: $galleryItems,
                        maxSelectionCount: remainingImageSlots,
                        matching: .images
                    ) {
                        actionChip(
                            title: "Gallery",
                            systemImage: "photo.on.rectangle",
                            disabled: remainingImageSlots == 0
                        )
                    }
                    .disabled(remainingImageSlots == 0)

                    Button {
                        showCameraPicker = true
                    } label: {
                        actionChip(
                            title: "Camera",
                            systemImage: "camera",
                            disabled: remainingImageSlots == 0 || !UIImagePickerController.isSourceTypeAvailable(.camera)
                        )
                    }
                    .disabled(remainingImageSlots == 0 || !UIImagePickerController.isSourceTypeAvailable(.camera))
                }

                if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Text("Camera is available on a real device.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if selectedImages.count > 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 92, height: 92)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                                        )

                                    Button {
                                        selectedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 19, weight: .semibold))
                                            .foregroundStyle(.white, .black.opacity(0.4))
                                    }
                                    .padding(6)
                                }
                            }
                        }
                    }
                }

                Text("\(selectedImages.count)/\(maxImages) images selected")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var violationTypeCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                headerTitle("Violation Type")

                Picker("Violation Type", selection: $selectedViolationType) {
                    Text("Select type").tag(nil as ViolationType?)
                    ForEach(ViolationType.allCases) { option in
                        Text(option.rawValue).tag(option as ViolationType?)
                    }
                }
                .pickerStyle(.menu)

                Text(selectedViolationType?.rawValue ?? "Choose the closest reason for the parking issue.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var parkingAreaCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                headerTitle("Area")

                Picker("Area", selection: $selectedArea) {
                    Text("Select area").tag(nil as ParkingArea?)
                    ForEach(ParkingArea.allCases) { option in
                        Text(option.rawValue).tag(option as ParkingArea?)
                    }
                }
                .pickerStyle(.menu)

                Text(selectedArea?.rawValue ?? "Choose where the violation happened.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var vehicleNumberCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                headerTitle("Vehicle Number")

                TextField("Vehicle number (optional)", text: $vehicleNumber)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.04))
                    )

                Text("Leave it blank if there is no proper HSRP plate.")
                    .font(.system(size: 12.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var commentsCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                headerTitle("Comments")

                ZStack(alignment: .topLeading) {
                    if comments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Add any extra context here...")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .padding(.top, 10)
                            .padding(.leading, 6)
                    }

                    TextEditor(text: $comments)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .frame(minHeight: 92)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, -4)
                        .padding(.top, 1)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.04))
                )
            }
        }
    }

    private var reviewCard: some View {
        let reviewSpacing = postAnonymously ? 10.0 : 14.0
        let identitySectionSpacing = postAnonymously ? 6.0 : 8.0

        return cardContainer {
                VStack(alignment: .leading, spacing: reviewSpacing) {
                    VStack(alignment: .leading, spacing: identitySectionSpacing) {
                        Text("Review")
                            .font(.system(size: 15.5, weight: .semibold, design: .rounded))

                    Text(society.name)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("\(society.city), \(society.state)")
                        .font(.system(size: 13.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Identity")
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            identityPill(
                                title: "Anonymous",
                                subtitle: "Hide my name",
                                systemImage: "eye.slash",
                                isSelected: postAnonymously
                            ) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                    postAnonymously = true
                                }
                            }

                            identityPill(
                                title: "Reveal",
                                subtitle: "Show my name",
                                systemImage: "person",
                                isSelected: !postAnonymously
                            ) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                    if store.residentProfile == nil {
                                        showIdentityEditor = true
                                    } else {
                                        postAnonymously = false
                                    }
                                }
                            }
                        }

                        Text(postAnonymously ? "Your name will stay hidden in the submitted report." : "Only your name will be revealed. Flat number, mobile number, and photo stay saved in your profile section.")
                            .font(.system(size: 11.75, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 1)

                if postAnonymously {
                    reviewRow(title: "Society", value: society.name)
                    reviewRow(title: "Images", value: "\(selectedImages.count)")
                    reviewRow(title: "Violation type", value: selectedViolationType?.rawValue ?? "Not selected")
                    reviewRow(title: "Area", value: selectedArea?.rawValue ?? "Not selected")
                    reviewRow(title: "Time stamp", value: Date.now.formatted(date: .abbreviated, time: .shortened))
                    reviewRow(title: "Identity", value: "Anonymous")
                } else {
                    reviewRow(title: "Society", value: society.name)
                    reviewRow(title: "Images", value: "\(selectedImages.count)")
                    reviewRow(title: "Violation type", value: selectedViolationType?.rawValue ?? "Not selected")
                    reviewRow(title: "Area", value: selectedArea?.rawValue ?? "Not selected")
                    reviewRow(title: "Vehicle number", value: vehicleNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Optional / not provided" : vehicleNumber)
                    identityReviewRow
                    reviewRow(title: "Active flat", value: activeResidenceReviewValue)
                    reviewRow(title: "Time stamp", value: Date.now.formatted(date: .abbreviated, time: .shortened))
                }
                if !postAnonymously {
                    reviewRow(title: "Comments", value: comments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No comments" : comments)
                }

                Button {
                    guard store.residentProfile != nil, !profileResidencesForCurrentSociety.isEmpty else {
                        showIdentityEditor = true
                        return
                    }
                    activeResidenceChoiceID = selectedResidenceForReport?.id ?? activeResidenceChoiceID
                    showActiveResidenceConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Submit Violation", systemImage: "paperplane.fill")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.45)

                Text("Saved locally. It will sync with the master file when online.")
                    .font(.system(size: 12.25, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var profileResidencesForCurrentSociety: [ResidenceUnit] {
        guard let profile = store.residentProfile else { return [] }
        let matches = profile.residences.filter {
            $0.societyName.localizedCaseInsensitiveContains(society.name) ||
            society.name.localizedCaseInsensitiveContains($0.societyName)
        }
        return matches.isEmpty ? profile.residences : matches
    }

    private var selectedResidenceForReport: ResidenceUnit? {
        let residences = profileResidencesForCurrentSociety
        let selectedID = activeResidenceChoiceID ?? store.residentProfile?.activeResidenceID
        return residences.first(where: { $0.id == selectedID }) ?? residences.first
    }

    private var activeResidenceReviewValue: String {
        guard let residence = selectedResidenceForReport else {
            return "Set up a profile to confirm the active flat"
        }

        return "\(residence.societyName) • \(residence.flatNumber) • \(residence.occupancyType.title)"
    }

    private func reviewRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)

            Text(value)
                .font(.system(size: 13.5, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
    }

    private var identityReviewRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("Identity")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)

            HStack(spacing: 8) {
                if let profile = store.residentProfile {
                    occupancyBadge(profile.occupancyType)
                }

                Text(revealedIdentityName)
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
            }
        }
    }

    private func identityPill(
        title: String,
        subtitle: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(width: 16)
                    .symbolEffect(.bounce, value: isSelected)
                    .scaleEffect(isSelected ? 1.02 : 0.98)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12.75, weight: .semibold, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 10.75, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(isSelected ? .cyan : .secondary.opacity(0.7))
                    .symbolEffect(.bounce, value: isSelected)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.26),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? .cyan.opacity(0.28) : .white.opacity(0.06), lineWidth: 1)
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.white.opacity(0.14),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: identityShimmer ? 150 : -150)
                        .rotationEffect(.degrees(8))
                        .opacity(0.08)
                        .blendMode(.screen)
                        .mask(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                }
            }
            .shadow(color: isSelected ? .cyan.opacity(0.07) : .black.opacity(0.05), radius: isSelected ? 14 : 7, y: isSelected ? 6 : 3)
        }
        .buttonStyle(.plain)
    }

    private func submitReportLocally(using residence: ResidenceUnit) {
        guard canSubmit, let violationType = selectedViolationType, let area = selectedArea else { return }

        let primaryImageData = selectedImages.first?.jpegData(compressionQuality: 0.88) ?? Data()
        let secondaryImageData = selectedImages.dropFirst().first?.jpegData(compressionQuality: 0.88)
        let trimmedVehicleNumber = vehicleNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let reporterName = postAnonymously ? nil : trimmedNonEmpty(store.residentProfile?.name)
        let report = ViolationReport(
            societyID: society.id,
            societyName: society.name,
            societyCity: society.city,
            societyState: society.state,
            vehicleNumber: trimmedVehicleNumber.isEmpty ? nil : trimmedVehicleNumber,
            reporterName: reporterName,
            reporterResidenceID: residence.id,
            reporterResidenceSocietyName: residence.societyName,
            reporterResidenceFlatNumber: residence.flatNumber,
            reporterResidenceOccupancyType: residence.occupancyType,
            violationType: violationType.rawValue,
            parkingArea: area.rawValue,
            comments: comments.trimmingCharacters(in: .whitespacesAndNewlines),
            primaryImageData: primaryImageData,
            secondaryImageData: secondaryImageData,
            isAnonymous: postAnonymously
        )

        store.addViolationReport(report)
        showSubmissionAlert = true
    }

    private func headerTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15.5, weight: .semibold, design: .rounded))
    }

    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
        )
    }

    private func actionChip(title: String, systemImage: String, disabled: Bool) -> some View {
        let fillStyle: Color = disabled ? .white.opacity(0.05) : .white.opacity(0.08)
        let textStyle: Color = disabled ? .secondary.opacity(0.6) : .primary

        return Label(title, systemImage: systemImage)
            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
            .foregroundStyle(textStyle)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fillStyle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
    }

    private func appendImage(_ image: UIImage) {
        guard selectedImages.count < maxImages else { return }
        selectedImages.append(image)
    }

    private var revealedIdentityName: String {
        trimmedNonEmpty(store.residentProfile?.name) ?? "Reveal identity"
    }

    private func trimmedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func occupancyBadge(_ occupancyType: ResidentOccupancyType) -> some View {
        HStack(spacing: 4) {
            Text(occupancyType.shortLabel)
                .font(.system(size: 10.25, weight: .semibold, design: .rounded))
            Text(occupancyType.title)
                .font(.system(size: 10.25, weight: .semibold, design: .rounded))
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
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
            .shadow(color: occupancyType == .owner ? .cyan.opacity(0.14) : .orange.opacity(0.14), radius: 6, y: 2)
    }

    private func loadGalleryImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        for item in items {
            guard selectedImages.count < maxImages else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    appendImage(image)
                }
            }
        }

        await MainActor.run {
            galleryItems = []
        }
    }
}

private enum ViolationType: String, CaseIterable, Identifiable {
    case wrongParkingAtSomeoneElsesSpace = "Wrong parking in someone else's space"
    case blockingThePathway = "Blocking the pathway"
    case blockingTheLiftArea = "Blocking the service/passenger lift area"
    case doubleParking = "Double parking"
    case parkingOnAccessRoad = "Parking on the access road"
    case blockingEmergencyAccess = "Blocking emergency access"

    var id: String { rawValue }
}

    private enum ParkingArea: String, CaseIterable, Identifiable {
        case podiumArea = "Podium Area"
        case b1 = "B1"
        case b2 = "B2"
        case b3 = "B3"
    case b4 = "B4"
    case nearClubHouse = "Near Club House"
    case inFrontOfResidentTowers = "In front of Resident Towers"

    var id: String { rawValue }
}

private struct ActiveResidenceConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let society: Society
    let residences: [ResidenceUnit]
    @Binding var selectedResidenceID: UUID?
    let onEditProfile: () -> Void
    let onConfirm: (ResidenceUnit) -> Void

    private var selectedResidence: ResidenceUnit? {
        guard !residences.isEmpty else { return nil }
        let selectedID = selectedResidenceID ?? residences.first?.id
        return residences.first(where: { $0.id == selectedID }) ?? residences.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm active flat")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))

                        Text("Make sure the flat below is the one you want to use for this report.")
                            .font(.system(size: 12.5, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    compactActiveResidenceCard

                    if residences.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No saved active flat found for this society.")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("Create or update your profile so the app can lock the correct flat before submission.")
                                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)

                            Button {
                                onEditProfile()
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Edit Profile", systemImage: "person.crop.circle.badge.plus")
                                        .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.black)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select active flat")
                                .font(.system(size: 12.25, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.8)

                            VStack(spacing: 10) {
                                ForEach(residences.sorted(by: { $0.updatedAt > $1.updatedAt })) { residence in
                                    Button {
                                        selectedResidenceID = residence.id
                                    } label: {
                                        HStack(spacing: 12) {
                                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: residence.id == selectedResidence?.id
                                                        ? [Color.cyan.opacity(0.96), Color.blue.opacity(0.56)]
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
                                                    if residence.id == selectedResidence?.id {
                                                        Text("Selected")
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

                                                HStack(spacing: 8) {
                                                    Text(residence.flatNumber)
                                                        .font(.system(size: 12.5, weight: .regular, design: .rounded))
                                                        .foregroundStyle(.secondary)
                                                    occupancyBadge(residence.occupancyType)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: residence.id == selectedResidence?.id ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(residence.id == selectedResidence?.id ? .cyan : .secondary.opacity(0.7))
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(residence.id == selectedResidence?.id ? .white.opacity(0.08) : .white.opacity(0.04))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(residence.id == selectedResidence?.id ? .cyan.opacity(0.20) : .white.opacity(0.08), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    }

                    Button {
                        if let selectedResidence {
                            onConfirm(selectedResidence)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Confirm & Submit", systemImage: "paperplane.fill")
                                .font(.system(size: 14.75, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .disabled(selectedResidence == nil)
                    .opacity(selectedResidence == nil ? 0.45 : 1)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Active Flat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", role: .cancel) {
                        dismiss()
                    }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    private var compactActiveResidenceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active flat")
                .font(.system(size: 12.25, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.96), Color.blue.opacity(0.56)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 4, height: 44)
                    .shadow(color: .cyan.opacity(0.12), radius: 7, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Selected from profile")
                            .font(.system(size: 11.25, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        Spacer(minLength: 0)
                    }

                    if let residence = selectedResidence {
                        Text(society.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text(residence.flatNumber)
                                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                            occupancyBadge(residence.occupancyType)
                            Text("Active")
                                .font(.system(size: 10.75, weight: .semibold, design: .rounded))
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
                    } else {
                        Text("Select a flat from your profile")
                            .font(.system(size: 12.5, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: .cyan.opacity(selectedResidence == nil ? 0.03 : 0.08), radius: selectedResidence == nil ? 8 : 16, x: 0, y: 6)
        }
    }

    private func occupancyBadge(_ occupancyType: ResidentOccupancyType) -> some View {
        HStack(spacing: 4) {
            Text(occupancyType.shortLabel)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text(occupancyType.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 4)
        .padding(.horizontal, 7)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: occupancyType == .owner
                        ? [Color.cyan.opacity(0.97), Color.blue.opacity(0.56)]
                        : [Color.orange.opacity(0.97), Color.yellow.opacity(0.64)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}
