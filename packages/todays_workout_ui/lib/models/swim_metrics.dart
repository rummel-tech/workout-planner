/// SwimMetrics model for logging swimming workouts.
///
/// Tracks distance, pace, duration, and optional stroke rate.
class SwimMetrics {
  final int? id;
  final String userId;
  final DateTime date;
  final double distanceMeters;
  final int durationSeconds;
  final double avgPaceSeconds;
  final String? strokeType;
  final String waterType;
  final double? strokeRate;
  final DateTime? createdAt;

  const SwimMetrics({
    this.id,
    required this.userId,
    required this.date,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.avgPaceSeconds,
    this.strokeType,
    required this.waterType,
    this.strokeRate,
    this.createdAt,
  });

  /// Water types
  static const String waterTypePool = 'pool';
  static const String waterTypeOpenWater = 'open_water';

  /// Stroke types
  static const List<String> strokeTypes = [
    'freestyle',
    'backstroke',
    'breaststroke',
    'butterfly',
    'mixed',
  ];

  /// Calculate pace from distance and duration
  static double calculatePace(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0) return 0;
    return durationSeconds / (distanceMeters / 100);
  }

  /// Calculate total duration from distance and pace
  static int calculateDuration(double distanceMeters, double avgPaceSeconds) {
    return ((distanceMeters / 100) * avgPaceSeconds).round();
  }

  /// Format pace as M:SS / 100m
  static String formatPace(double paceSeconds) {
    final minutes = (paceSeconds / 60).floor();
    final seconds = (paceSeconds % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} / 100m';
  }

  /// Format duration as M:SS or H:MM:SS
  static String formatDuration(int totalSeconds) {
    if (totalSeconds < 3600) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory SwimMetrics.fromJson(Map<String, dynamic> json) {
    return SwimMetrics(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      durationSeconds: json['duration_seconds'] as int,
      avgPaceSeconds: (json['avg_pace_seconds'] as num).toDouble(),
      strokeType: json['stroke_type'] as String?,
      waterType: json['water_type'] as String,
      strokeRate: (json['stroke_rate'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'distance_meters': distanceMeters,
      'duration_seconds': durationSeconds,
      'avg_pace_seconds': avgPaceSeconds,
      if (strokeType != null) 'stroke_type': strokeType,
      'water_type': waterType,
      if (strokeRate != null) 'stroke_rate': strokeRate,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  SwimMetrics copyWith({
    int? id,
    String? userId,
    DateTime? date,
    double? distanceMeters,
    int? durationSeconds,
    double? avgPaceSeconds,
    String? strokeType,
    String? waterType,
    double? strokeRate,
    DateTime? createdAt,
  }) {
    return SwimMetrics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      avgPaceSeconds: avgPaceSeconds ?? this.avgPaceSeconds,
      strokeType: strokeType ?? this.strokeType,
      waterType: waterType ?? this.waterType,
      strokeRate: strokeRate ?? this.strokeRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Display summary for list views
  String get summary => '${distanceMeters.toStringAsFixed(0)}m - ${formatPace(avgPaceSeconds)}';

  /// Formatted pace display
  String get paceDisplay => formatPace(avgPaceSeconds);

  /// Formatted duration display
  String get durationDisplay => formatDuration(durationSeconds);

  /// Distance in kilometers
  double get distanceKm => distanceMeters / 1000;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwimMetrics && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SwimMetrics(id: $id, distance: ${distanceMeters}m, pace: $paceDisplay)';
  }
}
