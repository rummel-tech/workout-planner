import 'dart:async';
import 'package:flutter/material.dart';
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
import '../ui_components/weekly_plan_preview.dart';
import 'day_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> readiness;
  final Map<String, dynamic> dailyPlan;
  final Map<String, dynamic> weeklyPlan;
  final bool testMode;
  final dynamic themeController;
  final AuthService? authService;

  const HomeScreen({
    super.key,
    required this.readiness,
    required this.dailyPlan,
    required this.weeklyPlan,
    this.testMode = false,
    this.themeController,
    this.authService,
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

  int _currentIndex = 0;
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
  String _userId = 'user-123'; // Default fallback

  @override
  void initState() {
    super.initState();
    _weeklyPlan = Map<String, dynamic>.from(widget.weeklyPlan);
    _dailyPlan = Map<String, dynamic>.from(widget.dailyPlan);

    if (!widget.testMode) {
      _initializeData();
    } else {
      _goalsLoading = false;
      _healthLoading = false;
      _readinessLoading = false;
    }
  }

  Future<void> _initializeData() async {
    // First load user ID, then load all data that depends on it
    await _loadUserId();

    // Now load data with correct user ID
    _loadSavedWeeklyPlan();
    _loadSavedDailyPlan();
    _loadGoals();
    _loadHealth();
    _loadReadiness();
    Future.delayed(const Duration(seconds: 2), _performSync);
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _performSync());
  }

  Future<void> _loadUserId() async {
    if (widget.authService != null) {
      final userId = await widget.authService!.getUserId();
      if (userId != null && mounted) {
        setState(() => _userId = userId);
      }
    }
  }

  Future<void> _loadSavedWeeklyPlan() async {
    final saved = await _weeklyPlanService.load(_userId);
    if (saved != null && mounted) {
      setState(() => _weeklyPlan = saved);
    }
  }

  Future<void> _loadSavedDailyPlan() async {
    final saved = await _dailyPlanService.loadToday(_userId);
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
      final data = await _readinessService.fetch(_userId);
      double asDouble(dynamic v, double fallback) => v is num ? v.toDouble() : fallback;
      int asInt(dynamic v, int fallback) => v is num ? v.round() : fallback;
      setState(() {
        _readinessScore = asDouble(data['readiness'], 0.0);
        _hrv = asDouble(data['hrv'], 0.0);
        _sleepHours = asDouble(data['sleep_hours'], 0.0);
        _restingHr = asInt(data['resting_hr'], 0);
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
      final goalsData = await _apiService.getGoals(_userId);
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
        setState(() => _goalsLoading = false);
      }
    }
  }

  Future<void> _loadHealth() async {
    setState(() {
      _healthLoading = true;
      _healthError = null;
    });
    try {
      final distanceSamples = await _healthService.listSamples(_userId, 'workout_distance', limit: 1000);
      final calorieSamples = await _healthService.listSamples(_userId, 'workout_calories', limit: 1000);
      _workoutsCount = distanceSamples.length;
      _totalDistanceKm = distanceSamples.fold<double>(0, (sum, s) => sum + ((s['value'] ?? 0) as num).toDouble()) / 1000.0;
      _totalCalories = calorieSamples.fold<double>(0, (sum, s) => sum + ((s['value'] ?? 0) as num).toDouble());
      setState(() => _healthLoading = false);
    } catch (e) {
      setState(() {
        _healthLoading = false;
        _healthError = '$e';
      });
    }
  }

  Future<void> _performSync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    final sync = HealthSync(userId: _userId);
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
          const SnackBar(content: Text('Health data unavailable (permissions).')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync errors: $joined')),
        );
      }
    }
    setState(() => _syncing = false);
  }

  void _showQuickLogSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quick Log',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickLogButton(
                    icon: Icons.favorite,
                    label: 'Health',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => HealthMetricsScreen(userId: _userId),
                      ));
                    },
                  ),
                  _quickLogButton(
                    icon: Icons.fitness_center,
                    label: 'Strength',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => StrengthMetricsScreen(userId: _userId),
                      ));
                    },
                  ),
                  _quickLogButton(
                    icon: Icons.pool,
                    label: 'Swim',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SwimMetricsScreen(userId: _userId),
                      ));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickLogButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildPlanTab(),
          _buildGoalsTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickLogSheet,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home, 'Home'),
              _navItem(1, Icons.calendar_today, 'Plan'),
              const SizedBox(width: 48), // Space for FAB
              _navItem(2, Icons.flag, 'Goals'),
              _navItem(3, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HOME TAB ====================
  Widget _buildHomeTab() {
    final upcoming = _getUpcomingWorkouts();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Workout-Planner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'AI Coach',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(userId: _userId)),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Today's Overview Card
              _buildTodayCard(upcoming),
              const SizedBox(height: 16),

              // Quick Stats Row
              _buildQuickStats(),
              const SizedBox(height: 16),

              // Next Workout Card
              if (upcoming.isNotEmpty) ...[
                _buildNextWorkoutCard(upcoming[0]),
                const SizedBox(height: 12),
              ],

              // Following Workout (compact)
              if (upcoming.length > 1)
                _buildCompactWorkoutCard(upcoming[1]),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard(List<Map<String, dynamic>> upcoming) {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayNames[now.weekday - 1],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${monthNames[now.month - 1]} ${now.day}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (!_readinessLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getReadinessColor(_readinessScore).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.battery_charging_full,
                          size: 18,
                          color: _getReadinessColor(_readinessScore),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_readinessScore * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getReadinessColor(_readinessScore),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (upcoming.isNotEmpty && upcoming[0]['day'] == dayNames[now.weekday - 1])
              _buildTodayWorkoutSummary(upcoming[0])
            else
              Text(
                'Rest Day',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayWorkoutSummary(Map<String, dynamic> workout) {
    final workouts = workout['workouts'] as List<Map<String, dynamic>>? ?? [];
    if (workouts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: workouts.map((w) {
        final type = w['type'] as String? ?? 'Workout';
        return Chip(
          avatar: _iconForWorkout(type, size: 16),
          label: Text(type),
          backgroundColor: _getWorkoutColor(type).withOpacity(0.1),
        );
      }).toList(),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            label: 'Sleep',
            value: '${_sleepHours.toStringAsFixed(1)}h',
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timeline,
            label: 'HRV',
            value: '${_hrv.round()}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.monitor_heart,
            label: 'RHR',
            value: '$_restingHr',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextWorkoutCard(Map<String, dynamic> workout) {
    final dayName = workout['day'] as String? ?? 'Unknown';
    final title = workout['title'] as String?;
    final workouts = workout['workouts'] as List<Map<String, dynamic>>? ?? [];
    final focus = workout['focus'] as String?;
    final description = workout['description'] as String?;
    final timeGoal = workout['timeGoal'] as int?;
    final goalName = workout['goalName'] as String?;
    final isRest = workouts.length == 1 &&
        (workouts[0]['type'] as String?)?.toLowerCase() == 'rest';
    final firstWorkoutType = workouts.isNotEmpty
        ? (workouts[0]['type'] as String? ?? 'Rest')
        : 'Rest';
    final headerColor = _getWorkoutColor(firstWorkoutType);

    // Display title or generate from workout types
    final displayTitle = (title != null && title.isNotEmpty)
        ? title
        : workouts.map((w) => w['type'] as String? ?? '').where((t) => t.isNotEmpty).join(' + ');

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDayDetail(workout),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: headerColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _iconForWorkout(firstWorkoutType, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Today's Workout",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• $dayName',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayTitle.isNotEmpty ? displayTitle : 'Rest Day',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),

              // Focus area
              if (focus != null && focus.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.track_changes, size: 18, color: headerColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Focus',
                              style: TextStyle(fontSize: 11, color: headerColor.withOpacity(0.7)),
                            ),
                            Text(
                              focus,
                              style: TextStyle(
                                fontSize: 15,
                                color: headerColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Time and Goal row
              if (timeGoal != null || goalName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (timeGoal != null) ...[
                      Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '$timeGoal min',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                    if (timeGoal != null && goalName != null)
                      const SizedBox(width: 16),
                    if (goalName != null) ...[
                      Icon(Icons.flag_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          goalName,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Workout types chips
              if (workouts.isNotEmpty && !isRest) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: workouts.map((w) {
                    final type = w['type'] as String? ?? 'Unknown';
                    final color = _getWorkoutColor(type);
                    return Chip(
                      avatar: _iconForWorkout(type, size: 16),
                      label: Text(type, style: const TextStyle(fontSize: 13)),
                      backgroundColor: color.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],

              // Description preview
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDayDetail(Map<String, dynamic> workout) async {
    final dayName = workout['day'] as String? ?? 'Unknown';
    final authService = widget.authService ?? AuthService();

    // Ensure dayData has proper workout structure
    final normalizedDayData = Map<String, dynamic>.from(workout);
    if (!normalizedDayData.containsKey('workouts') ||
        normalizedDayData['workouts'] is! List ||
        (normalizedDayData['workouts'] as List).isEmpty) {
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
          userId: _userId,
          goals: _goals,
          authService: authService,
        ),
      ),
    );

    if (result != null && mounted) {
      // Update the weekly plan with the edited day
      final rawDays = _weeklyPlan['days'] as List? ?? [];
      final days = rawDays.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      final index = days.indexWhere((d) => d['day'] == dayName);
      if (index >= 0) {
        days[index] = result;
        setState(() {
          _weeklyPlan = {..._weeklyPlan, 'days': days};
        });
        // Save the updated plan
        try {
          await _weeklyPlanService.save(_userId, _weeklyPlan);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Day updated')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save: $e')),
            );
          }
        }
      }
    }
  }

  Widget _buildCompactWorkoutCard(Map<String, dynamic> workout) {
    final dayName = workout['day'] as String? ?? 'Unknown';
    final workouts = workout['workouts'] as List<Map<String, dynamic>>? ?? [];
    final types = workouts.map((w) => w['type'] as String? ?? '').where((t) => t.isNotEmpty).join(', ');
    final isRest = types.toLowerCase() == 'rest' || types.isEmpty;

    return Card(
      child: ListTile(
        leading: Icon(
          isRest ? Icons.bedtime : Icons.schedule,
          color: isRest ? Colors.grey : Colors.blue,
        ),
        title: const Text('Tomorrow', style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          types.isEmpty ? 'Rest' : types,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => _navigateToDayDetail(workout),
      ),
    );
  }

  // ==================== PLAN TAB ====================
  Widget _buildPlanTab() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text('Weekly Plan'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              WeeklyPlanPreview(
                weeklyPlan: _weeklyPlan,
                userId: _userId,
                authService: widget.authService ?? AuthService(),
                onUpdated: (updated) async {
                  setState(() => _weeklyPlan = updated);
                  try {
                    await _weeklyPlanService.save(_userId, updated);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weekly plan saved')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save: $e')),
                      );
                    }
                  }
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== GOALS TAB ====================
  Widget _buildGoalsTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Goals'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                _loadGoals();
              },
            ),
          ],
        ),
        if (_goalsLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_goals.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No goals yet', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                      _loadGoals();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Goal'),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGoalCard(_goals[index]),
                childCount: _goals.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGoalCard(UserGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.flag, color: Colors.blue),
        ),
        title: Text(goal.goalType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (goal.targetValue != null)
              Text('Target: ${goal.targetValue}${goal.targetUnit != null ? ' ${goal.targetUnit}' : ''}'),
            if (goal.targetDate != null)
              Text('By: ${goal.targetDate}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) async {
            if (val == 'plans') {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => GoalPlansScreen(goal: goal)));
              _loadGoals();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'plans', child: Text('View Plans')),
          ],
        ),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => GoalPlansScreen(goal: goal)));
          _loadGoals();
        },
      ),
    );
  }

  // ==================== PROFILE TAB ====================
  Widget _buildProfileTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _confirmLogout,
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Profile Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        child: Text('SR', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shawn Rummel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('shawn@example.com', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Settings Options
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Appearance'),
                      trailing: const Icon(Icons.chevron_right),
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
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Sync Health Data'),
                      subtitle: _syncing ? const Text('Syncing...') : null,
                      trailing: _syncing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chevron_right),
                      onTap: _syncing ? null : _performSync,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.chat),
                      title: const Text('AI Coach'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(userId: _userId)),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== LOGOUT ====================
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = widget.authService ?? AuthService();
      await authService.logout();
      if (mounted) {
        // Navigate back to welcome/login screen and clear stack
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  // ==================== HELPERS ====================
  /// Returns today's and tomorrow's workouts (always exactly 2 entries)
  List<Map<String, dynamic>> _getUpcomingWorkouts() {
    final daysList = _weeklyPlan['days'];
    if (daysList == null || daysList is! List || daysList.isEmpty) return [];

    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final tomorrowIndex = (todayIndex + 1) % 7;
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    List<Map<String, dynamic>> result = [];

    // Get today and tomorrow
    for (final targetIndex in [todayIndex, tomorrowIndex]) {
      final dayName = dayNames[targetIndex];

      // Find matching day data
      Map<String, dynamic>? dayData;
      for (final d in daysList) {
        if (d is Map && d['day'] != null) {
          final dDay = d['day'].toString().toLowerCase();
          if (dDay == dayName.toLowerCase()) {
            dayData = Map<String, dynamic>.from(d);
            break;
          }
        }
      }

      if (dayData != null) {
        List<Map<String, dynamic>> workouts = [];
        if (dayData.containsKey('workouts') && dayData['workouts'] is List) {
          for (final w in dayData['workouts'] as List) {
            if (w is Map) {
              workouts.add(Map<String, dynamic>.from(w));
            }
          }
        } else if (dayData.containsKey('type')) {
          final type = dayData['type']?.toString() ?? '';
          workouts = [{'type': type.isEmpty ? 'Rest' : type}];
        }

        // If no workouts defined, default to Rest
        if (workouts.isEmpty) {
          workouts = [{'type': 'Rest'}];
        }

        result.add({
          'day': dayName,
          'workouts': workouts,
          'isToday': targetIndex == todayIndex,
        });
      }
    }

    return result;
  }

  Color _getReadinessColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getWorkoutColor(String type) {
    switch (type.toLowerCase()) {
      case 'strength': return Colors.orange;
      case 'swim': return Colors.blue;
      case 'run': return Colors.green;
      case 'mobility': return Colors.purple;
      case 'murph':
      case 'murph prep': return Colors.red;
      case 'bike':
      case 'cycling': return Colors.teal;
      case 'yoga': return Colors.indigo;
      case 'cardio': return Colors.pink;
      default: return Colors.grey;
    }
  }

  Icon _iconForWorkout(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'strength':
        return Icon(Icons.fitness_center, size: size, color: Colors.orange);
      case 'swim':
        return Icon(Icons.pool, size: size, color: Colors.blue);
      case 'run':
        return Icon(Icons.directions_run, size: size, color: Colors.green);
      case 'mobility':
        return Icon(Icons.accessibility_new, size: size, color: Colors.purple);
      case 'murph':
      case 'murph prep':
        return Icon(Icons.shield, size: size, color: Colors.red);
      case 'rest':
        return Icon(Icons.bedtime, size: size, color: Colors.grey);
      case 'bike':
      case 'cycling':
        return Icon(Icons.directions_bike, size: size, color: Colors.teal);
      case 'yoga':
        return Icon(Icons.self_improvement, size: size, color: Colors.indigo);
      case 'cardio':
        return Icon(Icons.favorite, size: size, color: Colors.pink);
      default:
        return Icon(Icons.fitness_center, size: size, color: Colors.grey);
    }
  }
}
