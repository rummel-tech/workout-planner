import Foundation
import Flutter
import HealthKit

class FlutterBridge: NSObject {
    static let shared = FlutterBridge()
    var channel: FlutterMethodChannel?

    private let healthStore = HKHealthStore()

    // Default date range: last 30 days
    private var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }

    private var endDate: Date {
        Date()
    }

    // Health data types we want to read
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        // Workouts
        types.insert(HKObjectType.workoutType())

        // Heart Rate
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }

        // Heart Rate Variability (HRV)
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }

        // Resting Heart Rate
        if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHR)
        }

        // Sleep Analysis
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        // Active Energy Burned
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }

        // Distance Walking/Running
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }

        // Step Count
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }

        // VO2 Max
        if let vo2max = HKObjectType.quantityType(forIdentifier: .vo2Max) {
            types.insert(vo2max)
        }

        // Respiratory Rate
        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respiratoryRate)
        }

        // Body Mass
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }

        return types
    }

    func setup(with messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "healthkit_bridge", binaryMessenger: messenger)

        channel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "Bridge not available", details: nil))
                return
            }

            switch call.method {
            case "requestPermissions":
                self.requestPermissions(result: result)
            case "fetchWorkouts":
                self.fetchWorkouts(result: result)
            case "fetchHeartRate":
                self.fetchHeartRate(result: result)
            case "fetchHRV":
                self.fetchHRV(result: result)
            case "fetchRestingHeartRate":
                self.fetchRestingHeartRate(result: result)
            case "fetchSleep":
                self.fetchSleep(result: result)
            case "fetchSteps":
                self.fetchSteps(result: result)
            case "fetchActiveEnergy":
                self.fetchActiveEnergy(result: result)
            case "fetchDistance":
                self.fetchDistance(result: result)
            case "fetchVO2Max":
                self.fetchVO2Max(result: result)
            case "fetchBodyMass":
                self.fetchBodyMass(result: result)
            case "isHealthDataAvailable":
                result(HKHealthStore.isHealthDataAvailable())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Permission Request

    private func requestPermissions(result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(false)
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                    result(false)
                } else {
                    result(success)
                }
            }
        }
    }

    // MARK: - Fetch Workouts

    private func fetchWorkouts(result: @escaping FlutterResult) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching workouts: \(error.localizedDescription)")
                    result([])
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    result([])
                    return
                }

                let data = workouts.map { workout -> [String: Any] in
                    var dict: [String: Any] = [
                        "uuid": workout.uuid.uuidString,
                        "start": workout.startDate.timeIntervalSince1970,
                        "end": workout.endDate.timeIntervalSince1970,
                        "workoutType": workout.workoutActivityType.rawValue,
                        "workoutTypeName": self.workoutTypeName(workout.workoutActivityType),
                        "source": workout.sourceRevision.source.name
                    ]

                    // Duration
                    dict["duration"] = workout.duration

                    // Total Energy Burned
                    if let energy = workout.totalEnergyBurned {
                        dict["calories"] = energy.doubleValue(for: .kilocalorie())
                    }

                    // Total Distance
                    if let distance = workout.totalDistance {
                        dict["distance"] = distance.doubleValue(for: .meter())
                    }

                    return dict
                }

                result(data)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Fetch Heart Rate

    private func fetchHeartRate(result: @escaping FlutterResult) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            result([])
            return
        }

        fetchQuantitySamples(type: heartRateType, unit: HKUnit.count().unitDivided(by: .minute()), result: result)
    }

    // MARK: - Fetch HRV

    private func fetchHRV(result: @escaping FlutterResult) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            result([])
            return
        }

        fetchQuantitySamples(type: hrvType, unit: HKUnit.secondUnit(with: .milli), result: result)
    }

    // MARK: - Fetch Resting Heart Rate

    private func fetchRestingHeartRate(result: @escaping FlutterResult) {
        guard let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            result([])
            return
        }

        fetchQuantitySamples(type: restingHRType, unit: HKUnit.count().unitDivided(by: .minute()), result: result)
    }

    // MARK: - Fetch Sleep

    private func fetchSleep(result: @escaping FlutterResult) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            result([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching sleep: \(error.localizedDescription)")
                    result([])
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample] else {
                    result([])
                    return
                }

                let data = sleepSamples.map { sample -> [String: Any] in
                    return [
                        "uuid": sample.uuid.uuidString,
                        "start": sample.startDate.timeIntervalSince1970,
                        "end": sample.endDate.timeIntervalSince1970,
                        "value": sample.value,
                        "sleepStage": self.sleepStageName(sample.value),
                        "source": sample.sourceRevision.source.name
                    ]
                }

                result(data)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Fetch Steps

    private func fetchSteps(result: @escaping FlutterResult) {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            result([])
            return
        }

        fetchQuantitySamples(type: stepsType, unit: HKUnit.count(), result: result)
    }

    // MARK: - Fetch Active Energy

    private func fetchActiveEnergy(result: @escaping FlutterResult) {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            result([])
            return
        }

        fetchQuantitySamples(type: activeEnergyType, unit: HKUnit.kilocalorie(), result: result)
    }

    // MARK: - Fetch Distance

    private func fetchDistance(result: @escaping FlutterResult) {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            result([])
            return
        }

        fetchQuantitySamples(type: distanceType, unit: HKUnit.meter(), result: result)
    }

    // MARK: - Fetch VO2 Max

    private func fetchVO2Max(result: @escaping FlutterResult) {
        guard let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max) else {
            result([])
            return
        }

        // VO2 Max unit: mL/(kg·min)
        let unit = HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        fetchQuantitySamples(type: vo2MaxType, unit: unit, result: result)
    }

    // MARK: - Fetch Body Mass

    private func fetchBodyMass(result: @escaping FlutterResult) {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            result([])
            return
        }

        fetchQuantitySamples(type: bodyMassType, unit: HKUnit.gramUnit(with: .kilo), result: result)
    }

    // MARK: - Generic Quantity Sample Fetcher

    private func fetchQuantitySamples(type: HKQuantityType, unit: HKUnit, result: @escaping FlutterResult) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching \(type.identifier): \(error.localizedDescription)")
                    result([])
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    result([])
                    return
                }

                let data = quantitySamples.map { sample -> [String: Any] in
                    return [
                        "uuid": sample.uuid.uuidString,
                        "start": sample.startDate.timeIntervalSince1970,
                        "end": sample.endDate.timeIntervalSince1970,
                        "value": sample.quantity.doubleValue(for: unit),
                        "source": sample.sourceRevision.source.name
                    ]
                }

                result(data)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Helper Methods

    private func workoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Strength Training"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .highIntensityIntervalTraining: return "HIIT"
        case .jumpRope: return "Jump Rope"
        case .kickboxing: return "Kickboxing"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .coreTraining: return "Core Training"
        case .flexibility: return "Flexibility"
        case .cooldown: return "Cooldown"
        case .mixedCardio: return "Mixed Cardio"
        case .other: return "Other"
        default: return "Workout"
        }
    }

    private func sleepStageName(_ value: Int) -> String {
        // HKCategoryValueSleepAnalysis values
        switch value {
        case 0: return "inBed"
        case 1: return "asleepUnspecified"
        case 2: return "awake"
        case 3: return "asleepCore"
        case 4: return "asleepDeep"
        case 5: return "asleepREM"
        default: return "unknown"
        }
    }
}
