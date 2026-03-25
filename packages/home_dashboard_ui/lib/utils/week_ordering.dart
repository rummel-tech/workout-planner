/// Utility functions for ordering days of the week
///
/// This ensures consistent week ordering across all weekly plan views.
/// The week always starts from yesterday to provide recent context.

/// Get week days ordered starting from yesterday
///
/// Example: If today is Thursday, returns:
/// ['Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday']
List<String> getWeekStartingYesterday() {
  final allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Get yesterday's day of week (1 = Monday, 7 = Sunday)
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayWeekday = yesterday.weekday; // 1-7, Monday=1, Sunday=7

  // Reorder days to start from yesterday
  // yesterdayWeekday is 1-indexed (Monday=1), but our list is 0-indexed
  final startIndex = yesterdayWeekday - 1;

  return [
    ...allDays.sublist(startIndex),
    ...allDays.sublist(0, startIndex),
  ];
}

/// Reorder a weekly plan's days array to start from yesterday
///
/// Takes a weekly plan map and returns a new map with days reordered.
/// The original map is not modified.
Map<String, dynamic> reorderWeeklyPlanDays(Map<String, dynamic> plan) {
  final days = plan['days'] as List<dynamic>? ?? [];
  if (days.isEmpty) return plan;

  final orderedDayNames = getWeekStartingYesterday();
  final reorderedDays = <Map<String, dynamic>>[];

  // Reorder days according to ordered day names
  for (final dayName in orderedDayNames) {
    final day = days.cast<Map<String, dynamic>>().firstWhere(
      (d) => (d['day'] ?? '').toString().toLowerCase() == dayName.toLowerCase(),
      orElse: () => {'day': dayName, 'workouts': []},
    );
    reorderedDays.add(Map<String, dynamic>.from(day));
  }

  // Return new plan with reordered days
  return {
    ...plan,
    'days': reorderedDays,
  };
}
