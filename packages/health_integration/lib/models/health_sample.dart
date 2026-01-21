/// HealthSample model representing a single health data point.
///
/// Supports various sample types from HealthKit/Google Fit including:
/// - hrv (Heart Rate Variability in ms)
/// - resting_hr (Resting Heart Rate in bpm)
/// - sleep_stage (Sleep duration in hours)
/// - workout_distance (Workout distance in meters)
/// - workout_calories (Calories burned in kcal)
/// - vo2max (VO2 Max in mL/kg/min)
/// - weight (Body weight in kg)
class HealthSample {
  final int? id;
  final String userId;
  final String sampleType;
  final double value;
  final String? unit;
  final DateTime startTime;
  final DateTime? endTime;
  final String? sourceApp;
  final String? sourceUuid;
  final DateTime? createdAt;

  const HealthSample({
    this.id,
    required this.userId,
    required this.sampleType,
    required this.value,
    this.unit,
    required this.startTime,
    this.endTime,
    this.sourceApp,
    this.sourceUuid,
    this.createdAt,
  });

  /// Known sample types
  static const String typeHrv = 'hrv';
  static const String typeRestingHr = 'resting_hr';
  static const String typeSleepStage = 'sleep_stage';
  static const String typeWorkoutDistance = 'workout_distance';
  static const String typeWorkoutCalories = 'workout_calories';
  static const String typeVo2max = 'vo2max';
  static const String typeWeight = 'weight';

  /// Subjective rating types (1-10 scale)
  static const String typeRpe = 'rpe';
  static const String typeSoreness = 'soreness';
  static const String typeMood = 'mood';

  /// Default units for each sample type
  static const Map<String, String> defaultUnits = {
    typeHrv: 'ms',
    typeRestingHr: 'bpm',
    typeSleepStage: 'hours',
    typeWorkoutDistance: 'meters',
    typeWorkoutCalories: 'kcal',
    typeVo2max: 'mL/kg/min',
    typeWeight: 'kg',
    typeRpe: 'rating',
    typeSoreness: 'rating',
    typeMood: 'rating',
  };

  factory HealthSample.fromJson(Map<String, dynamic> json) {
    return HealthSample(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      sampleType: json['sample_type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      sourceApp: json['source_app'] as String?,
      sourceUuid: json['source_uuid'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'sample_type': sampleType,
      'value': value,
      if (unit != null) 'unit': unit,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      if (sourceApp != null) 'source_app': sourceApp,
      if (sourceUuid != null) 'source_uuid': sourceUuid,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Create a sample for API ingestion (minimal fields required by backend)
  Map<String, dynamic> toIngestJson() {
    return {
      'user_id': userId,
      'sample_type': sampleType,
      'value': value,
      if (unit != null) 'unit': unit,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      if (sourceApp != null) 'source_app': sourceApp,
      if (sourceUuid != null) 'source_uuid': sourceUuid,
    };
  }

  HealthSample copyWith({
    int? id,
    String? userId,
    String? sampleType,
    double? value,
    String? unit,
    DateTime? startTime,
    DateTime? endTime,
    String? sourceApp,
    String? sourceUuid,
    DateTime? createdAt,
  }) {
    return HealthSample(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sampleType: sampleType ?? this.sampleType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sourceApp: sourceApp ?? this.sourceApp,
      sourceUuid: sourceUuid ?? this.sourceUuid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the effective unit (provided or default for sample type)
  String get effectiveUnit => unit ?? defaultUnits[sampleType] ?? '';

  /// Format the value with its unit for display
  String get displayValue {
    final u = effectiveUnit;
    if (sampleType == typeSleepStage) {
      final hours = value.floor();
      final minutes = ((value - hours) * 60).round();
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $u';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthSample &&
        other.id == id &&
        other.sourceUuid == sourceUuid;
  }

  @override
  int get hashCode => Object.hash(id, sourceUuid);

  @override
  String toString() {
    return 'HealthSample(id: $id, type: $sampleType, value: $value, startTime: $startTime)';
  }
}
