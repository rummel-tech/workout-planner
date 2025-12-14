import 'package:flutter/material.dart';
import '../services/weekly_plan_service.dart';
import 'dart:async';

class WeeklyPlanEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialPlan;
  const WeeklyPlanEditScreen({super.key, required this.initialPlan});

  @override
  State<WeeklyPlanEditScreen> createState() => _WeeklyPlanEditScreenState();
}

class _WeeklyPlanEditScreenState extends State<WeeklyPlanEditScreen> {
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

  late List<DayWorkouts> _days;
  late List<DayWorkouts> _originalDays;
  bool _saving = false;
  bool _saveError = false;
  final WeeklyPlanService _service = WeeklyPlanService();

  @override
  void initState() {
    super.initState();
    final rawDays = widget.initialPlan['days'] as List<dynamic>? ?? [];
    _days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ].map((name) {
      final existing = rawDays.cast<Map<String, dynamic>>().firstWhere(
            (d) => (d['day'] ?? '').toString().toLowerCase() == name.toLowerCase(),
            orElse: () => {},
          );

      List<String> workouts = [];
      // Support both old format (type field) and new format (workouts array)
      if (existing.containsKey('workouts') && existing['workouts'] is List) {
        workouts = (existing['workouts'] as List)
            .map((w) => (w['type'] as String?) ?? 'Run')
            .toList();
      } else if (existing.containsKey('type')) {
        // Legacy format - convert to workout list
        workouts = [existing['type'] as String];
      }

      // If no workouts, default to one Run workout
      if (workouts.isEmpty) {
        workouts = ['Run'];
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
        if (_days[i].workouts[j] != _originalDays[i].workouts[j]) {
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
                'workouts': d.workouts.map((type) => {'type': type}).toList(),
              })
          .toList(),
    };
    try {
      // Backend user id placeholder (replace with real auth later)
      await _service.save('user-123', updated);
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
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _WorkoutPickerDialog(workoutTypes: _workoutTypes),
    );
    if (selected != null && mounted) {
      setState(() {
        if (day.workouts.length < 5) {
          day.workouts.add(selected);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Maximum 5 workouts per day reached')),
          );
        }
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

  void _changeWorkout(DayWorkouts day, int index) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _WorkoutPickerDialog(workoutTypes: _workoutTypes),
    );
    if (selected != null && mounted) {
      setState(() {
        day.workouts[index] = selected;
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _changeWorkout(day, index),
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
                                _iconFor(day.workouts[index], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    day.workouts[index],
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
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
              if (day.workouts.length < 5)
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
  final List<String> workouts;

  DayWorkouts({required this.name, required this.workouts});

  static DayWorkouts copy(DayWorkouts other) {
    return DayWorkouts(
      name: other.name,
      workouts: List<String>.from(other.workouts),
    );
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
