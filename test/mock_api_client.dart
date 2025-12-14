import 'package:workout_planner/services/api_client.dart';

class MockApiClient implements ApiClient {
  @override
  Future<Map<String, dynamic>> fetchData() async {
    return {
      "readiness": {
        "readiness": 0.8,
        "hrv": 55,
        "sleep_hours": 8,
        "resting_hr": 55,
        "recovery_level": "high",
        "limiting_factor": "none"
      },
      "dailyPlan": {
        "warmup": ["10 min"],
        "main": ["Workout B"],
        "cooldown": ["light stretch"]
      },
      "weeklyPlan": {
        "focus": "strength",
        "days": [
          {"day": "Monday", "type": "strength"},
          {"day": "Tuesday", "type": "run"},
          {"day": "Wednesday", "type": "rest"},
          {"day": "Thursday", "type": "strength"},
          {"day": "Friday", "type": "swim"},
          {"day": "Saturday", "type": "long run"},
          {"day": "Sunday", "type": "rest"},
        ],
      },
    };
  }
}
