import 'package:flutter/material.dart';
import '../services/workout_service.dart';

/// Dialog for selecting how to add a workout:
/// - Create new from scratch
/// - Copy a previous workout
/// - Load and edit a previous workout
class WorkoutSelectionDialog extends StatefulWidget {
  final String userId;
  final WorkoutService workoutService;

  const WorkoutSelectionDialog({
    super.key,
    required this.userId,
    required this.workoutService,
  });

  @override
  State<WorkoutSelectionDialog> createState() => _WorkoutSelectionDialogState();
}

class _WorkoutSelectionDialogState extends State<WorkoutSelectionDialog> {
  List<Map<String, dynamic>> _workouts = [];
  List<Map<String, dynamic>> _filteredWorkouts = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedType;

  static const List<String> _workoutTypes = [
    'All',
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

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _loading = true);
    try {
      final workouts = await widget.workoutService.getWorkouts(widget.userId);
      // Sort by most recently updated
      workouts.sort((a, b) {
        final aDate = a['updated_at'] ?? a['created_at'] ?? '';
        final bDate = b['updated_at'] ?? b['created_at'] ?? '';
        return bDate.compareTo(aDate);
      });
      setState(() {
        _workouts = workouts;
        _filteredWorkouts = workouts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _filterWorkouts() {
    setState(() {
      _filteredWorkouts = _workouts.where((w) {
        // Filter by type
        if (_selectedType != null && _selectedType != 'All') {
          if (w['type'] != _selectedType) return false;
        }
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final name = (w['name'] ?? '').toString().toLowerCase();
          final type = (w['type'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          if (!name.contains(query) && !type.contains(query)) return false;
        }
        return true;
      }).toList();
    });
  }

  IconData _getWorkoutIcon(String? type) {
    switch (type) {
      case 'Strength':
        return Icons.fitness_center;
      case 'Run':
        return Icons.directions_run;
      case 'Swim':
        return Icons.pool;
      case 'Bike':
        return Icons.directions_bike;
      case 'Yoga':
        return Icons.self_improvement;
      case 'Cardio':
        return Icons.favorite;
      case 'Mobility':
        return Icons.accessibility_new;
      case 'Rest':
        return Icons.hotel;
      case 'Murph':
        return Icons.military_tech;
      default:
        return Icons.sports;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.add_circle_outline),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Add Workout',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Create New button
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.add, size: 32),
                  title: const Text(
                    'Create New Workout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Start from scratch'),
                  onTap: () => Navigator.pop(context, {'action': 'create_new'}),
                ),
              ),

              const SizedBox(height: 16),

              // Previous workouts section
              if (_workouts.isNotEmpty) ...[
                const Text(
                  'Or use a previous workout:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                // Search and filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search workouts...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterWorkouts();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedType ?? 'All',
                      items: _workoutTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _selectedType = value;
                        _filterWorkouts();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Workout list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredWorkouts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _workouts.isEmpty
                                      ? 'No saved workouts yet'
                                      : 'No workouts match your search',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredWorkouts.length,
                            itemBuilder: (context, index) {
                              final workout = _filteredWorkouts[index];
                              return _WorkoutListItem(
                                workout: workout,
                                icon: _getWorkoutIcon(workout['type']),
                                dateLabel: _formatDate(
                                  workout['updated_at'] ?? workout['created_at'],
                                ),
                                onCopy: () => Navigator.pop(context, {
                                  'action': 'copy',
                                  'workout': workout,
                                }),
                                onEdit: () => Navigator.pop(context, {
                                  'action': 'edit',
                                  'workout': workout,
                                }),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutListItem extends StatelessWidget {
  final Map<String, dynamic> workout;
  final IconData icon;
  final String dateLabel;
  final VoidCallback onCopy;
  final VoidCallback onEdit;

  const _WorkoutListItem({
    required this.workout,
    required this.icon,
    required this.dateLabel,
    required this.onCopy,
    required this.onEdit,
  });

  String _getExerciseCount() {
    int count = 0;
    final warmup = workout['warmup'] as List? ?? [];
    final main = workout['main'] as List? ?? [];
    final cooldown = workout['cooldown'] as List? ?? [];
    count = warmup.length + main.length + cooldown.length;
    if (count == 0) return '';
    return '$count exercise${count == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final name = workout['name'] ?? workout['type'] ?? 'Workout';
    final type = workout['type'] ?? '';
    final exerciseCount = _getExerciseCount();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 28),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (type.isNotEmpty) ...[
                        Text(
                          type,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (exerciseCount.isNotEmpty)
                          Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                      if (exerciseCount.isNotEmpty)
                        Text(
                          exerciseCount,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  if (dateLabel.isNotEmpty)
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Use'),
                  onPressed: onCopy,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
