import 'package:flutter/material.dart';

class WeeklyPlanScreen extends StatelessWidget {
  final Map<String, dynamic> weeklyPlan;

  const WeeklyPlanScreen({super.key, required this.weeklyPlan});

  @override
  Widget build(BuildContext context) {
    final days = weeklyPlan['days'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Weekly Plan (${weeklyPlan["focus"]})')),
      body: days.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No weekly plan available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: _iconFor(day['type']),
                    title: Text(day['day'], style: const TextStyle(fontSize: 20)),
                    subtitle: Text(day['type'], style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
    );
  }

  Icon _iconFor(String type) {
    switch (type) {
      case "strength":
        return const Icon(Icons.fitness_center, size: 32);
      case "swim":
        return const Icon(Icons.water, size: 32);
      case "run":
        return const Icon(Icons.directions_run, size: 32);
      case "mobility":
        return const Icon(Icons.accessibility_new, size: 32);
      case "murph prep":
        return const Icon(Icons.shield, size: 32);
      case "rest":
        return const Icon(Icons.bedtime, size: 32);
      default:
        return const Icon(Icons.circle, size: 32);
    }
  }
}
