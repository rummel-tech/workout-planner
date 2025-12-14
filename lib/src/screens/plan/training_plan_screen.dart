
import 'package:flutter/material.dart';
import '../../services/daily_plan_service.dart';
import '../../services/weekly_plan_service.dart';

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({super.key});

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  Map<String, dynamic>? daily;
  Map<String, dynamic>? weekly;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    daily = await DailyPlanService().fetchDailyPlan();
    weekly = await WeeklyPlanService().fetchWeeklyPlan();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Training Plan")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Today's Plan", style: Theme.of(context).textTheme.headlineMedium),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(daily.toString()),
          )),
          const SizedBox(height: 24),
          Text("Weekly Plan", style: Theme.of(context).textTheme.headlineMedium),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(weekly.toString()),
          )),
        ],
      ),
    );
  }
}
