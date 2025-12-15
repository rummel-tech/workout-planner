import 'package:flutter/material.dart';
import '../screens/weekly_plan_edit_screen.dart';
import '../screens/day_edit_screen.dart';
import '../services/weekly_plan_service.dart';
import '../services/auth_service.dart';

class WeeklyPlanPreview extends StatefulWidget {
  final Map<String, dynamic> weeklyPlan;
  final ValueChanged<Map<String, dynamic>>? onUpdated;
  final String userId;
  final AuthService authService;

  const WeeklyPlanPreview({
    super.key,
    required this.weeklyPlan,
    required this.authService,
    this.onUpdated,
    this.userId = 'user-123',
  });

  @override
  State<WeeklyPlanPreview> createState() => _WeeklyPlanPreviewState();
}

class _WeeklyPlanPreviewState extends State<WeeklyPlanPreview> {
  static const List<String> _workoutTypes = [
    'Strength',
    'Run',
    'Swim',
    'Murph',
    'Bike',
    'Yoga',
    'Cardio',
    'Mobility',
    'Rest',
  ];

  final WeeklyPlanService _service = WeeklyPlanService();
  late Map<String, dynamic> _currentPlan;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentPlan = Map<String, dynamic>.from(widget.weeklyPlan);
  }

  @override
  void didUpdateWidget(WeeklyPlanPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weeklyPlan != oldWidget.weeklyPlan) {
      setState(() {
        _currentPlan = Map<String, dynamic>.from(widget.weeklyPlan);
      });
    }
  }

  Future<void> _addWorkoutToDay(String dayName) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _WorkoutPickerDialog(workoutTypes: _workoutTypes),
    );

    if (selected != null && mounted) {
      // Create a deep copy of the plan to ensure proper state updates
      final newPlan = Map<String, dynamic>.from(_currentPlan);
      final days = List<dynamic>.from(newPlan['days'] as List<dynamic>);

      final dayIndex = days.indexWhere(
        (d) => (d['day'] as String).toLowerCase() == dayName.toLowerCase(),
      );

      if (dayIndex != -1) {
        // Create a new map for the day to ensure state update is detected
        final oldDay = days[dayIndex] as Map<String, dynamic>;
        final day = Map<String, dynamic>.from(oldDay);

        // Get current workouts
        List<Map<String, dynamic>> workouts = [];
        if (day.containsKey('workouts') && day['workouts'] is List) {
          workouts = List<Map<String, dynamic>>.from(
            (day['workouts'] as List).map((w) => Map<String, dynamic>.from(w as Map))
          );
        } else if (day.containsKey('type')) {
          // Convert old format - only if it's not 'rest'
          final existingType = day['type'] as String;
          if (existingType.toLowerCase() != 'rest') {
            workouts = [{'type': existingType}];
          }
        }

        // Add new workout if less than 3
        if (workouts.length < 3) {
          workouts.add({'type': selected});
          day['workouts'] = workouts;
          day.remove('type'); // Remove old format field

          // Update the days list with the modified day
          days[dayIndex] = day;
          newPlan['days'] = days;

          setState(() {
            _currentPlan = newPlan;
          });

          // Save the updated plan
          await _savePlan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 3 workouts per day')),
          );
        }
      }
    }
  }

  Future<void> _savePlan() async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      await _service.save(widget.userId, _currentPlan);
      if (mounted && widget.onUpdated != null) {
        widget.onUpdated!(_currentPlan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _currentPlan['days'] as List<dynamic>? ?? [];
    final focus = _currentPlan['focus'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'This Week',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeeklyPlanEditScreen(
                          initialPlan: _currentPlan,
                          userId: widget.userId,
                          authService: widget.authService,
                        ),
                      ),
                    );
                    if (updated != null && mounted) {
                      setState(() {
                        _currentPlan = updated;
                      });
                      if (widget.onUpdated != null) widget.onUpdated!(updated);
                    }
                  },
                  icon: const Icon(Icons.calendar_view_week, size: 18),
                  label: const Text('View Week'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (days.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No weekly plan available', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final day in days)
                      _buildDayChip(context, day as Map<String, dynamic>),
                  ],
                ),
              ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }

  // Icon for workout type
  Icon _iconFor(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case "strength":
        return Icon(Icons.fitness_center, size: size, color: Colors.orange);
      case "swim":
        return Icon(Icons.pool, size: size, color: Colors.blue);
      case "run":
        return Icon(Icons.directions_run, size: size, color: Colors.green);
      case "mobility":
        return Icon(Icons.accessibility_new, size: size, color: Colors.purple);
      case "murph prep":
      case "murph":
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

  // Base color for chip border/background accent
  Color _chipColor(String type) {
    switch (type.toLowerCase()) {
      case "strength":
        return Colors.orange;
      case "swim":
        return Colors.blue;
      case "run":
        return Colors.green;
      case "mobility":
        return Colors.purple;
      case "murph prep":
        return Colors.red;
      case "rest":
        return Colors.grey;
      case "bike":
      case "cycling":
        return Colors.teal;
      case "yoga":
        return Colors.indigo;
      case "cardio":
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // Abbreviate day (e.g., Monday -> Mon)
  String _abbrev(String day) {
    if (day.length <= 3) return day;
    return day.substring(0, 3);
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    const names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    final todayName = names[now.weekday - 1];
    return day.toLowerCase().startsWith(todayName.toLowerCase().substring(0, 3));
  }

  Widget _buildDayChip(BuildContext context, Map<String, dynamic> day) {
    final name = day['day'] as String? ?? '';
    final isToday = _isToday(name);

    // Support both old format (type field) and new format (workouts array)
    List<Map<String, dynamic>> workouts = [];
    if (day.containsKey('workouts') && day['workouts'] is List) {
      // Safely convert each workout to Map<String, dynamic>
      for (final w in day['workouts'] as List) {
        if (w is Map) {
          workouts.add(Map<String, dynamic>.from(w));
        }
      }
    } else if (day.containsKey('type') && day['type'] is String) {
      // Legacy format - convert to workout list
      workouts = [{'type': day['type'] as String}];
    }

    // If no workouts, show rest day
    if (workouts.isEmpty) {
      workouts = [{'type': 'Rest'}];
    }

    final canAddMore = workouts.length < 3;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
        decoration: BoxDecoration(
          color: isToday ? Colors.blue.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
          border: Border.all(
            color: isToday ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () => _showDayDetails(context, name, day),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _abbrev(name),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.blue[800] : Colors.black87,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...workouts.take(3).map((workout) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconFor(workout['type'] as String? ?? 'Rest', size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              workout['type'] as String? ?? 'Rest',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            if (canAddMore)
              Tooltip(
                message: 'Add workout (max 3 per day)',
                child: InkWell(
                  onTap: () => _addWorkoutToDay(name),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Tooltip(
                message: 'Max 3 workouts per day',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Max reached',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDayDetails(BuildContext context, String dayName, Map<String, dynamic> dayData) async {
    // Ensure dayData has proper workout structure
    final normalizedDayData = Map<String, dynamic>.from(dayData);

    // Ensure workouts array exists and has at least one workout
    if (!normalizedDayData.containsKey('workouts') ||
        normalizedDayData['workouts'] is! List ||
        (normalizedDayData['workouts'] as List).isEmpty) {
      // Check for legacy 'type' field
      if (normalizedDayData.containsKey('type') && normalizedDayData['type'] != null) {
        normalizedDayData['workouts'] = [
          {
            'type': normalizedDayData['type'],
            'name': normalizedDayData['type'],
            'warmup': <Map<String, dynamic>>[],
            'main': <Map<String, dynamic>>[],
            'cooldown': <Map<String, dynamic>>[],
            'notes': '',
            'status': 'pending',
          }
        ];
      } else {
        // Default to Rest workout
        normalizedDayData['workouts'] = [
          {
            'type': 'Rest',
            'name': 'Rest',
            'warmup': <Map<String, dynamic>>[],
            'main': <Map<String, dynamic>>[],
            'cooldown': <Map<String, dynamic>>[],
            'notes': '',
            'status': 'pending',
          }
        ];
      }
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => DayEditScreen(
          dayName: dayName,
          dayData: normalizedDayData,
          userId: widget.userId,
          authService: widget.authService,
        ),
      ),
    );

    if (result != null && mounted) {
      // Update the day in the plan
      final newPlan = Map<String, dynamic>.from(_currentPlan);
      final days = List<dynamic>.from(newPlan['days'] as List<dynamic>);

      final dayIndex = days.indexWhere(
        (d) => (d['day'] as String).toLowerCase() == dayName.toLowerCase(),
      );

      if (dayIndex != -1) {
        days[dayIndex] = result;
        newPlan['days'] = days;

        setState(() {
          _currentPlan = newPlan;
        });

        // Save the updated plan
        await _savePlan();
      }
    }
  }

}

class _WorkoutPickerDialog extends StatelessWidget {
  final List<String> workoutTypes;

  const _WorkoutPickerDialog({required this.workoutTypes});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Workout Type'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: workoutTypes.length,
          itemBuilder: (context, index) {
            final type = workoutTypes[index];
            return ListTile(
              leading: _iconFor(type),
              title: Text(type),
              onTap: () => Navigator.pop(context, type),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Icon _iconFor(String type) {
    switch (type.toLowerCase()) {
      case "strength":
        return const Icon(Icons.fitness_center, color: Colors.orange);
      case "swim":
        return const Icon(Icons.pool, color: Colors.blue);
      case "run":
        return const Icon(Icons.directions_run, color: Colors.green);
      case "mobility":
        return const Icon(Icons.accessibility_new, color: Colors.purple);
      case "murph":
        return const Icon(Icons.shield, color: Colors.red);
      case "rest":
        return const Icon(Icons.bedtime, color: Colors.grey);
      case "bike":
      case "cycling":
        return const Icon(Icons.directions_bike, color: Colors.teal);
      case "yoga":
        return const Icon(Icons.self_improvement, color: Colors.indigo);
      case "cardio":
        return const Icon(Icons.favorite, color: Colors.pink);
      default:
        return const Icon(Icons.fitness_center, color: Colors.grey);
    }
  }
}
