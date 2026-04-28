import Foundation
import HealthKit

final class HealthKitManager: NSObject, ObservableObject {
    private let store = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var energyQuery: HKAnchoredObjectQuery?

    @Published var currentHeartRate: Double?
    @Published var heartRateSamples: [(date: Date, bpm: Double)] = []
    @Published var activeCalories: Double = 0
    @Published var isAvailable: Bool = false
    @Published var isAuthorized: Bool = false

    private let heartRateType = HKQuantityType(.heartRate)
    private let activeEnergyType = HKQuantityType(.activeEnergyBurned)
    private let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
    private let energyUnit = HKUnit.kilocalorie()

    override init() {
        super.init()
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    var readTypes: Set<HKObjectType> {
        [heartRateType, activeEnergyType]
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run { isAuthorized = true }
            return true
        } catch {
            return false
        }
    }

    func startObserving(from startDate: Date) {
        startHeartRateQuery(from: startDate)
        startEnergyQuery(from: startDate)
    }

    func stopObserving() {
        if let q = heartRateQuery { store.stop(q) }
        if let q = energyQuery { store.stop(q) }
        heartRateQuery = nil
        energyQuery = nil
    }

    func reset() {
        stopObserving()
        DispatchQueue.main.async {
            self.currentHeartRate = nil
            self.heartRateSamples = []
            self.activeCalories = 0
        }
    }

    // MARK: - Heart Rate

    private func startHeartRateQuery(from startDate: Date) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil)
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        store.execute(query)
        heartRateQuery = query
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else { return }
        let newEntries = quantitySamples.map { sample in
            (date: sample.startDate, bpm: sample.quantity.doubleValue(for: heartRateUnit))
        }
        let latestBPM = newEntries.last?.bpm
        DispatchQueue.main.async {
            self.heartRateSamples.append(contentsOf: newEntries)
            if let bpm = latestBPM {
                self.currentHeartRate = bpm
            }
        }
    }

    // MARK: - Active Energy

    private func startEnergyQuery(from startDate: Date) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil)
        let query = HKAnchoredObjectQuery(
            type: activeEnergyType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processEnergySamples(samples)
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processEnergySamples(samples)
        }
        store.execute(query)
        energyQuery = query
    }

    private func processEnergySamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else { return }
        let total = quantitySamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: energyUnit) }
        DispatchQueue.main.async {
            self.activeCalories += total
        }
    }

    // MARK: - Summary stats

    var averageHeartRate: Double? {
        guard !heartRateSamples.isEmpty else { return nil }
        return heartRateSamples.map(\.bpm).reduce(0, +) / Double(heartRateSamples.count)
    }

    var maxHeartRate: Double? {
        heartRateSamples.map(\.bpm).max()
    }

    var minHeartRate: Double? {
        heartRateSamples.map(\.bpm).min()
    }
}
