import Foundation
import SwiftUI

@MainActor
final class DeparturesStore: ObservableObject {
    @Published private(set) var departures: [Departure] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false
    @Published private(set) var allStops: [Stop] = []
    @Published private(set) var atcoCode: String
    @Published private(set) var stopName: String
    /// Auto-refresh runs only for a while after the user looks at the app.
    @Published private(set) var isAwake = false

    private static let atcoKey = "atcoCode"
    private static let stopNameKey = "stopName"
    // Default: Edinburgh Royal Infirmary, RH for Children & Young People (Stop IE), south-west bound.
    private static let defaultAtco = "6200251020"
    private static let defaultName = "Royal Hospital for Children & Young People (Stop IE) SW"
    // Polling only happens while awake, which keeps load on volunteer-run bustimes.org low.
    private static let refreshInterval: TimeInterval = 30
    private static let awakeDuration: Duration = .seconds(5 * 60)

    private let service = BusService()
    private var timer: Timer?
    private var sleepTask: Task<Void, Never>?

    init() {
        atcoCode = UserDefaults.standard.string(forKey: Self.atcoKey) ?? Self.defaultAtco
        stopName = UserDefaults.standard.string(forKey: Self.stopNameKey) ?? Self.defaultName
    }

    /// Fetch now, then auto-refresh until 5 minutes after the most recent wake.
    func wake(force: Bool = false) {
        isAwake = true
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
                Task { await self?.refresh() }
            }
        }
        sleepTask?.cancel()
        sleepTask = Task { [weak self] in
            try? await Task.sleep(for: Self.awakeDuration)
            guard !Task.isCancelled else { return }
            self?.sleep()
        }
        Task { await refresh(force: force) }
    }

    private func sleep() {
        timer?.invalidate()
        timer = nil
        isAwake = false
    }

    func select(_ stop: Stop) {
        UserDefaults.standard.set(stop.atcoCode, forKey: Self.atcoKey)
        UserDefaults.standard.set(stop.displayName, forKey: Self.stopNameKey)
        atcoCode = stop.atcoCode
        stopName = stop.displayName
        departures = []
        lastUpdated = nil
        wake(force: true)
    }

    func refresh(force: Bool = false) async {
        guard force || !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let requested = atcoCode
        do {
            let result = try await service.departures(atcoCode: requested)
            guard requested == atcoCode else { return }  // stop changed mid-request
            departures = result
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadStopsIfNeeded() async throws {
        if allStops.isEmpty {
            allStops = try await service.stops()
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}
