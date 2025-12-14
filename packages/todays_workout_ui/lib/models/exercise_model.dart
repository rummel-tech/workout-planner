class Exercise {
  String name;
  int? sets;
  int? reps;
  double? weight;
  String weightUnit;
  int? duration; // seconds
  int? rest; // seconds between sets
  double? distance;
  String distanceUnit;
  String? notes;

  Exercise({
    this.name = '',
    this.sets,
    this.reps,
    this.weight,
    this.weightUnit = 'lbs',
    this.duration,
    this.rest,
    this.distance,
    this.distanceUnit = 'miles',
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};
    if (sets != null) json['sets'] = sets;
    if (reps != null) json['reps'] = reps;
    if (weight != null) {
      json['weight'] = weight;
      json['weightUnit'] = weightUnit;
    }
    if (duration != null) json['duration'] = duration;
    if (rest != null) json['rest'] = rest;
    if (distance != null) {
      json['distance'] = distance;
      json['distanceUnit'] = distanceUnit;
    }
    if (notes != null && notes!.isNotEmpty) json['notes'] = notes;
    return json;
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String? ?? '',
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weightUnit'] as String? ?? 'lbs',
      duration: json['duration'] as int?,
      rest: json['rest'] as int?,
      distance: (json['distance'] as num?)?.toDouble(),
      distanceUnit: json['distanceUnit'] as String? ?? 'miles',
      notes: json['notes'] as String?,
    );
  }

  Exercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weight,
    String? weightUnit,
    int? duration,
    int? rest,
    double? distance,
    String? distanceUnit,
    String? notes,
  }) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      duration: duration ?? this.duration,
      rest: rest ?? this.rest,
      distance: distance ?? this.distance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      notes: notes ?? this.notes,
    );
  }

  String get summary {
    final parts = <String>[];
    if (sets != null && reps != null) {
      parts.add('$sets x $reps');
    } else if (sets != null) {
      parts.add('$sets sets');
    } else if (reps != null) {
      parts.add('$reps reps');
    }
    if (weight != null) {
      parts.add('@ ${weight!.toStringAsFixed(weight! % 1 == 0 ? 0 : 1)} $weightUnit');
    }
    if (duration != null) {
      parts.add(_formatDuration(duration!));
    }
    if (distance != null) {
      parts.add('${distance!.toStringAsFixed(distance! % 1 == 0 ? 0 : 2)} $distanceUnit');
    }
    if (rest != null) {
      parts.add('rest ${_formatDuration(rest!)}');
    }
    return parts.isEmpty ? name : parts.join(' ');
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) return '${mins}m';
    return '${mins}m ${secs}s';
  }
}
