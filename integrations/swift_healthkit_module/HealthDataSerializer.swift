import HealthKit

struct HealthDataSerializer {

    static func serializeWorkouts(_ workouts: [HKWorkout]) -> [[String: Any]] {
        return workouts.map { workout in
            return [
                "uuid": workout.uuid.uuidString,
                "type": workout.workoutActivityType.rawValue,
                "start": workout.startDate.timeIntervalSince1970,
                "end": workout.endDate.timeIntervalSince1970,
                "calories": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                "distance": workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                "metadata": workout.metadata ?? [:]
            ]
        }
    }

    static func serializeQuantitySamples(_ samples: [HKQuantitySample], unit: HKUnit, type: String) -> [[String: Any]] {
        return samples.map { sample in
            return [
                "uuid": sample.uuid.uuidString,
                "sample_type": type,
                "start": sample.startDate.timeIntervalSince1970,
                "end": sample.endDate.timeIntervalSince1970,
                "value": sample.quantity.doubleValue(for: unit),
                "unit": unit.description,
                "source": sample.sourceRevision.source.name
            ]
        }
    }

    static func serializeSleepSamples(_ samples: [HKCategorySample]) -> [[String: Any]] {
        return samples.map { sample in
            return [
                "uuid": sample.uuid.uuidString,
                "sample_type": "sleep",
                "start": sample.startDate.timeIntervalSince1970,
                "end": sample.endDate.timeIntervalSince1970,
                "value": sample.value, // 0=InBed,1=Asleep (Apple docs)
                "source": sample.sourceRevision.source.name
            ]
        }
    }
}
