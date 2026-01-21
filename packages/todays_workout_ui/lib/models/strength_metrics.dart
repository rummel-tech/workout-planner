/// StrengthMetrics model for logging strength training sets.
///
/// Tracks individual sets with weight, reps, and optional velocity data.
/// Calculates estimated 1RM using the Epley formula.
class StrengthMetrics {
  final int? id;
  final String userId;
  final DateTime date;
  final String lift;
  final double weight;
  final int reps;
  final int setNumber;
  final double? estimated1rm;
  final double? velocityMPerS;
  final DateTime? createdAt;

  const StrengthMetrics({
    this.id,
    required this.userId,
    required this.date,
    required this.lift,
    required this.weight,
    required this.reps,
    required this.setNumber,
    this.estimated1rm,
    this.velocityMPerS,
    this.createdAt,
  });

  /// Known lift types
  static const List<String> liftTypes = [
    'squat',
    'bench_press',
    'deadlift',
    'overhead_press',
    'front_squat',
    'power_clean',
    'snatch',
    'row',
    'pull_up',
  ];

  /// Calculate estimated 1RM using Epley formula
  static double calculate1RM(double weight, int reps) {
    if (reps <= 0) return weight;
    return weight * (1 + reps / 30);
  }

  /// Get display name for a lift type
  static String liftDisplayName(String lift) {
    return lift.replaceAll('_', ' ').toUpperCase();
  }

  factory StrengthMetrics.fromJson(Map<String, dynamic> json) {
    return StrengthMetrics(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      lift: json['lift'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      setNumber: json['set_number'] as int,
      estimated1rm: (json['estimated_1rm'] as num?)?.toDouble(),
      velocityMPerS: (json['velocity_m_per_s'] as num?)?.toDouble(),
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
      'lift': lift,
      'weight': weight,
      'reps': reps,
      'set_number': setNumber,
      'estimated_1rm': estimated1rm ?? calculate1RM(weight, reps),
      if (velocityMPerS != null) 'velocity_m_per_s': velocityMPerS,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  StrengthMetrics copyWith({
    int? id,
    String? userId,
    DateTime? date,
    String? lift,
    double? weight,
    int? reps,
    int? setNumber,
    double? estimated1rm,
    double? velocityMPerS,
    DateTime? createdAt,
  }) {
    return StrengthMetrics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      lift: lift ?? this.lift,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      setNumber: setNumber ?? this.setNumber,
      estimated1rm: estimated1rm ?? this.estimated1rm,
      velocityMPerS: velocityMPerS ?? this.velocityMPerS,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Display summary for list views
  String get summary => '${liftDisplayName(lift)} - ${weight}kg x $reps (Set $setNumber)';

  /// Formatted 1RM display
  String get estimated1rmDisplay => '${(estimated1rm ?? calculate1RM(weight, reps)).toStringAsFixed(1)} kg';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StrengthMetrics && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StrengthMetrics(id: $id, lift: $lift, weight: $weight, reps: $reps)';
  }
}
