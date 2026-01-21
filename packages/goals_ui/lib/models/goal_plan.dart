/// GoalPlan model representing a sub-plan for a UserGoal.
///
/// Each goal can have multiple plans (e.g., "Week 1-4 Base Building",
/// "Week 5-8 Speed Work") that break down the path to achieving the goal.
class GoalPlan {
  final int id;
  final int goalId;
  final String userId;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalPlan({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.name,
    this.description,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalPlan.fromJson(Map<String, dynamic> json) {
    return GoalPlan(
      id: json['id'] as int,
      goalId: json['goal_id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'name': name,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GoalPlan copyWith({
    int? id,
    int? goalId,
    String? userId,
    String? name,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalPlan(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GoalPlan(id: $id, goalId: $goalId, name: $name, status: $status)';
  }
}
