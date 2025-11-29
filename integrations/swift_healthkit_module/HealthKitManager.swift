import HealthKit

final class HealthKitManager {

    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    func requestPermissions(completion: @escaping (Bool, Error?) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            completion(success, error)
        }
    }

    func fetchRecentWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let workoutType = HKObjectType.workoutType()

        let lastFetch = UserDefaults.standard.object(forKey: "lastWorkoutFetch") as? Date ?? .distantPast

        let predicate = HKQuery.predicateForSamples(
            withStart: lastFetch,
            end: Date(),
            options: .strictEndDate
        )

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error = error {
                completion(nil, error)
                return
            }
            if let workouts = samples as? [HKWorkout] {
                UserDefaults.standard.set(Date(), forKey: "lastWorkoutFetch")
                completion(workouts, nil)
            } else {
                completion([], nil)
            }
        }

        healthStore.execute(query)
    }

    private func lastFetchDate(key: String) -> Date {
        return UserDefaults.standard.object(forKey: key) as? Date ?? .distantPast
    }

    private func updateLastFetchDate(key: String) {
        UserDefaults.standard.set(Date(), forKey: key)
    }

    func fetchQuantitySamples(identifier: HKQuantityTypeIdentifier, unit: HKUnit, key: String, completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid quantity type identifier."]))
            return
        }
        let since = lastFetchDate(key: key)
        let predicate = HKQuery.predicateForSamples(withStart: since, end: Date(), options: .strictEndDate)
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            guard let self = self else { return }
            if let error = error {
                completion(nil, error)
                return
            }
            let results = samples as? [HKQuantitySample] ?? []
            if !results.isEmpty { self.updateLastFetchDate(key: key) }
            completion(results, nil)
        }
        healthStore.execute(query)
    }

    func fetchHeartRate(completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        fetchQuantitySamples(identifier: .heartRate, unit: unit, key: "lastHeartRateFetch") { samples, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(HealthDataSerializer.serializeQuantitySamples(samples ?? [], unit: unit, type: "heart_rate"), nil)
        }
    }

    func fetchHRV(completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        let unit = HKUnit.secondUnit(with: .milli)
        fetchQuantitySamples(identifier: .heartRateVariabilitySDNN, unit: unit, key: "lastHRVFetch") { samples, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(HealthDataSerializer.serializeQuantitySamples(samples ?? [], unit: unit, type: "hrv"), nil)
        }
    }

    func fetchRestingHeartRate(completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        fetchQuantitySamples(identifier: .restingHeartRate, unit: unit, key: "lastRestingHRFetch") { samples, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(HealthDataSerializer.serializeQuantitySamples(samples ?? [], unit: unit, type: "resting_hr"), nil)
        }
    }

    func fetchSleepAnalysis(completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid sleep analysis type identifier."]))
            return
        }
        let since = lastFetchDate(key: "lastSleepFetch")
        let predicate = HKQuery.predicateForSamples(withStart: since, end: Date(), options: .strictEndDate)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            guard let self = self else { return }
            if let error = error {
                completion(nil, error)
                return
            }
            let results = samples as? [HKCategorySample] ?? []
            if !results.isEmpty { self.updateLastFetchDate(key: "lastSleepFetch") }
            completion(HealthDataSerializer.serializeSleepSamples(results), nil)
        }
        healthStore.execute(query)
    }
}
