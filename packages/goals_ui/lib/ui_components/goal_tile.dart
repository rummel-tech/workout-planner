import 'package:flutter/material.dart';
import 'goal_model.dart';

class GoalTile extends StatelessWidget {
  final UserGoal goal;

  const GoalTile({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.goalType.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (goal.targetValue != null)
              Text('Target: ${goal.targetValue}', style: const TextStyle(fontSize: 16)),
            if (goal.targetDate != null)
              Text('Deadline: ${goal.targetDate}', style: const TextStyle(fontSize: 16)),
            if (goal.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(goal.notes!, style: const TextStyle(fontSize: 14)),
              ),
            const SizedBox(height: 8),
            Text(
              goal.isActive == true ? "ACTIVE" : "COMPLETED",
              style: TextStyle(
                color: goal.isActive == true ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
