import 'package:flutter/material.dart';
import 'package:goals_ui/ui_components/goal_model.dart';
import 'package:goals_ui/services/goals_api_service.dart';
import 'package:goals_ui/screens/goals_screen.dart';
import 'package:todays_workout_ui/screens/workout_detail_screen.dart';

class DayEditScreen extends StatefulWidget {
  final String dayName;
  final Map<String, dynamic> dayData;
  final List<UserGoal>? goals;
  final String userId;

  const DayEditScreen({
    super.key,
    required this.dayName,
    required this.dayData,
    required this.userId,
    this.goals,
  });

  @override
  State<DayEditScreen> createState() => _DayEditScreenState();
}

class _DayEditScreenState extends State<DayEditScreen> {
  late List<Map<String, dynamic>> _workouts;
  late TextEditingController _titleController;
  late TextEditingController _focusController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeGoalController;
  int? _selectedGoalId;
  List<UserGoal> _goals = [];
  bool _goalsLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Initialize workouts from day data
    if (widget.dayData.containsKey('workouts') && widget.dayData['workouts'] is List) {
      _workouts = (widget.dayData['workouts'] as List)
          .map((w) {
            final workout = Map<String, dynamic>.from(w as Map);
            // Ensure all required fields are present
            return _normalizeWorkout(workout);
          })
          .toList();
    } else if (widget.dayData.containsKey('type')) {
      _workouts = [_createWorkoutFromType(widget.dayData['type'] as String)];
    } else {
      _workouts = [_createWorkoutFromType('Rest')];
    }

    // Initialize text controllers - default title to current date if empty
    final existingTitle = widget.dayData['title'] as String? ?? '';
    final defaultTitle = existingTitle.isEmpty
        ? _formatDate(DateTime.now())
        : existingTitle;
    _titleController = TextEditingController(text: defaultTitle);
    _focusController = TextEditingController(
      text: widget.dayData['focus'] as String? ?? '',
    );
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
    _focusController.dispose();
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
        const SnackBar(content: Text('Maximum 3 types per day')),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const WorkoutDetailScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        // If adding a non-rest workout to a rest day, remove the rest
        if (_workouts.length == 1 &&
            (_workouts[0]['type'] as String?)?.toLowerCase() == 'rest' &&
            (result['type'] as String?)?.toLowerCase() != 'rest') {
          _workouts.clear();
        }
        _workouts.add(result);
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
    return {
      'name': workout['name'] ?? type,
      'type': type,
      'warmup': workout['warmup'] ?? <Map<String, dynamic>>[],
      'main': workout['main'] ?? <Map<String, dynamic>>[],
      'cooldown': workout['cooldown'] ?? <Map<String, dynamic>>[],
      'notes': workout['notes'] ?? '',
      'status': workout['status'] ?? 'pending',
    };
  }

  void _removeWorkout(int index) {
    setState(() {
      _workouts.removeAt(index);
      if (_workouts.isEmpty) {
        _workouts.add({'type': 'Rest'});
      }
      _markChanged();
    });
  }

  void _saveAndReturn() {
    final result = Map<String, dynamic>.from(widget.dayData);
    result['day'] = widget.dayName;
    result['workouts'] = _workouts;
    result['title'] = _titleController.text.trim();
    result['focus'] = _focusController.text.trim();
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

    // Remove old 'type' field if present
    result.remove('type');

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

              // Related Goal Section
              _buildSectionHeader('Related Goal'),
              const SizedBox(height: 8),
              _buildGoalSelector(),

              const SizedBox(height: 24),

              // Type Section
              _buildSectionHeader('Type', onAdd: _addWorkout),
              const SizedBox(height: 8),
              if (_workouts.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.bedtime, color: Colors.grey),
                    title: Text('Rest Day'),
                  ),
                )
              else
                ...List.generate(_workouts.length, (index) {
                  final workout = _workouts[index];
                  final type = workout['type'] as String? ?? 'Unknown';
                  final name = workout['name'] as String? ?? type;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _iconForWorkout(type),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: name != type ? Text(type) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeWorkout(index),
                      ),
                      onTap: () => _editWorkout(index),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Focus Section
              _buildSectionHeader('Focus'),
              const SizedBox(height: 8),
              TextField(
                controller: _focusController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Upper body strength, Endurance...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _markChanged(),
              ),

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

