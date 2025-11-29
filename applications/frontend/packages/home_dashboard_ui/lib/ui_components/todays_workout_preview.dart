import 'package:flutter/material.dart';
import 'package:todays_workout_ui/screens/todays_workout_screen.dart';
import '../services/daily_plan_service.dart';

class TodaysWorkoutPreview extends StatefulWidget {
  final Map<String, dynamic> plan;
  final String userId;
  final Function(Map<String, dynamic>)? onUpdate;

  const TodaysWorkoutPreview({
    super.key,
    required this.plan,
    this.userId = 'user-123',
    this.onUpdate,
  });

  @override
  State<TodaysWorkoutPreview> createState() => _TodaysWorkoutPreviewState();
}

class _TodaysWorkoutPreviewState extends State<TodaysWorkoutPreview> {
  final _dailyPlanService = DailyPlanService();

  Future<void> _onSaveWorkout(Map<String, dynamic> updatedPlan) async {
    await _dailyPlanService.saveToday(widget.userId, updatedPlan);
    if (widget.onUpdate != null) {
      widget.onUpdate!(updatedPlan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final main = widget.plan['main'] ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TodaysWorkoutScreen(
                        plan: widget.plan,
                        onSave: _onSaveWorkout,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.fitness_center, size: 16),
                  label: const Text('View Workout', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in main) Text(item.toString()),
          ],
        ),
      ),
    );
  }
}
