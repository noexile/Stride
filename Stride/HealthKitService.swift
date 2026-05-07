import HealthKit
import SwiftData

// MARK: - Protocol (enables injection in tests)

protocol HealthKitServiceProtocol: AnyObject {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func importNewRuns(into context: ModelContext) async throws -> Int
}

// MARK: - Implementation

final class HealthKitService: HealthKitServiceProtocol {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private let anchorDefaultsKey = "healthkit.runAnchor"
    private let workoutType = HKObjectType.workoutType()
    private let distanceType = HKQuantityType(.distanceWalkingRunning)

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: [workoutType, distanceType])
    }

    // Returns number of newly inserted runs.
    func importNewRuns(into context: ModelContext) async throws -> Int {
        guard isAvailable else { return 0 }

        let anchor = loadAnchor()
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let (workouts, newAnchor) = try await fetchWorkouts(predicate: predicate, anchor: anchor)

        let existingIds = Set(
            (try? context.fetch(FetchDescriptor<Run>()))?.map(\.healthKitWorkoutId) ?? []
        )

        let newRuns = workouts
            .filter { !existingIds.contains($0.uuid) }
            .map { makeRun(from: $0) }

        for run in newRuns { context.insert(run) }
        if let newAnchor { saveAnchor(newAnchor) }

        return newRuns.count
    }

    private func fetchWorkouts(
        predicate: NSPredicate,
        anchor: HKQueryAnchor?
    ) async throws -> ([HKWorkout], HKQueryAnchor?) {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: workoutType,
                predicate: predicate,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, newAnchor, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let workouts = (samples ?? []).compactMap { $0 as? HKWorkout }
                continuation.resume(returning: (workouts, newAnchor))
            }
            store.execute(query)
        }
    }

    private func makeRun(from workout: HKWorkout) -> Run {
        let meters = workout.statistics(for: distanceType)?
            .sumQuantity()?
            .doubleValue(for: .meter()) ?? 0
        return Run(
            healthKitWorkoutId: workout.uuid,
            startDate: workout.startDate,
            endDate: workout.endDate,
            distanceMiles: meters / 1609.344,
            sourceName: workout.sourceRevision.source.name
        )
    }

    private func loadAnchor() -> HKQueryAnchor? {
        guard let data = UserDefaults.standard.data(forKey: anchorDefaultsKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    private func saveAnchor(_ anchor: HKQueryAnchor) {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
        UserDefaults.standard.set(data, forKey: anchorDefaultsKey)
    }
}
