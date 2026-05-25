import SwiftUI
import UIKit

struct SavedReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IncParStore
    @State private var selectedFilter: ReportFilter = .all
    @State private var selectedReport: ViolationReport?
    @State private var reportToDelete: ViolationReport?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    filterRow

                    if filteredReports.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredReports) { report in
                            SavedReportCard(report: report)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        selectedReport = report
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        reportToDelete = report
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete Report", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Saved Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .sheet(item: $selectedReport) { report in
                SavedReportDetailView(report: report)
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Delete this saved report?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Report", role: .destructive) {
                    if let reportToDelete {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.deleteViolationReport(reportToDelete.id)
                        }
                    }
                    reportToDelete = nil
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove the report from the device before it syncs.")
            }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 10) {
            ForEach(ReportFilter.allCases) { filter in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: filter.icon)
                            .font(.system(size: 11, weight: .semibold))

                        Text(filter.title)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))

                        Text("\(count(for: filter))")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(selectedFilter == filter ? .primary : .secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(selectedFilter == filter ? .white.opacity(0.10) : .white.opacity(0.05))
                    )
                    .overlay(
                        Capsule().strokeBorder(.white.opacity(selectedFilter == filter ? 0.16 : 0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.8))
                .padding(10)
                .background(.thinMaterial, in: Circle())

            Text("No saved reports yet")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            Text("Submitted violations will appear here before they sync later.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var filteredReports: [ViolationReport] {
        let reports = store.violationReports.sorted(by: { $0.createdAt > $1.createdAt })
        switch selectedFilter {
        case .all:
            return reports
        case .pending:
            return reports.filter { $0.syncStatus.lowercased() == "pending" }
        case .synced:
            return reports.filter { $0.syncStatus.lowercased() != "pending" }
        }
    }

    private func count(for filter: ReportFilter) -> Int {
        switch filter {
        case .all:
            return store.violationReports.count
        case .pending:
            return store.violationReports.filter { $0.syncStatus.lowercased() == "pending" }.count
        case .synced:
            return store.violationReports.filter { $0.syncStatus.lowercased() != "pending" }.count
        }
    }
}

private enum ReportFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case synced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .pending:
            return "Pending"
        case .synced:
            return "Synced"
        }
    }

    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .pending:
            return "clock.badge.exclamationmark"
        case .synced:
            return "checkmark.seal"
        }
    }
}

private struct SavedReportCard: View {
    let report: ViolationReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(report.societyName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    Text("\(report.societyCity), \(report.societyState)")
                        .font(.system(size: 12.75, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusPill
            }

            HStack(spacing: 10) {
                if let image = primaryImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 74, height: 74)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    detailRow(label: "Violation", value: report.violationType)
                    detailRow(label: "Area", value: report.parkingArea)
                    detailRow(label: "Active flat", value: report.reporterResidenceSummary)
                    detailRow(
                        label: "Vehicle",
                        value: {
                            let vehicle = report.vehicleNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            return vehicle.isEmpty ? "Optional / not provided" : vehicle
                        }()
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !report.comments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(report.comments)
                    .font(.system(size: 12.75, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary.opacity(0.9))
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

    private var statusPill: some View {
        Text(report.syncStatus == "pending" ? "Pending sync" : report.syncStatus.capitalized)
            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(.white.opacity(0.06))
            )
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
    }

    private var primaryImage: UIImage? {
        UIImage(data: report.primaryImageData)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(label):")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)

            Text(value)
                .font(.system(size: 12.75, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
    }
}

private struct SavedReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IncParStore
    let report: ViolationReport
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    imageSection
                    infoSection
                    commentsSection
                    statusSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.thinMaterial, in: Circle())
                            .overlay(
                                Circle().strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Delete saved report")
                }
            }
            .confirmationDialog(
                "Delete this report?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Report", role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.deleteViolationReport(report.id)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This report will be removed from the device.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(report.societyName)
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("\(report.societyCity), \(report.societyState)")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var imageSection: some View {
        Group {
            if let image = UIImage(data: report.primaryImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text("No image preview available")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
    }

    private var infoSection: some View {
        VStack(spacing: 12) {
            detailRow(icon: "exclamationmark.triangle", label: "Violation", value: report.violationType)
            detailRow(icon: "square.3.layers.3d.down.right", label: "Area", value: report.parkingArea)
            detailRow(icon: "person", label: "Identity", value: report.isAnonymous ? "Anonymous" : (report.reporterName ?? "Identity revealed"))
            detailRow(icon: "house", label: "Active flat", value: report.reporterResidenceSummary)
            detailRow(
                icon: "car",
                label: "Vehicle",
                value: {
                    let vehicle = report.vehicleNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    return vehicle.isEmpty ? "Optional / not provided" : vehicle
                }()
            )
            detailRow(icon: "calendar", label: "Saved", value: report.createdAt.formatted(date: .abbreviated, time: .shortened))
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

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comments")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(report.comments.isEmpty ? "No comments were added." : report.comments)
                .font(.system(size: 13.5, weight: .regular, design: .rounded))
                .foregroundStyle(report.comments.isEmpty ? .secondary : .primary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var statusSection: some View {
        HStack(spacing: 10) {
            Image(systemName: report.syncStatus.lowercased() == "pending" ? "clock" : "checkmark.seal.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(report.syncStatus.lowercased() == "pending" ? .orange : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(report.syncStatus.lowercased() == "pending" ? "Pending sync" : "Synced")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                Text(report.syncStatus.lowercased() == "pending" ? "Stored locally and waiting to sync." : "Already synced to the master file.")
                    .font(.system(size: 12.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
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

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
    }
}
