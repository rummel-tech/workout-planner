import 'package:flutter/material.dart';
import '../models/exercise_model.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? existingWorkout;

  const WorkoutDetailScreen({super.key, this.existingWorkout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
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

  late String _selectedType;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late List<Exercise> _warmup;
  late List<Exercise> _main;
  late List<Exercise> _cooldown;
  bool _hasChanges = false;

  bool get _isEditing => widget.existingWorkout != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingWorkout != null) {
      _selectedType = widget.existingWorkout!['type'] as String? ?? 'Strength';
      _nameController = TextEditingController(
        text: widget.existingWorkout!['name'] as String? ?? _selectedType,
      );
      _notesController = TextEditingController(
        text: widget.existingWorkout!['notes'] as String? ?? '',
      );
      _warmup = _parseExercises(widget.existingWorkout!['warmup']);
      _main = _parseExercises(widget.existingWorkout!['main']);
      _cooldown = _parseExercises(widget.existingWorkout!['cooldown']);
    } else {
      _selectedType = 'Strength';
      _nameController = TextEditingController();
      _notesController = TextEditingController();
      _warmup = [];
      _main = [];
      _cooldown = [];
    }
  }

  List<Exercise> _parseExercises(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data.map((e) {
      if (e is String) {
        return Exercise(name: e);
      } else if (e is Map) {
        // Handle both Map<String, dynamic> and Map<dynamic, dynamic>
        final map = Map<String, dynamic>.from(e);
        return Exercise.fromJson(map);
      }
      return Exercise(name: e.toString());
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final result = <String, dynamic>{
      'type': _selectedType,
      'name': name.isEmpty ? _selectedType : name,
      'warmup': _warmup.map((e) => e.toJson()).toList(),
      'main': _main.map((e) => e.toJson()).toList(),
      'cooldown': _cooldown.map((e) => e.toJson()).toList(),
      'notes': _notesController.text.trim(),
      'status': widget.existingWorkout?['status'] ?? 'pending',
    };
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

  void _addExercise(List<Exercise> list) {
    _showExerciseDialog(
      onSave: (exercise) {
        setState(() {
          list.add(exercise);
          _markChanged();
        });
      },
    );
  }

  void _editExercise(List<Exercise> list, int index) {
    _showExerciseDialog(
      exercise: list[index],
      onSave: (exercise) {
        setState(() {
          list[index] = exercise;
          _markChanged();
        });
      },
    );
  }

  void _removeExercise(List<Exercise> list, int index) {
    setState(() {
      list.removeAt(index);
      _markChanged();
    });
  }

  void _showExerciseDialog({Exercise? exercise, required Function(Exercise) onSave}) {
    showDialog(
      context: context,
      builder: (ctx) => _ExerciseDialog(
        exercise: exercise,
        workoutType: _selectedType,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Workout' : 'Add Workout'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildNameField(),
            const SizedBox(height: 24),
            _buildExerciseSection('Warmup', _warmup),
            const SizedBox(height: 16),
            _buildExerciseSection('Main Set', _main),
            const SizedBox(height: 16),
            _buildExerciseSection('Cooldown', _cooldown),
            const SizedBox(height: 24),
            _buildNotesField(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _iconForWorkout(_selectedType),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Workout Type',
                  border: InputBorder.none,
                ),
                items: _workoutTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        _iconForWorkout(type),
                        const SizedBox(width: 8),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      if (_nameController.text.isEmpty ||
                          _workoutTypes.contains(_nameController.text)) {
                        _nameController.text = value;
                      }
                      _markChanged();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Workout Name',
        hintText: 'e.g., Upper Body Power, Morning Run...',
        border: OutlineInputBorder(),
      ),
      onChanged: (_) => _markChanged(),
    );
  }

  Widget _buildExerciseSection(String title, List<Exercise> exercises) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  onPressed: () => _addExercise(exercises),
                  tooltip: 'Add exercise',
                ),
              ],
            ),
          ),
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No exercises added',
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = exercises.removeAt(oldIndex);
                  exercises.insert(newIndex, item);
                  _markChanged();
                });
              },
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _buildExerciseCard(
                  key: ValueKey('${title}_$index'),
                  exercise: exercise,
                  onEdit: () => _editExercise(exercises, index),
                  onDelete: () => _removeExercise(exercises, index),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required Key key,
    required Exercise exercise,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(
          exercise.name.isEmpty ? 'Unnamed exercise' : exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: exercise.summary.isNotEmpty && exercise.summary != exercise.name
            ? Text(exercise.summary)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'Additional notes for this workout...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      onChanged: (_) => _markChanged(),
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

class _ExerciseDialog extends StatefulWidget {
  final Exercise? exercise;
  final String workoutType;
  final Function(Exercise) onSave;

  const _ExerciseDialog({
    this.exercise,
    required this.workoutType,
    required this.onSave,
  });

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _durationController;
  late TextEditingController _restController;
  late TextEditingController _distanceController;
  late TextEditingController _notesController;
  late String _weightUnit;
  late String _distanceUnit;
  bool _nameIsValid = false;

  bool get _isStrengthType =>
      ['strength', 'murph'].contains(widget.workoutType.toLowerCase());

  bool get _isCardioType =>
      ['run', 'bike', 'swim', 'cardio', 'cycling'].contains(widget.workoutType.toLowerCase());

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _nameController = TextEditingController(text: e?.name ?? '');
    _setsController = TextEditingController(text: e?.sets?.toString() ?? '');
    _repsController = TextEditingController(text: e?.reps?.toString() ?? '');
    _weightController = TextEditingController(text: e?.weight?.toString() ?? '');
    _durationController = TextEditingController(text: e?.duration?.toString() ?? '');
    _restController = TextEditingController(text: e?.rest?.toString() ?? '');
    _distanceController = TextEditingController(text: e?.distance?.toString() ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _weightUnit = e?.weightUnit ?? 'lbs';
    _distanceUnit = e?.distanceUnit ?? 'miles';
    _nameIsValid = _nameController.text.trim().isNotEmpty;
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final isValid = _nameController.text.trim().isNotEmpty;
    if (isValid != _nameIsValid) {
      setState(() => _nameIsValid = isValid);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _restController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final exercise = Exercise(
      name: _nameController.text.trim(),
      sets: int.tryParse(_setsController.text),
      reps: int.tryParse(_repsController.text),
      weight: double.tryParse(_weightController.text),
      weightUnit: _weightUnit,
      duration: int.tryParse(_durationController.text),
      rest: int.tryParse(_restController.text),
      distance: double.tryParse(_distanceController.text),
      distanceUnit: _distanceUnit,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    widget.onSave(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise == null ? 'Add Exercise' : 'Edit Exercise'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name *',
                hintText: 'e.g., Bench Press, 400m Run...',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_isStrengthType || !_isCardioType) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _setsController,
                      decoration: const InputDecoration(labelText: 'Sets'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      decoration: const InputDecoration(labelText: 'Reps'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _weightUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                      ],
                      onChanged: (v) => setState(() => _weightUnit = v ?? 'lbs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_isCardioType || !_isStrengthType) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _distanceController,
                      decoration: const InputDecoration(labelText: 'Distance'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _distanceUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'miles', child: Text('mi')),
                        DropdownMenuItem(value: 'km', child: Text('km')),
                        DropdownMenuItem(value: 'meters', child: Text('m')),
                        DropdownMenuItem(value: 'yards', child: Text('yd')),
                        DropdownMenuItem(value: 'laps', child: Text('laps')),
                      ],
                      onChanged: (v) => setState(() => _distanceUnit = v ?? 'miles'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      suffixText: 'sec',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _restController,
                    decoration: const InputDecoration(
                      labelText: 'Rest',
                      suffixText: 'sec',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional notes...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameIsValid ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
