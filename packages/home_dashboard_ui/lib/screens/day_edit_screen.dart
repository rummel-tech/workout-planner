import 'package:flutter/material.dart';
import 'package:goals_ui/ui_components/goal_model.dart';
import 'package:goals_ui/services/goals_api_service.dart';
import 'package:goals_ui/screens/goals_screen.dart';
import 'package:todays_workout_ui/screens/workout_detail_screen.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../widgets/workout_selection_dialog.dart';

class DayEditScreen extends StatefulWidget {
  final String dayName;
  final Map<String, dynamic> dayData;
  final List<UserGoal>? goals;
  final String userId;
  final AuthService authService;

  const DayEditScreen({
    super.key,
    required this.dayName,
    required this.dayData,
    required this.userId,
    required this.authService,
    this.goals,
  });

  @override
  State<DayEditScreen> createState() => _DayEditScreenState();
}

class _DayEditScreenState extends State<DayEditScreen> {
  late List<Map<String, dynamic>> _workouts;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeGoalController;
  int? _selectedGoalId;
  List<UserGoal> _goals = [];
  bool _goalsLoading = false;
  bool _hasChanges = false;
  late final WorkoutService _workoutService;

  @override
  void initState() {
    super.initState();
    _workoutService = WorkoutService(widget.authService);

    // Initialize workouts from day data
    if (widget.dayData.containsKey('workouts') &&
        widget.dayData['workouts'] is List &&
        (widget.dayData['workouts'] as List).isNotEmpty) {
      _workouts = (widget.dayData['workouts'] as List)
          .map((w) {
            if (w is Map) {
              final workout = Map<String, dynamic>.from(w);
              return _normalizeWorkout(workout);
            }
            // Handle string type (legacy format)
            return _createWorkoutFromType(w.toString());
          })
          .toList();
    } else if (widget.dayData.containsKey('type') && widget.dayData['type'] != null) {
      _workouts = [_createWorkoutFromType(widget.dayData['type'] as String)];
    } else {
      // Default to one Rest workout
      _workouts = [_createWorkoutFromType('Rest')];
    }

    // Ensure at least one workout exists
    if (_workouts.isEmpty) {
      _workouts = [_createWorkoutFromType('Rest')];
    }

    // Initialize text controllers - default title to current date if empty
    final existingTitle = widget.dayData['title'] as String? ?? '';
    final defaultTitle = existingTitle.isEmpty
        ? _formatDate(DateTime.now())
        : existingTitle;
    _titleController = TextEditingController(text: defaultTitle);
    _descriptionController = TextEditingController(
      text: widget.dayData['description'] as String? ?? '',
    );
    _timeGoalController = TextEditingController(
      text: widget.dayData['timeGoal']?.toString() ?? '',
    );
    _selectedGoalId = widget.dayData['goalId'] as int?;

    // Initialize goals from widget or load them
    if (widget.goals != null) {
      _goals = widget.goals!;
    } else {
      _loadGoals();
    }
  }

  Future<void> _loadGoals() async {
    setState(() => _goalsLoading = true);
    try {
      final apiService = GoalsApiService();
      final goalsData = await apiService.getGoals(widget.userId);
      if (mounted) {
        setState(() {
          _goals = goalsData.map((g) => UserGoal.fromJson(g)).toList();
          _goalsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _goalsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeGoalController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _addWorkout() async {
    if (_workouts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 workouts per day')),
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
        // If adding a non-rest workout to a rest day, remove the rest
        if (_workouts.length == 1 &&
            (_workouts[0]['type'] as String?)?.toLowerCase() == 'rest' &&
            (result!['type'] as String?)?.toLowerCase() != 'rest') {
          _workouts.clear();
        }
        _workouts.add(result!);
        _markChanged();
      });
    }
  }

  void _editWorkout(int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(existingWorkout: _workouts[index]),
      ),
    );

    if (result != null && mounted) {
      // Update in service if it has an ID, otherwise create new
      final existingId = _workouts[index]['id']?.toString();
      if (existingId != null && existingId.isNotEmpty) {
        await _workoutService.updateWorkout(widget.userId, existingId, result);
      } else {
        await _workoutService.createWorkout(widget.userId, result);
      }

      setState(() {
        _workouts[index] = result;
        _markChanged();
      });
    }
  }

  /// Create a workout object with all required attributes from just a type
  Map<String, dynamic> _createWorkoutFromType(String type) {
    return {
      'name': type,
      'type': type,
      'warmup': <Map<String, dynamic>>[],
      'main': <Map<String, dynamic>>[],
      'cooldown': <Map<String, dynamic>>[],
      'notes': '',
      'status': 'pending',
    };
  }

  /// Normalize a workout object to ensure all required fields are present
  Map<String, dynamic> _normalizeWorkout(Map<String, dynamic> workout) {
    final type = workout['type'] as String? ?? 'Rest';

    // Helper to normalize exercise lists
    List<Map<String, dynamic>> normalizeExerciseList(dynamic data) {
      if (data == null) return <Map<String, dynamic>>[];
      if (data is! List) return <Map<String, dynamic>>[];
      return data.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return <String, dynamic>{'name': e.toString()};
      }).toList();
    }

