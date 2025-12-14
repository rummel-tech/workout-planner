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
                result(true)
            case "fetchWorkouts":
                result([])
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
