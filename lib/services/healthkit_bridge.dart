import 'package:flutter/services.dart';

class HealthKitBridge {
  static const MethodChannel _channel = MethodChannel('healthkit_bridge');

  static Future<bool> requestPermissions() async {
    final result = await _channel.invokeMethod('requestPermissions');
    return result == true;
  }

  static Future<List<dynamic>> fetchWorkouts() async {
    final result = await _channel.invokeMethod('fetchWorkouts');
    return result as List<dynamic>;
  }

  static Future<List<Map<String, dynamic>>> fetchHeartRate() async {
    final result = await _channel.invokeMethod('fetchHeartRate');
    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchHRV() async {
    final result = await _channel.invokeMethod('fetchHRV');
    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchRestingHeartRate() async {
    final result = await _channel.invokeMethod('fetchRestingHeartRate');
    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchSleep() async {
    final result = await _channel.invokeMethod('fetchSleep');
    return (result as List).cast<Map<String, dynamic>>();
  }
}
