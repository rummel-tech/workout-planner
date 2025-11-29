// Simplified UserGoal model (non-freezed) for immediate build compatibility.
// To use freezed, run: flutter pub run build_runner build --delete-conflicting-outputs
// Then uncomment the freezed version below.

class UserGoal {
  final int id;
  final String goalType;
  final double? targetValue;
  final String? targetUnit;
  final String? targetDate;
  final String? notes;
  final bool? isActive;

  const UserGoal({
    required this.id,
    required this.goalType,
    this.targetValue,
    this.targetUnit,
    this.targetDate,
    this.notes,
    this.isActive,
  });

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    return UserGoal(
      id: json['id'] as int,
      goalType: json['goalType'] as String,
      targetValue: json['targetValue'] as double?,
      targetUnit: json['targetUnit'] as String?,
      targetDate: json['targetDate'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalType': goalType,
        'targetValue': targetValue,
        'targetUnit': targetUnit,
        'targetDate': targetDate,
        'notes': notes,
        'isActive': isActive,
      };
}

/* OPTIONAL: Freezed version (uncomment after running build_runner)
import 'package:freezed_annotation/freezed_annotation.dart';
part 'goal_model.freezed.dart';
part 'goal_model.g.dart';

@freezed
class UserGoal with _$UserGoal {
  const factory UserGoal({
    required int id,
    required String goalType,
    double? targetValue,
    String? targetDate,
    String? notes,
    bool? isActive,
  }) = _UserGoal;

  factory UserGoal.fromJson(Map<String, dynamic> json) => _$UserGoalFromJson(json);
}
*/
