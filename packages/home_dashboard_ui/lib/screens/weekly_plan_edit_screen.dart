import 'package:flutter/material.dart';
import 'package:todays_workout_ui/screens/workout_detail_screen.dart';
import '../services/weekly_plan_service.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../widgets/workout_selection_dialog.dart';
import '../utils/week_ordering.dart';
import 'dart:async';

class WeeklyPlanEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialPlan;
  final String userId;
  final AuthService authService;
  const WeeklyPlanEditScreen({
    super.key,
    required this.initialPlan,
    required this.authService,
    this.userId = 'user-123',
  });

  @override
  State<WeeklyPlanEditScreen> createState() => _WeeklyPlanEditScreenState();
}

class _WeeklyPlanEditScreenState extends State<WeeklyPlanEditScreen> {
  late List<DayWorkouts> _days;
  late List<DayWorkouts> _originalDays;
  bool _saving = false;
  bool _saveError = false;
  final WeeklyPlanService _service = WeeklyPlanService();
  late final WorkoutService _workoutService;

  @override
  void initState() {
    super.initState();
    _workoutService = WorkoutService(widget.authService);
    final rawDays = widget.initialPlan['days'] as List<dynamic>? ?? [];

    // Get ordered day names starting from yesterday
    final orderedDays = getWeekStartingYesterday();

    _days = orderedDays.map((name) {
      final existing = rawDays.cast<Map<String, dynamic>>().firstWhere(
            (d) => (d['day'] ?? '').toString().toLowerCase() == name.toLowerCase(),
            orElse: () => {},
          );

      List<Map<String, dynamic>> workouts = [];
      // Support both old format (type field) and new format (workouts array)
      if (existing.containsKey('workouts') && existing['workouts'] is List) {
        workouts = (existing['workouts'] as List).map((w) {
          if (w is Map<String, dynamic>) {
            return Map<String, dynamic>.from(w);
          } else if (w is String) {
            return {'type': w, 'name': w};
          }
          return {'type': 'Run', 'name': 'Run'};
        }).toList();
      } else if (existing.containsKey('type')) {
        // Legacy format - convert to workout list
        final type = existing['type'] as String;
        workouts = [{'type': type, 'name': type}];
      }

      // If no workouts, default to one Run workout
      if (workouts.isEmpty) {
        workouts = [{'type': 'Run', 'name': 'Run'}];
      }

      return DayWorkouts(name: name, workouts: workouts);
    }).toList();

    _originalDays = _days.map((d) => DayWorkouts.copy(d)).toList();
  }

  bool get _isDirty {
    if (_days.length != _originalDays.length) return true;
    for (int i = 0; i < _days.length; i++) {
      if (_days[i].workouts.length != _originalDays[i].workouts.length) {
        return true;
      }
      for (int j = 0; j < _days[i].workouts.length; j++) {
        final current = _days[i].workouts[j];
        final original = _originalDays[i].workouts[j];
        // Compare key fields for changes
        if (current['type'] != original['type'] ||
            current['name'] != original['name'] ||
            current.toString() != original.toString()) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _save() async {
    if (!_isDirty || _saving) return;
    setState(() {
      _saving = true;
      _saveError = false;
    });
    final updated = {
      ...widget.initialPlan,
      'days': _days
          .map((d) => {
                'day': d.name,
                'workouts': d.workouts,
              })
          .toList(),
    };
    try {
      await _service.save(widget.userId, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly plan saved')));
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = true;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _addWorkout(DayWorkouts day) async {
    if (day.workouts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 workouts per day reached')),
      );
      return;
    }

    // Show workout selection dialog
    final selection = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => WorkoutSelectionDialog(
        userId: widget.userId,
        workoutService: _workoutService,
      ),
    );

    if (selection == null || !mounted) return;

    final action = selection['action'] as String?;
    Map<String, dynamic>? result;

    if (action == 'create_new') {
      // Create new workout from scratch
      result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => const WorkoutDetailScreen(),
        ),
      );
    } else if (action == 'copy') {
      // Use previous workout as-is (copy it)
      final workout = selection['workout'] as Map<String, dynamic>;
      result = _workoutService.copyWorkout(workout);
    } else if (action == 'edit') {
      // Load previous workout and edit it
      final workout = selection['workout'] as Map<String, dynamic>;
      final workoutCopy = _workoutService.copyWorkout(workout);
      result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(existingWorkout: workoutCopy),
        ),
      );
    }

    if (result != null && mounted) {
      // Save workout to service for future reuse
      await _workoutService.createWorkout(widget.userId, result);

      setState(() {
        day.workouts.add(result!);
      });
    }
  }

  void _removeWorkout(DayWorkouts day, int index) {
    setState(() {
      if (day.workouts.length > 1) {
        day.workouts.removeAt(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one workout required per day')),
        );
      }
    });
  }

  void _editWorkout(DayWorkouts day, int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(existingWorkout: day.workouts[index]),
      ),
    );

    if (result != null && mounted) {
      // Update in service if it has an ID, otherwise create new
      final existingId = day.workouts[index]['id']?.toString();
      if (existingId != null && existingId.isNotEmpty) {
        await _workoutService.updateWorkout(widget.userId, existingId, result);
      } else {
        await _workoutService.createWorkout(widget.userId, result);
      }

      setState(() {
        day.workouts[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Weekly Plan'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final dayCards = _days.map((day) => _dayCard(day)).toList();
          if (isNarrow) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: dayCards,
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final card in dayCards)
                  Padding(
                      padding: const EdgeInsets.only(right: 16), child: card),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDirty && !_saving ? _save : null,
                  icon: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_saving
                      ? 'Saving...'
                      : _isDirty
                          ? 'Save Changes'
                          : 'No Changes'),
                ),
              ),
              if (_saveError) ...[
                const SizedBox(width: 12),
                const Icon(Icons.error, color: Colors.redAccent),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCard(DayWorkouts day) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              ...List.generate(day.workouts.length, (index) {
                final workout = day.workouts[index];
                final type = workout['type'] as String? ?? 'Unknown';
                final name = workout['name'] as String? ?? type;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _editWorkout(day, index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                _iconFor(type, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (name != type)
                                        Text(
                                          type,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => _removeWorkout(day, index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              if (day.workouts.length < 3)
                OutlinedButton.icon(
                  onPressed: () => _addWorkout(day),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Workout'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _iconFor(String type, {double size = 20}) {
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

class DayWorkouts {
  final String name;
  final List<Map<String, dynamic>> workouts;

  DayWorkouts({required this.name, required this.workouts});

  static DayWorkouts copy(DayWorkouts other) {
    return DayWorkouts(
      name: other.name,
      workouts: other.workouts.map((w) => Map<String, dynamic>.from(w)).toList(),
    );
  }
}

