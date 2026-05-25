import Foundation
import Network
import Combine

@MainActor
final class SyncCoordinator: ObservableObject {
    enum BadgeState: Equatable {
        case offline
        case syncing
        case online
    }

    @Published private(set) var badgeState: BadgeState = .offline

    private let store: IncParStore
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "IncPar.NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    private var syncTask: Task<Void, Never>?
    private var isConnected = false

    init(store: IncParStore) {
        self.store = store

        pathMonitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            DispatchQueue.main.async { [weak self] in
                self?.handleConnectivityChange(isConnected: isConnected)
            }
        }
        pathMonitor.start(queue: monitorQueue)

        store.$violationReports
            .sink { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.refresh()
                }
            }
            .store(in: &cancellables)

        refresh()
    }

    deinit {
        pathMonitor.cancel()
        syncTask?.cancel()
    }

    func refresh() {
        let hasPendingReports = store.violationReports.contains { $0.syncStatus.lowercased() == "pending" }

        guard isConnected else {
            cancelSync()
            badgeState = .offline
            return
        }

        if hasPendingReports {
            startSyncIfNeeded()
        } else {
            cancelSync()
            badgeState = .online
        }
    }

    private func handleConnectivityChange(isConnected: Bool) {
        self.isConnected = isConnected
        refresh()
    }

    private func startSyncIfNeeded() {
        guard syncTask == nil else {
            badgeState = .syncing
            return
        }

        badgeState = .syncing
        syncTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(1600))
            guard !Task.isCancelled else { return }
            guard let self else { return }
            self.store.markPendingViolationReportsSynced()
            self.syncTask = nil
            self.badgeState = self.isConnected ? .online : .offline
        }
    }

    private func cancelSync() {
        syncTask?.cancel()
        syncTask = nil
    }
}
