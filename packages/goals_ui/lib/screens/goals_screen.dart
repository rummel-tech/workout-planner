import 'package:flutter/material.dart';
import 'package:home_dashboard_ui/services/auth_service.dart';
import '../ui_components/goal_tile.dart';
import '../ui_components/goal_model.dart';
import '../services/goals_api_service.dart';
import 'goal_plans_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _apiService = GoalsApiService();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _goalTypeController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _targetUnitController = TextEditingController();
  final _targetDateController = TextEditingController();
  final _notesController = TextEditingController();

  List<UserGoal> _goals = [];
  Map<int, int> _planCounts = {}; // goalId -> plan count
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    _userId = await _authService.getUserId();
    if (_userId == null) {
      setState(() {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
      });
      return;
    }
    await _loadGoals();
  }

  @override
  void dispose() {
    _goalTypeController.dispose();
    _targetValueController.dispose();
    _targetUnitController.dispose();
    _targetDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goalsData = await _apiService.getGoals(_userId);
      final goals = goalsData.map((data) => UserGoal(
        id: data['id'],
        goalType: data['goal_type'],
        targetValue: data['target_value']?.toDouble(),
        targetUnit: data['target_unit'],
        targetDate: data['target_date'],
        notes: data['notes'],
        isActive: data['is_active'] == 1 || data['is_active'] == true,
      )).toList();

      // Load plan counts for each goal
      final planCounts = <int, int>{};
      for (final goal in goals) {
        try {
          final plans = await _apiService.getPlans(goal.id, _userId!);
          planCounts[goal.id] = plans.length;
        } catch (e) {
          planCounts[goal.id] = 0;
        }
      }

      setState(() {
        _goals = goals;
        _planCounts = planCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load goals: $e';
        _isLoading = false;
      });
    }
  }

  void _showGoalDialog({UserGoal? goal}) {
    final isEditing = goal != null;
    
    if (isEditing) {
      _goalTypeController.text = goal.goalType;
      _targetValueController.text = goal.targetValue?.toString() ?? '';
      _targetUnitController.text = goal.targetUnit ?? '';
      _targetDateController.text = goal.targetDate ?? '';
      _notesController.text = goal.notes ?? '';
    } else {
      _goalTypeController.clear();
      _targetValueController.clear();
      _targetUnitController.clear();
      _targetDateController.clear();
      _notesController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Goal' : 'Create Goal'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _goalTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Type',
                    hintText: 'e.g., Running, Strength, Swimming',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetValueController,
                  decoration: const InputDecoration(
                    labelText: 'Target Value (optional)',
                    hintText: 'e.g., 5k, 26.2, 300',
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Target Unit (optional)',
                    hintText: 'e.g., km, mi, lbs, reps',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetDateController,
                  decoration: const InputDecoration(
                    labelText: 'Target Date (optional)',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      _targetDateController.text = date.toIso8601String().split('T')[0];
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  double? targetValue;
                  String? targetUnit = _targetUnitController.text.isEmpty ? null : _targetUnitController.text.trim();
                  final raw = _targetValueController.text.trim();
                  if (raw.isNotEmpty) {
                    final reg = RegExp(r'^([0-9]*\.?[0-9]+)\s*([a-zA-Z]+)?$');
                    final m = reg.firstMatch(raw);
                    if (m != null) {
                      targetValue = double.tryParse(m.group(1)!);
                      final suffix = m.group(2);
                      if (suffix != null && suffix.isNotEmpty && (targetUnit == null || targetUnit.isEmpty)) {
                        targetUnit = suffix.toLowerCase();
                      }
                    } else {
                      targetValue = double.tryParse(raw);
                    }
                  }
                  
                  if (isEditing) {
                    await _apiService.updateGoal(
                      goal.id,
                      _goalTypeController.text,
                      targetValue,
                      _targetDateController.text.isEmpty ? null : _targetDateController.text,
                      _notesController.text.isEmpty ? null : _notesController.text,
                      targetUnit,
                    );
                  } else {
                    await _apiService.createGoal(
                      _userId!,
                      _goalTypeController.text,
                      targetValue,
                      _targetDateController.text.isEmpty ? null : _targetDateController.text,
                      _notesController.text.isEmpty ? null : _notesController.text,
                      targetUnit,
                    );
                  }
                  
                  Navigator.pop(context);
                  await _loadGoals();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Goal updated successfully' : 'Goal created successfully')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to ${isEditing ? 'update' : 'create'} goal: $e')),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _deleteGoal(UserGoal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.goalType}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteGoal(goal.id);
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete goal: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Goals')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadGoals,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _goals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No goals yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showGoalDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Goal'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final planCount = _planCounts[goal.id] ?? 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(goal.goalType, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                if (planCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$planCount plan${planCount != 1 ? 's' : ''}',
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (goal.targetValue != null)
                                  Text('Target: ${goal.targetValue}${goal.targetUnit != null ? ' ${goal.targetUnit}' : ''}'),
                                if (goal.targetDate != null)
                                  Text('By: ${goal.targetDate}'),
                                if (goal.notes != null)
                                  Text(goal.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.event_note),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GoalPlansScreen(goal: goal),
                                      ),
                                    );
                                    // Reload to update plan count
                                    _loadGoals();
                                  },
                                  tooltip: 'View Plans',
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showGoalDialog(goal: goal);
                                    } else if (value == 'delete') {
                                      _deleteGoal(goal);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _goals.isNotEmpty && !_isLoading && _errorMessage == null
          ? FloatingActionButton(
              onPressed: () => _showGoalDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