    return {
      'name': workout['name'] ?? type,
      'type': type,
      'warmup': normalizeExerciseList(workout['warmup']),
      'main': normalizeExerciseList(workout['main']),
      'cooldown': normalizeExerciseList(workout['cooldown']),
      'notes': workout['notes'] ?? '',
      'status': workout['status'] ?? 'pending',
      if (workout['id'] != null) 'id': workout['id'],
    };
  }

  void _removeWorkout(int index) {
    // At least one workout is required
    if (_workouts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one workout is required')),
      );
      return;
    }
    setState(() {
      _workouts.removeAt(index);
      _markChanged();
    });
  }

  void _saveAndReturn() {
    final result = Map<String, dynamic>.from(widget.dayData);
    result['day'] = widget.dayName;
    result['workouts'] = _workouts;
    result['title'] = _titleController.text.trim();
    result['description'] = _descriptionController.text.trim();

    final timeGoal = int.tryParse(_timeGoalController.text.trim());
    if (timeGoal != null && timeGoal > 0) {
      result['timeGoal'] = timeGoal;
    } else {
      result.remove('timeGoal');
    }

    if (_selectedGoalId != null) {
      result['goalId'] = _selectedGoalId;
      // Also store goal name for display purposes
      final goal = _goals.where((g) => g.id == _selectedGoalId).firstOrNull;
      if (goal != null) {
        result['goalName'] = goal.goalType;
      }
    } else {
      result.remove('goalId');
      result.remove('goalName');
    }

    // Remove old fields if present
    result.remove('type');
    result.remove('focus');

    Navigator.pop(context, result);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.dayName),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              _buildSectionHeader('Title'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Upper Body Power, Long Run...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _markChanged(),
              ),

              const SizedBox(height: 24),

              // Workouts Section
              _buildWorkoutsSection(),

              const SizedBox(height: 24),

              // Description Section
              _buildSectionHeader('Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Workout details, notes, exercises...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onChanged: (_) => _markChanged(),
              ),

              const SizedBox(height: 24),

              // Time Goal Section
              _buildSectionHeader('Time Goal (minutes)'),
              const SizedBox(height: 8),
              TextField(
                controller: _timeGoalController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 60',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _markChanged(),
              ),

              const SizedBox(height: 24),

              // Related Goal Section (at bottom)
              _buildSectionHeader('Related Goal'),
              const SizedBox(height: 8),
              _buildGoalSelector(),

              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _saveAndReturn,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSelector() {
    if (_goalsLoading) {
      return const Card(
        child: ListTile(
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Loading goals...'),
        ),
      );
    }

    if (_goals.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined, color: Colors.grey),
          title: const Text('No goals created yet'),
          subtitle: const Text('Create a goal to link this workout'),
          trailing: FilledButton.tonal(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsScreen()),
              );
              _loadGoals();
            },
            child: const Text('Create'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<int?>(
          value: _selectedGoalId,
          decoration: const InputDecoration(
            border: InputBorder.none,
            icon: Icon(Icons.flag),
          ),
          hint: const Text('Select a goal (optional)'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('No goal', style: TextStyle(color: Colors.grey)),
            ),
            ..._goals.map((goal) => DropdownMenuItem<int?>(
              value: goal.id,
              child: Text(goal.goalType),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGoalId = value;
              _markChanged();
            });
          },
        ),
      ),
    );
  }

  Widget _buildWorkoutsSection() {
    final canDelete = _workouts.length > 1;
    final canAdd = _workouts.length < 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count and add button
        Row(
          children: [
            const Text(
              'Workouts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_workouts.length}/3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const Spacer(),
            if (canAdd)
              FilledButton.tonalIcon(
                onPressed: _addWorkout,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Workout cards
        ...List.generate(_workouts.length, (index) {
          final workout = _workouts[index];
          final type = workout['type'] as String? ?? 'Unknown';
          final name = workout['name'] as String? ?? type;
          final warmupCount = (workout['warmup'] as List?)?.length ?? 0;
          final mainCount = (workout['main'] as List?)?.length ?? 0;
          final cooldownCount = (workout['cooldown'] as List?)?.length ?? 0;
          final totalExercises = warmupCount + mainCount + cooldownCount;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(100),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _editWorkout(index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Workout number badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Icon
                      _iconForWorkout(type),
                      const SizedBox(width: 10),

                      // Workout info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (totalExercises > 0 || name != type)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  [
                                    if (name != type) type,
                                    if (totalExercises > 0) '$totalExercises exercise${totalExercises == 1 ? '' : 's'}',
                                  ].join(' • '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Delete button (only if more than 1 workout)
                      if (canDelete)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          onPressed: () => _removeWorkout(index),
                          tooltip: 'Remove workout',
                          visualDensity: VisualDensity.compact,
                        ),

                      // Edit indicator
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // Helper text
        if (_workouts.length == 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'At least one workout is required',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (onAdd != null)
          Tooltip(
            message: 'Max 3 types per day',
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: onAdd,
            ),
          ),
      ],
    );
  }

  Icon _iconForWorkout(String type) {
    switch (type.toLowerCase()) {
      case 'strength':
        return const Icon(Icons.fitness_center, color: Colors.orange);
      case 'swim':
        return const Icon(Icons.pool, color: Colors.blue);
      case 'run':
        return const Icon(Icons.directions_run, color: Colors.green);
      case 'mobility':
        return const Icon(Icons.accessibility_new, color: Colors.purple);
      case 'murph':
      case 'murph prep':
        return const Icon(Icons.shield, color: Colors.red);
      case 'rest':
        return const Icon(Icons.bedtime, color: Colors.grey);
      case 'bike':
      case 'cycling':
        return const Icon(Icons.directions_bike, color: Colors.teal);
      case 'yoga':
        return const Icon(Icons.self_improvement, color: Colors.indigo);
      case 'cardio':
        return const Icon(Icons.favorite, color: Colors.pink);
      default:
        return const Icon(Icons.fitness_center, color: Colors.grey);
    }
  }
}

