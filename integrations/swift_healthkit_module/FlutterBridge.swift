import Foundation
import Flutter

class FlutterBridge: NSObject {
    static let shared = FlutterBridge()
    var channel: FlutterMethodChannel?

    func setup(with messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "healthkit_bridge", binaryMessenger: messenger)

        channel?.setMethodCallHandler { call, result in
            switch call.method {
            case "requestPermissions":
                HealthKitManager.shared.requestPermissions { success, error in
                    if let error = error {
                        result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
                        return
                    }
                    result(success)
                }

            case "fetchWorkouts":
                HealthKitManager.shared.fetchRecentWorkouts { workouts, error in
                    if let error = error {
                        result(FlutterError(code: "FETCH_ERROR", message: error.localizedDescription, details: nil))
                        return
                    }
                    let serialized = HealthDataSerializer.serializeWorkouts(workouts ?? [])
                    result(serialized)
                }

            case "fetchHeartRate":
                HealthKitManager.shared.fetchHeartRate { samples, error in
                    if let error = error {
                        result(FlutterError(code: "FETCH_ERROR", message: error.localizedDescription, details: nil))
                        return
                    }
                    result(samples)
                }

            case "fetchHRV":
                HealthKitManager.shared.fetchHRV { samples, error in
                    if let error = error {
                        result(FlutterError(code: "FETCH_ERROR", message: error.localizedDescription, details: nil))
                        return
                    }
                    result(samples)
                }

            case "fetchRestingHeartRate":
                HealthKitManager.shared.fetchRestingHeartRate { samples, error in
                    if let error = error {
                        result(FlutterError(code: "FETCH_ERROR", message: error.localizedDescription, details: nil))
                        return
                    }
                    result(samples)
                }

            case "fetchSleep":
                HealthKitManager.shared.fetchSleepAnalysis { samples, error in
                    if let error = error {
                        result(FlutterError(code: "FETCH_ERROR", message: error.localizedDescription, details: nil))
                        return
                    }
                    result(samples)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
