import 'dart:async';
import 'package:flutter/material.dart';
import '../ui_components/readiness_card.dart';
import '../ui_components/todays_workout_preview.dart';
import '../ui_components/weekly_plan_preview.dart';
import 'package:todays_workout_ui/screens/strength_metrics_screen.dart';
import 'package:todays_workout_ui/screens/swim_metrics_screen.dart';
import 'package:goals_ui/screens/goals_screen.dart';
import 'package:goals_ui/screens/goal_plans_screen.dart';
import 'package:goals_ui/ui_components/goal_model.dart';
import 'package:goals_ui/services/goals_api_service.dart';
import 'package:settings_profile_ui/screens/profile_screen.dart';
import 'package:readiness_ui/screens/health_metrics_screen.dart';
import 'package:ai_coach_chat/ai_coach_chat.dart';
import '../services/auth_service.dart';
import '../services/health_service.dart';
import '../services/readiness_service.dart';
import '../services/health_sync.dart';
import '../services/weekly_plan_service.dart';
import '../services/daily_plan_service.dart';

// Clean, single HomeScreen implementation — final version
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> readiness;
  final Map<String, dynamic> dailyPlan;
  final Map<String, dynamic> weeklyPlan;
  final bool testMode;
  final dynamic themeController;

  const HomeScreen({
    super.key,
    required this.readiness,
    required this.dailyPlan,
    required this.weeklyPlan,
    this.testMode = false,
    this.themeController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = GoalsApiService();
  final _healthService = HealthService();
  final _readinessService = ReadinessService();
  final _weeklyPlanService = WeeklyPlanService();
  final _dailyPlanService = DailyPlanService();
  List<UserGoal> _goals = [];
    bool _readinessLoading = true;
    String? _readinessError;
    double _readinessScore = 0.0;
    double _hrv = 0.0;
    double _sleepHours = 0.0;
    int _restingHr = 0;
  bool _goalsLoading = true;
  bool _healthLoading = true;
  String? _healthError;
  int _workoutsCount = 0;
  double _totalDistanceKm = 0;
  double _totalCalories = 0;
  bool _syncing = false;
  String? _syncError;
  Timer? _syncTimer;
  late Map<String, dynamic> _weeklyPlan;
  late Map<String, dynamic> _dailyPlan;

  @override
  void initState() {
    super.initState();
    _weeklyPlan = Map<String, dynamic>.from(widget.weeklyPlan);
    _dailyPlan = Map<String, dynamic>.from(widget.dailyPlan);

    // Skip network calls in test mode
    if (!widget.testMode) {
      _loadSavedWeeklyPlan();
      _loadSavedDailyPlan();
      _loadGoals();
      _loadHealth();
      _loadReadiness();
      // Auto-sync on startup
      Future.delayed(const Duration(seconds: 2), _performSync);
      // Periodic sync every 15 minutes
      _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _performSync());
    } else {
      // In test mode, set loading to false immediately
      _goalsLoading = false;
      _healthLoading = false;
      _readinessLoading = false;
    }
  }

  Future<void> _loadSavedWeeklyPlan() async {
    final saved = await _weeklyPlanService.load('user-123');
    if (saved != null && mounted) {
      setState(() => _weeklyPlan = saved);
    }
  }

  Future<void> _loadSavedDailyPlan() async {
    final saved = await _dailyPlanService.loadToday('user-123');
    if (saved != null && mounted) {
      setState(() => _dailyPlan = saved);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReadiness() async {
    setState(() {
      _readinessLoading = true;
      _readinessError = null;
    });
    try {
      final data = await _readinessService.fetch('user-123');
      double _asDouble(dynamic v, double fallback) => v is num ? v.toDouble() : fallback;
      int _asInt(dynamic v, int fallback) => v is num ? v.round() : fallback;
      setState(() {
        _readinessScore = _asDouble(data['readiness'], 0.0);
        _hrv = _asDouble(data['hrv'], 0.0);
        _sleepHours = _asDouble(data['sleep_hours'], 0.0);
        _restingHr = _asInt(data['resting_hr'], 0);
        _readinessLoading = false;
      });
    } catch (e) {
      setState(() {
        _readinessError = '$e';
        _readinessLoading = false;
      });
    }
  }

  Future<void> _loadGoals() async {
    try {
      final goalsData = await _apiService.getGoals('user-123');
      if (mounted) {
        setState(() {
          _goals = goalsData.map((data) => UserGoal(
            id: data['id'],
            goalType: data['goal_type'],
            targetValue: data['target_value']?.toDouble(),
            targetUnit: data['target_unit'],
            targetDate: data['target_date'],
            notes: data['notes'],
            isActive: data['is_active'] == 1 || data['is_active'] == true,
          )).toList();
          _goalsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _goalsLoading = false;
        });
      }
    }
  }

  Future<void> _loadHealth() async {
    setState(() {
      _healthLoading = true;
      _healthError = null;
    });
    try {
      // Fetch distance and calories samples
      final distanceSamples = await _healthService.listSamples('user-123', 'workout_distance', limit: 1000);
      final calorieSamples = await _healthService.listSamples('user-123', 'workout_calories', limit: 1000);
      _workoutsCount = distanceSamples.length; // approximation
      _totalDistanceKm = distanceSamples.fold<double>(0, (sum, s) => sum + ((s['value'] ?? 0) as num).toDouble()) / 1000.0;
      _totalCalories = calorieSamples.fold<double>(0, (sum, s) => sum + ((s['value'] ?? 0) as num).toDouble());
      setState(() {
        _healthLoading = false;
      });
    } catch (e) {
      setState(() {
        _healthLoading = false;
        _healthError = '$e';
      });
    }
  }

  Future<void> _performSync() async {
    if (_syncing) return; // Prevent concurrent syncs
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    final sync = HealthSync(userId: 'user-123');
    final res = await sync.perform();
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced ${res.inserted}/${res.total} samples')),
      );
      await _loadHealth();
      await _loadReadiness();
    } else {
      final joined = res.errors.join('; ');
      setState(() { _syncError = joined; });
      final permissionOnly = res.errors.isNotEmpty && res.errors.every((e) => e.toLowerCase().contains('permission'));
      if (permissionOnly) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health data unavailable (permissions).')), // softer info message
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync errors: $joined')),
        );
      }
    }
    setState(() {
      _syncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout-Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'AI Coach',
            onPressed: () {
              // Navigate to chat screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(userId: 'user-123'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Logout and return to login screen
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            child: ListTile(
              leading: const CircleAvatar(child: Text('SR')),
              title: const Text('Shawn Rummel'),
              subtitle: const Text('shawn@example.com'),
              trailing: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      themeController: widget.themeController,
                      healthError: _healthError,
                      syncError: _syncError,
                    ),
                  ),
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    themeController: widget.themeController,
                    healthError: _healthError,
                    syncError: _syncError,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 12),

          

          // Next Workouts Preview
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final upcomingWorkouts = _getUpcomingWorkouts();

              final nextWorkout = upcomingWorkouts.isNotEmpty
                  ? _buildWorkoutCard(
                      'Next Workout',
                      upcomingWorkouts[0]['day'] ?? 'Unknown',
                      upcomingWorkouts[0]['workouts'] as List<Map<String, dynamic>>? ?? [],
                      isPrimary: true,
                    )
                  : _buildWorkoutCard('Next Workout', 'No workouts', [], isPrimary: true);

              final followingWorkout = upcomingWorkouts.length > 1
                  ? _buildWorkoutCard(
                      'Following Workout',
                      upcomingWorkouts[1]['day'] ?? 'Unknown',
                      upcomingWorkouts[1]['workouts'] as List<Map<String, dynamic>>? ?? [],
                      isPrimary: false,
                    )
                  : _buildWorkoutCard('Following Workout', 'No workout', [], isPrimary: false);

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    nextWorkout,
                    const SizedBox(height: 12),
                    followingWorkout,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nextWorkout),
                  const SizedBox(width: 12),
                  Expanded(child: followingWorkout),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          WeeklyPlanPreview(
            weeklyPlan: _weeklyPlan,
            onUpdated: (updated) async {
              setState(() => _weeklyPlan = updated);
              try {
                await _weeklyPlanService.save('user-123', updated);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Weekly plan saved')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save weekly plan: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                              _loadGoals();
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Goal', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                              _loadGoals();
                            },
                            icon: const Icon(Icons.flag, size: 16),
                            label: const Text('View All', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_goalsLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_goals.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('No goals yet', style: TextStyle(color: Colors.grey)),
                            TextButton(
                              onPressed: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                                _loadGoals();
                              },
                              child: const Text('Create your first goal'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    for (final g in _goals.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(g.goalType),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (g.targetValue != null) Text('Target: ${g.targetValue}${g.targetUnit != null ? ' ${g.targetUnit}' : ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            if (g.notes != null && g.notes!.isNotEmpty) Text(g.notes!, style: const TextStyle(fontSize: 12)),
                            if (g.targetDate != null) Text('By: ${g.targetDate}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'history') showModalBottomSheet(context: context, builder: (_) => const Padding(padding: EdgeInsets.all(16), child: Text('History Placeholder')));
                            if (val == 'plans') {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => GoalPlansScreen(goal: g)));
                              _loadGoals();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'plans', child: Text('View Plans')),
                            const PopupMenuItem(value: 'history', child: Text('View History')),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthMetricsScreen(userId: 'user-123'))),
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Health'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StrengthMetricsScreen(userId: 'user-123'))),
                        icon: const Icon(Icons.fitness_center, size: 18),
                        label: const Text('Strength'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SwimMetricsScreen(userId: 'user-123'))),
                        icon: const Icon(Icons.pool, size: 18),
                        label: const Text('Swim'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  List<Map<String, dynamic>> _getUpcomingWorkouts() {
    final days = _weeklyPlan['days'] as List<dynamic>? ?? [];
    if (days.isEmpty) return [];

    // Get current day of week (1 = Monday, 7 = Sunday)
    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1; // 0 = Monday, 6 = Sunday

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    List<Map<String, dynamic>> upcoming = [];

    // Start from current day and look forward
    for (int i = 0; i < 7; i++) {
      final checkIndex = (currentDayIndex + i) % 7;
      final dayName = dayNames[checkIndex];

      final dayData = days.firstWhere(
        (d) => (d['day'] as String).toLowerCase() == dayName.toLowerCase(),
        orElse: () => {},
      ) as Map<String, dynamic>;

      if (dayData.isNotEmpty) {
        // Extract workouts
        List<Map<String, dynamic>> workouts = [];
        if (dayData.containsKey('workouts') && dayData['workouts'] is List) {
          workouts = (dayData['workouts'] as List)
              .map((w) => w as Map<String, dynamic>)
              .toList();
        } else if (dayData.containsKey('type')) {
          workouts = [{'type': dayData['type']}];
        }

        if (workouts.isNotEmpty) {
          upcoming.add({
            'day': dayName,
            'workouts': workouts,
          });
        }

        if (upcoming.length >= 2) break;
      }
    }

    return upcoming;
  }

  Widget _buildWorkoutCard(String title, String dayName, List<Map<String, dynamic>> workouts, {required bool isPrimary}) {
    return Card(
      elevation: isPrimary ? 3 : 2,
      color: isPrimary ? Colors.blue.withOpacity(0.03) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPrimary ? Icons.fitness_center : Icons.schedule,
                  size: 20,
                  color: isPrimary ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.blue[800] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (workouts.isEmpty)
              const Text(
                'Rest day',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              )
            else
              ...workouts.map((workout) {
                final type = workout['type'] as String? ?? 'Unknown';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _iconForWorkout(type, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Icon _iconForWorkout(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case "strength":
        return Icon(Icons.fitness_center, size: size, color: Colors.orange);
      case "swim":
        return Icon(Icons.pool, size: size, color: Colors.blue);
      case "run":
        return Icon(Icons.directions_run, size: size, color: Colors.green);
      case "mobility":
        return Icon(Icons.accessibility_new, size: size, color: Colors.purple);
      case "murph":
      case "murph prep":
        return Icon(Icons.shield, size: size, color: Colors.red);
      case "rest":
        return Icon(Icons.bedtime, size: size, color: Colors.grey);
      case "bike":
      case "cycling":
        return Icon(Icons.directions_bike, size: size, color: Colors.teal);
      case "yoga":
        return Icon(Icons.self_improvement, size: size, color: Colors.indigo);
      case "cardio":
        return Icon(Icons.favorite, size: size, color: Colors.pink);
      default:
        return Icon(Icons.fitness_center, size: size, color: Colors.grey);
    }
  }
}
